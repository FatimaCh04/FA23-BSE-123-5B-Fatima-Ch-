import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import 'package:photo_view/photo_view.dart';

class VisitRecordsScreen extends StatelessWidget {
  final Patient patient;

  const VisitRecordsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final visits = db.getVisitsByPatientId(patient.id) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("${patient.name}'s Visits"),
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade50,
      body: visits.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, color: Colors.teal, size: 60),
            SizedBox(height: 8),
            Text("No visits recorded yet",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final v = visits[index];
          final List<dynamic> images = v['imagePaths'] ?? [];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Visit Date: ${DateTime.parse(v['visitDate']).day}/${DateTime.parse(v['visitDate']).month}/${DateTime.parse(v['visitDate']).year}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text("Diagnosis: ${v['diagnosis'] ?? '-'}"),
                  Text("Treatment: ${v['treatment'] ?? '-'}"),
                  Text("Notes: ${v['notes'] ?? '-'}"),
                  Text("Prescription: ${v['prescription'] ?? '-'}"),
                  const SizedBox(height: 8),
                  if (images.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: images.map((path) {
                        if (path == null || path == '') return const SizedBox();
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                body: Center(
                                  child: PhotoView(
                                    imageProvider: FileImage(File(path)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
