import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'add_patient_screen.dart';
import 'patient_list_screen.dart';
import 'patient_details_screen.dart';
import 'search_patient_screen.dart';
import 'book_appointment_screen.dart';
import 'settings_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final String today;
  const DoctorDashboard({super.key, required this.today});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAppointments();
    });
  }

  Future<void> loadAppointments() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    await dbService.loadAppointments();
    setState(() {
      appointments = dbService.appointments;
    });
  }

  Future<void> deleteAppointment(int id) async {
    // 1️⃣ Remove appointment from UI immediately
    setState(() {
      appointments.removeWhere((appt) => appt['id'] == id);
    });

    // 2️⃣ Delete from database asynchronously
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      await dbService.deleteAppointmentById(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully!')),
      );
    } catch (e) {
      await loadAppointments(); // reload if DB fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete appointment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Patient",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          );
          if (result == true) {
            await loadAppointments();
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Good Morning!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Today is ${widget.today}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Overview",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Patients Overview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      border:
                      Border.all(color: Colors.teal.shade700, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person_add,
                            size: 40, color: Colors.teal.shade700),
                        const SizedBox(height: 8),
                        Text(
                          "${databaseService.patients.length}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const Text("New Patients",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appointments Overview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      border: Border.all(
                          color: Colors.lightBlue.shade700, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 40, color: Colors.lightBlue.shade700),
                        const SizedBox(height: 8),
                        Text(
                          "${appointments.length}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue.shade700,
                          ),
                        ),
                        const Text("Appointments Today",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFeatureCard(
                  context,
                  "Add Patient",
                  Icons.person_add,
                  Colors.lightBlue.shade100,
                  Colors.lightBlue.shade700,
                      () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddPatientScreen()));
                  },
                ),
                _buildFeatureCard(
                  context,
                  "Search Patient",
                  Icons.search,
                  Colors.green.shade100,
                  Colors.green.shade700,
                      () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SearchPatientScreen()));
                  },
                ),
                _buildFeatureCard(
                  context,
                  "Appointments",
                  Icons.calendar_today,
                  Colors.orange.shade100,
                  Colors.orange.shade700,
                      () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddAppointmentScreen(),
                      ),
                    );
                    if (result == true) await loadAppointments();
                  },
                ),
                _buildFeatureCard(
                  context,
                  "View All Patients",
                  Icons.people,
                  Colors.purple.shade100,
                  Colors.purple.shade700,
                      () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PatientListScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🩺 Appointments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "🩺 Today's Appointments",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            appointments.isEmpty
                ? const Center(child: Text("No appointments today"))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                final name = appt['patientName'] ?? "Unknown";

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(
                            color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        "${appt['date']} - ${appt['reason'] ?? 'No reason'}"),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.teal),
                      onSelected: (value) async {
                        if (value == 'view' || value == 'edit') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddAppointmentScreen(existingData: appt),
                            ),
                          );
                          if (result == true) await loadAppointments();
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Appointment'),
                              content: Text(
                                  'Are you sure you want to delete ${appt['patientName'] ?? 'this appointment'}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteAppointment(appt['id']);
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Patients
            const Text(
              "👩‍⚕️ Recent Patients",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),

            databaseService.patients.isEmpty
                ? const Center(child: Text("No recent patients"))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: databaseService.patients.length,
              itemBuilder: (context, index) {
                final patient = databaseService.patients[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(patient.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("DOB: ${patient.dateOfBirth}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(patient: patient)),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon,
      Color circleBgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBgColor,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
