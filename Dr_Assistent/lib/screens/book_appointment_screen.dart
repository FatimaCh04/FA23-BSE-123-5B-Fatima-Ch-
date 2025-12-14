import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData; // null => add, not null => edit

  const AddAppointmentScreen({super.key, this.existingData});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      nameController.text = widget.existingData!['patientName'] ?? '';
      reasonController.text = widget.existingData!['reason'] ?? '';

      final savedDate = widget.existingData!['date'];
      if (savedDate != null && savedDate.isNotEmpty) {
        final dateTime = DateTime.tryParse(savedDate);
        if (dateTime != null) {
          selectedDate = dateTime;
          selectedTime = TimeOfDay.fromDateTime(dateTime);
        }
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          widget.existingData == null ? 'Add Appointment' : 'Edit Appointment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "📅 Appointment Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // --- Patient Name ---
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Patient Name',
                    prefixIcon: const Icon(Icons.person, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Reason ---
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Reason / Notes',
                    prefixIcon: const Icon(Icons.note_add, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Date Picker ---
                InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.teal.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.teal, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? 'Select Appointment Date'
                              : '${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Time Picker ---
                InkWell(
                  onTap: () => _pickTime(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.teal.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.teal, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime == null
                              ? 'Select Appointment Time'
                              : selectedTime!.format(context),
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedTime == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Submit Button ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    widget.existingData == null
                        ? 'Add Appointment'
                        : 'Update Appointment',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final reason = reasonController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter patient name')),
                      );
                      return;
                    }

                    if (selectedDate == null || selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select date and time')),
                      );
                      return;
                    }

                    final finalDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    // --- Add or Update Appointment ---
                    if (widget.existingData == null) {
                      await dbService.addAppointment(
                        patientId: DateTime.now().millisecondsSinceEpoch,
                        patientName: name,
                        date: finalDateTime,
                        reason: reason,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment added successfully!')),
                      );
                    } else {
                      final id = widget.existingData!['id'];
                      await dbService.updateAppointment(id, {
                        'patientName': name,
                        'reason': reason,
                        'date': finalDateTime.toIso8601String(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment updated successfully!')),
                      );
                    }

                    // ✅ Immediately go back to previous screen
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
