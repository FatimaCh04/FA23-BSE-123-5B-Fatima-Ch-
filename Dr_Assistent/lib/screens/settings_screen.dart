import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_assistant/services/database_service.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Manage your profile information',
              onTap: () => _showProfileDialog(context),
            ),
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () => _showSignOutDialog(context),
              titleColor: Colors.red,
              iconColor: Colors.red,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.backup,
              title: 'Backup to Cloud',
              subtitle: 'Sync your patient records securely',
              onTap: () => _showBackupDialog(context),
            ),
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Export Data',
              subtitle: 'Export patient data to file',
              onTap: () => _showExportDialog(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('App Settings'),
          _buildTwoTilesCard(context, [
            _buildSettingsTile(
              icon: notificationsOn
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              title: 'Notifications',
              subtitle: notificationsOn ? 'On' : 'Off',
              onTap: () => setState(() => notificationsOn = !notificationsOn),
            ),
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Clear All Data',
              subtitle: 'Remove all local patient records',
              onTap: () => _showClearDataDialog(context),
              titleColor: Colors.red,
              iconColor: Colors.red,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Contact support via WhatsApp',
              onTap: () => _launchWhatsApp('03043133364'),
            ),
          ]),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  // Cards
  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.teal.shade100,
      child: Column(children: children),
    );
  }

  Widget _buildTwoTilesCard(BuildContext context, List<Widget> children) {
    return _buildSettingsCard(context, children);
  }

  // ListTile
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Icon(icon, color: iconColor ?? Colors.teal.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.black,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('About Me', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Fatima Choudhry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('App: Clinical Management System', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Contact: 03043133364', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Designed & Developed by Fatima Choudhry.\nAll rights reserved © 2025.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to remove all patient records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog
              try {
                final dbService = context.read<DatabaseService>();
                await dbService.clearAllData(); // <-- You need this function in DatabaseService

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error clearing data: $e')),
                );
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  void _showBackupDialog(BuildContext context) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: Text('Backup date: $now\nAll patient records are synced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
            'Import functionality will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out?\nYou will need to sign in again to access your records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear local saved data
              await context.read<AuthService>().signOut();

              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/signup', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp(String phone) async {
    final url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }
}
