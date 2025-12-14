import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class AddVisitScreen extends StatefulWidget {
  final Patient patient;

  const AddVisitScreen({super.key, required this.patient});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController prescriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final List<File> images = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => images.add(File(pickedFile.path)));
    }
  }

  void _saveVisit() async {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one image is required')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final db = context.read<DatabaseService>();

      final newVisit = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'patientId': widget.patient.id,
        'visitDate': selectedDate.toIso8601String(),
        'diagnosis': diagnosisController.text,
        'treatment': treatmentController.text,
        'notes': notesController.text,
        'prescription': prescriptionController.text,
        'imagePaths': images.map((f) => f.path).toList(),
      };

      await db.addVisit(newVisit);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit recorded for ${widget.patient.name}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, newVisit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Add Visit"),
        centerTitle: true,
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveVisit,
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(widget.patient),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextBox(Icons.local_hospital, "Diagnosis", diagnosisController),
              const SizedBox(height: 16),
              _buildTextBox(Icons.healing, "Treatment", treatmentController),
              const SizedBox(height: 16),
              _buildTextBox(Icons.note, "Notes", notesController),
              const SizedBox(height: 16),
              _buildTextBox(Icons.receipt, "Prescription", prescriptionController),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVisit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Record Visit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Patient patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.teal.shade400,
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(patient.phoneNumber,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_today, color: Colors.teal),
      title: const Text("Visit Date"),
      subtitle:
      Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null && picked != selectedDate) {
          setState(() => selectedDate = picked);
        }
      },
    );
  }

  Widget _buildTextBox(
      IconData icon, String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Images *", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (images.isEmpty)
          const Text("At least one image is required",
              style: TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.image),
              label: const Text("Gallery"),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Camera"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((img) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageView(imageFile: img),
                    ),
                  ),
                  child: Hero(
                    tag: img.path,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(img,
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => images.remove(img)),
                ),
              ],
            );
          }).toList(),
        )
      ],
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final File imageFile;
  const FullScreenImageView({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.8,
          maxScale: 4.0,
          child: Hero(
            tag: imageFile.path,
            child: Image.file(imageFile),
          ),
        ),
      ),
    );
  }
}
