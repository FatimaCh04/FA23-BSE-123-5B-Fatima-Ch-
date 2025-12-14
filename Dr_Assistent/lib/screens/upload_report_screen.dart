import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  File? selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Report"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            selectedFile != null
                ? ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: Text(selectedFile!.path.split('/').last),
            )
                : const Text("No file selected"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Choose File"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedFile == null
                  ? null
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File uploaded successfully!")),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 48)),
              child: const Text("Upload Report"),
            ),
          ],
        ),
      ),
    );
  }
}
