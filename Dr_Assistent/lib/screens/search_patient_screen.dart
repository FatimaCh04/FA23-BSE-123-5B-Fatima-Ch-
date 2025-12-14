import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/patient.dart';
import 'patient_details_screen.dart';

class SearchPatientScreen extends StatefulWidget {
  const SearchPatientScreen({super.key});

  @override
  State<SearchPatientScreen> createState() => _SearchPatientScreenState();
}

class _SearchPatientScreenState extends State<SearchPatientScreen> {
  final TextEditingController searchController = TextEditingController();
  String query = "";
  bool isSearched = false;

  @override
  Widget build(BuildContext context) {
    final databaseService = context.watch<DatabaseService>();

    List<Patient> filteredPatients = [];
    if (isSearched && query.isNotEmpty) {
      filteredPatients = databaseService.patients.where((patient) {
        final q = query.toLowerCase();
        final name = patient.name.toLowerCase();
        final phone = patient.phoneNumber?.toLowerCase() ?? "";

        return name.contains(q) || phone.contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Search Patient"),
        centerTitle: true,
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search input
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search by Name, Phone",
                labelStyle: const TextStyle(color: Colors.teal),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.teal),
                  onPressed: () {
                    setState(() {
                      query = searchController.text.trim();
                      isSearched = true;
                    });
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  query = value.trim();
                  isSearched = true;
                });
              },
            ),
            const SizedBox(height: 20),

            // Search Results
            Expanded(
              child: !isSearched
                  ? const Center(
                child: Text(
                  "Enter patient name, phone to search",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              )
                  : filteredPatients.isEmpty
                  ? const Center(
                child: Text(
                  "No patients found",
                  style: TextStyle(color: Colors.redAccent),
                ),
              )
                  : ListView.builder(
                itemCount: filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin:
                    const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade300,
                        child: Text(
                          patient.name.isNotEmpty
                              ? patient.name[0].toUpperCase()
                              : "?",
                          style:
                          const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        patient.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientDetailScreen(
                                  patient: patient,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
