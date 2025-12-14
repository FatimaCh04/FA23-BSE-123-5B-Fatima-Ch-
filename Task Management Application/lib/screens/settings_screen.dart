import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedSound;
  final List<String> sounds = ['ding', 'chime', 'alert', 'cool', 'urgent'];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSelectedSound();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: initAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSound = prefs.getString('notificationSound') ?? 'ding';
    });
  }

  Future<void> _saveSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', sound);
    setState(() => selectedSound = sound);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "$sound" selected as notification sound'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _previewSound(String sound) async {
    final androidDetails = AndroidNotificationDetails(
      'preview_channel_$sound',
      'Preview Channel',
      channelDescription: 'Sound preview notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 10000,
      '🔔 Sound Preview',
      'Playing "$sound"',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = provider.tasks;

    final rows = [
      ['Title', 'Description', 'Due Date', 'Completed', 'Repeat Type'],
      ...tasks.map((t) => [
        t.title,
        t.description,
        t.dueDate.toString(),
        t.isCompleted ? 'Yes' : 'No',
        t.repeatType,
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tasks.csv');
    await file.writeAsString(csv);
    await Share.shareFiles([file.path], text: '📋 My exported task list');
  }

  Future<void> _exportPDF(BuildContext context) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('📝 Task Report',
                style:
                pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...provider.tasks.map(
                  (t) => pw.Text(
                '${t.title} - ${t.isCompleted ? "✅ Completed" : "❌ Pending"} (${t.dueDate})',
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tasks.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareFiles([file.path], text: '📄 Task list PDF');
  }

  Future<void> _exportEmail(BuildContext context) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = provider.tasks;

    final TextEditingController emailController = TextEditingController();

    final emailAddress = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Enter recipient email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'example@gmail.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (emailAddress == null || emailAddress.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("📋 Task Report\n");
    for (var t in tasks) {
      buffer.writeln(
        "- ${t.title} (${t.isCompleted ? '✅ Done' : '❌ Pending'}) | Due: ${t.dueDate}\n",
      );
    }

    final email = Email(
      subject: '📝 My Task Report',
      body: buffer.toString(),
      recipients: [emailAddress],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📨 Email composer opened successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to open email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings & Export'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('🌓 Appearance'),
            _buildCard(
              context,
              child: SwitchListTile(
                title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (_) => provider.toggleTheme(),
                secondary: const Icon(Icons.dark_mode),
              ),
            ),
            const SizedBox(height: 10),

            _buildSectionTitle('🔔 Notification Sound'),
            _buildCard(
              context,
              child: Column(
                children: sounds.map((sound) {
                  return ListTile(
                    leading: Radio<String>(
                      value: sound,
                      groupValue: selectedSound,
                      onChanged: (value) {
                        if (value != null) _saveSound(value);
                      },
                    ),
                    title: Text(
                      sound[0].toUpperCase() + sound.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow,
                          color: colorScheme.primary),
                      onPressed: () => _previewSound(sound),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            _buildSectionTitle('📤 Export Options'),
            _buildCard(
              context,
              child: Column(
                children: [
                  ListTile(
                    leading:
                    Icon(Icons.download, color: colorScheme.primary),
                    title: const Text('Export to CSV'),
                    onTap: () => _exportCSV(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.picture_as_pdf,
                        color: colorScheme.primary),
                    title: const Text('Export to PDF'),
                    onTap: () => _exportPDF(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.email, color: colorScheme.primary),
                    title: const Text('Export via Email'),
                    onTap: () => _exportEmail(context),
                  ),
                ],
              ),
            ),

            _buildSectionTitle('🧪 Test Notification'),
            _buildCard(
              context,
              child: ListTile(
                leading: Icon(Icons.notifications_active,
                    color: colorScheme.primary),
                title: const Text('Test Selected Sound'),
                subtitle:
                const Text('Play your chosen notification sound instantly'),
                onTap: () async {
                  final service = NotificationService();
                  await service.init();
                  await service.scheduleNotification(
                    title: 'Test Notification 🔔',
                    body: 'This is how your selected sound will play!',
                    scheduledDate:
                    DateTime.now().add(const Duration(seconds: 1)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    ),
  );

  Widget _buildCard(BuildContext context, {required Widget child}) => Card(
    elevation: 4,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    ),
  );
}
