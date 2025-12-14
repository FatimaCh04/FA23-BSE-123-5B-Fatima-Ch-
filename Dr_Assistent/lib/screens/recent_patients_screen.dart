import 'package:flutter/material.dart';

class RecentPatientsScreen extends StatelessWidget {
  const RecentPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Dummy list for now (replace later with Firestore or your DB data)
    final recentPatients = [
      {'name': 'Ali Khan', 'age': 28, 'disease': 'Flu'},
      {'name': 'Fatima Noor', 'age': 32, 'disease': 'Fever'},
      {'name': 'Hassan Raza', 'age': 45, 'disease': 'Diabetes'},
    ];

    if (recentPatients.isEmpty) {
      return const Center(
        child: Text(
          "No recent patients yet.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: recentPatients.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final patient = recentPatients[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white),
          ),
          // title: Text(
          //   patient['name']!,
          //   style: const TextStyle(fontWeight: FontWeight.bold),
          // ),
          subtitle: Text(
            "Age: ${patient['age']}, Disease: ${patient['disease']}",
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal),
            onPressed: () {
              // Later: Navigate to patient details
            },
          ),
        );
      },
    );
  }
}
