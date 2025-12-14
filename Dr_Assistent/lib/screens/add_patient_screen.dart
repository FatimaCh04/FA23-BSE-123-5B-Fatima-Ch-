import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patientToEdit;

  const AddPatientScreen({super.key, this.patientToEdit});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();

  String? _selectedGender;
  File? _profileImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      _nameController.text = p.name;
      _dateOfBirthController.text = p.dateOfBirth;
      _phoneController.text = p.phoneNumber;
      _addressController.text = p.address;
      _medicalHistoryController.text = p.medicalHistory;
      _allergiesController.text = p.allergies;

      // ✅ Safely restore gender
      _selectedGender = ['Male', 'Female', 'Other'].contains(p.gender)
          ? p.gender
          : null;

      if (p.profileImagePath != null && File(p.profileImagePath!).existsSync()) {
        _profileImage = File(p.profileImagePath!);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 3650)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text =
        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newPatient = Patient(
      id: widget.patientToEdit?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender ?? '',
      address: _addressController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      allergies: _allergiesController.text.trim(),
      profileImagePath: _profileImage?.path,
      createdAt: widget.patientToEdit?.createdAt ?? DateTime.now(),
    );

    final db = context.read<DatabaseService>();

    try {
      if (widget.patientToEdit != null) {
        await db.updatePatient(newPatient);
      } else {
        await db.addPatient(newPatient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.patientToEdit != null
                ? 'Patient updated successfully!'
                : 'Patient added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        title: Text(
          widget.patientToEdit != null ? 'Edit Patient' : 'Add New Patient',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ---------------- Profile Picture ----------------
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? Icon(Icons.person,
                          size: 50, color: Colors.teal.shade700)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.shade400,
                          child: const Icon(Icons.edit,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('Personal Information'),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter name' : null,
              ),

              // ✅ Date Picker
              GestureDetector(
                onTap: _selectDateOfBirth,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _dateOfBirthController,
                    label: 'Date of Birth',
                    icon: Icons.calendar_today,
                  ),
                ),
              ),

              // ✅ Gender Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline,
                        color: Colors.teal.shade700),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedGender = value;
                  }),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Select gender' : null,
                ),
              ),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone (+92XXXXXXXXXX)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter phone number';
                  }
                  if (!RegExp(r'^\+92\d{10}$').hasMatch(value)) {
                    return 'Enter valid Pakistani number (+92XXXXXXXXXX)';
                  }
                  return null;
                },
              ),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('Medical Information'),

              _buildTextField(
                controller: _medicalHistoryController,
                label: 'Medical History',
                icon: Icons.medical_services,
              ),
              _buildTextField(
                controller: _allergiesController,
                label: 'Allergies',
                icon: Icons.warning,
              ),

              const SizedBox(height: 30),

              // ---------------- Save Button ----------------
              ElevatedButton(
                onPressed: _isSaving ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  widget.patientToEdit != null
                      ? 'Update Patient'
                      : 'Save Patient Record',
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Helper Widgets ----------------
  Widget _buildSectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.teal.shade700),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade200),
            ),
          ),
        ),
      );
}
