import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../data/local/database_helper.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/printer/printer_setup_sheet.dart';
import '../backup/backup_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoBackup = true;
  int _backupInterval = 24;
  int _lowStockThreshold = 10;
  double _taxRate = 0.0;
  String _currency = 'PKR';
  String? _profilePicturePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackup = prefs.getBool(AppConstants.autoBackupKey) ?? true;
      _backupInterval = prefs.getInt(AppConstants.backupIntervalKey) ?? 24;
      _lowStockThreshold =
          prefs.getInt(AppConstants.lowStockThresholdKey) ?? 10;
      _taxRate = prefs.getDouble(AppConstants.taxRateKey) ?? 0.0;
      _currency = prefs.getString(AppConstants.currencyKey) ?? 'PKR';
      _profilePicturePath = prefs.getString('profile_picture_path');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.autoBackupKey, _autoBackup);
    await prefs.setInt(AppConstants.backupIntervalKey, _backupInterval);
    await prefs.setInt(AppConstants.lowStockThresholdKey, _lowStockThreshold);
    await prefs.setDouble(AppConstants.taxRateKey, _taxRate);
    await prefs.setString(AppConstants.currencyKey, _currency);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final connectivityService = context.watch<ConnectivityService>();
    final syncService = context.watch<SyncService>();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Settings',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionHeader('Profile'),
            _buildProfileCard(authService),
            const SizedBox(height: 24),

            // User Management Section
            _buildSectionHeader('User Management'),
            _buildUserManagementCard(),
            const SizedBox(height: 24),

            // Sync Status
            _buildSectionHeader('Sync Status'),
            _buildSyncCard(connectivityService, syncService),
            const SizedBox(height: 24),

            // Backup Settings
            _buildSectionHeader('Backup'),
            _buildSettingCard(
              children: [
                _buildSwitchTile(
                  'Auto Backup',
                  'Automatically backup data periodically',
                  _autoBackup,
                  (value) => setState(() => _autoBackup = value),
                ),
                if (_autoBackup) ...[
                  const Divider(),
                  _buildDropdownTile(
                    'Backup Interval',
                    'How often to auto backup',
                    _backupInterval.toString(),
                    ['6', '12', '24', '48', '72'],
                    (value) =>
                        setState(() => _backupInterval = int.parse(value!)),
                    suffix: 'hours',
                  ),
                ],
                const Divider(),
                _buildNavigationTile(
                  'Manage Backups',
                  'View, create, and restore backups',
                  Icons.backup,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Inventory Settings
            _buildSectionHeader('Inventory'),
            _buildSettingCard(
              children: [
                _buildNumberTile(
                  'Low Stock Threshold',
                  'Alert when stock falls below this',
                  _lowStockThreshold,
                  (value) => setState(() => _lowStockThreshold = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // POS Settings
            _buildSectionHeader('POS Settings'),
            _buildSettingCard(
              children: [
                _buildNumberTile(
                  'Default Tax Rate',
                  'Applied to all sales (%)',
                  _taxRate.toInt(),
                  (value) => setState(() => _taxRate = value.toDouble()),
                ),
                const Divider(),
                _buildDropdownTile(
                  'Currency',
                  'Default currency for display',
                  _currency,
                  ['PKR', 'USD', 'EUR', 'GBP', 'AED'],
                  (value) => setState(() => _currency = value!),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Printer Settings
            _buildSectionHeader('Printer'),
            _buildPrinterCard(),
            const SizedBox(height: 24),

            // Danger Zone - Clear Data
            _buildSectionHeader('Danger Zone'),
            _buildDangerZoneCard(),
            const SizedBox(height: 24),

            // About
            _buildSectionHeader('About'),
            _buildSettingCard(
              children: [
                _buildInfoTile(
                  'Version',
                  AppConstants.appVersion,
                  Icons.info_outline,
                ),
                const Divider(),
                _buildInfoTile(
                  'App',
                  AppConstants.appName,
                  Icons.point_of_sale,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: AppTheme.titleMedium),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProfileCard(AuthService authService) {
    final user = authService.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Profile Picture with tap to change
          GestureDetector(
            onTap: () => _showProfilePictureOptions(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: _profilePicturePath != null && _profilePicturePath!.isNotEmpty
                      ? FileImage(File(_profilePicturePath!))
                      : null,
                  child: _profilePicturePath == null || _profilePicturePath!.isEmpty
                      ? Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 28,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: AppTheme.titleLarge,
                ),
                Text(
                  user?.email ?? '',
                  style: AppTheme.bodySmall,
                ),
                if (user?.businessName != null)
                  Text(
                    user!.businessName,
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(authService),
          ),
        ],
      ),
    );
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPictureOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildPictureOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (_profilePicturePath != null && _profilePicturePath!.isNotEmpty)
                  _buildPictureOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    color: Colors.red,
                    onTap: () => _removeProfilePicture(),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _profilePicturePath = image.path);
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_picture_path', image.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    setState(() => _profilePicturePath = null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_picture_path');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildUserManagementCard() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text('Staff Members', style: AppTheme.titleMedium),
            subtitle: Text(
              'Add and manage staff accounts',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.security,
                color: AppTheme.warningColor,
              ),
            ),
            title: Text('Roles & Permissions', style: AppTheme.titleMedium),
            subtitle: Text(
              'Admin, Manager, Cashier',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () {
              _showRolesInfoDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showRolesInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Roles & Permissions', style: AppTheme.headingSmall),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleInfo(
                'Admin',
                Icons.admin_panel_settings,
                AppTheme.primaryColor,
                ['Full access to all features', 'Manage users', 'View all reports', 'Backup & restore'],
              ),
              const SizedBox(height: 16),
              _buildRoleInfo(
                'Manager',
                Icons.manage_accounts,
                AppTheme.warningColor,
                ['Manage products & categories', 'View reports', 'Make sales', 'Manage customers'],
              ),
              const SizedBox(height: 16),
              _buildRoleInfo(
                'Cashier',
                Icons.point_of_sale,
                AppTheme.infoColor,
                ['Make sales (POS)', 'View own transactions', 'Basic customer info'],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleInfo(String title, IconData icon, Color color, List<String> permissions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...permissions.map((p) => Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Row(
              children: [
                Icon(Icons.check, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p,
                    style: AppTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPrinterCard() {
    return Consumer<PrinterService>(
      builder: (context, printerService, _) {
        final isConnected = printerService.isConnected;
        final printer = printerService.connectedPrinter;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              InkWell(
                onTap: () => showPrinterSetupSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isConnected 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isConnected ? Icons.print : Icons.print_outlined,
                        color: isConnected 
                            ? AppTheme.successColor 
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printer != null ? printer.name : 'Bluetooth Printer',
                            style: AppTheme.titleMedium,
                          ),
                          Text(
                            isConnected 
                                ? 'Connected' 
                                : printer != null 
                                    ? 'Saved (not connected)' 
                                    : 'Not configured',
                            style: AppTheme.bodySmall.copyWith(
                              color: isConnected 
                                  ? AppTheme.successColor 
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Ready',
                              style: AppTheme.labelMedium.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              if (isConnected) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: printerService.isPrinting 
                            ? null 
                            : () async {
                                final success = await printerService.printTestPage();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success 
                                          ? 'Test page printed!' 
                                          : 'Print failed'),
                                      backgroundColor: success 
                                          ? AppTheme.successColor 
                                          : AppTheme.errorColor,
                                    ),
                                  );
                                }
                              },
                        icon: printerService.isPrinting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.print, size: 18),
                        label: const Text('Test Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => printerService.disconnect(),
                        icon: const Icon(Icons.bluetooth_disabled, size: 18),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncCard(
    ConnectivityService connectivity,
    SyncService syncService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                color: connectivity.isOnline
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectivity.isOnline ? 'Online' : 'Offline',
                      style: AppTheme.titleMedium.copyWith(
                        color: connectivity.isOnline
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ),
                    Text(
                      'Connection: ${connectivity.getConnectionType()}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                syncService.isSyncing ? Icons.sync : Icons.sync_disabled,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending: ${syncService.pendingSyncCount} items',
                      style: AppTheme.titleMedium,
                    ),
                    if (syncService.lastSyncTime != null)
                      Text(
                        'Last sync: ${_formatDateTime(syncService.lastSyncTime!)}',
                        style: AppTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: connectivity.isOnline ? () => syncService.syncAll() : null,
                child: syncService.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sync Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMedium),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    Function(String?) onChanged, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMedium),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: options
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(suffix != null ? '$e $suffix' : e),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTile(
    String title,
    String subtitle,
    int value,
    Function(int) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMedium),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(title, style: AppTheme.titleMedium),
          const Spacer(),
          Text(value, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showEditProfileDialog(AuthService authService) {
    final user = authService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final businessController =
        TextEditingController(text: user?.businessName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Name',
                hint: 'Enter your name',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: businessController,
                label: 'Business Name',
                hint: 'Enter business name',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: phoneController,
                label: 'Phone',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.updateProfile(
                name: nameController.text,
                businessName: businessController.text,
                phone: phoneController.text.isNotEmpty
                    ? phoneController.text
                    : null,
              );
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_forever,
                color: AppTheme.errorColor,
              ),
            ),
            title: Text(
              'Clear All Data',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.errorColor),
            ),
            subtitle: Text(
              'Delete all products, categories, sales & customers',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.errorColor),
            onTap: _showClearDataDialog,
          ),
          const Divider(height: 1, color: Colors.transparent),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restart_alt,
                color: AppTheme.warningColor,
              ),
            ),
            title: Text(
              'Reset App',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.warningColor),
            ),
            subtitle: Text(
              'Clear data and logout (keeps account)',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.warningColor),
            onTap: _showResetAppDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text('Clear All Data', style: AppTheme.headingSmall.copyWith(color: AppTheme.errorColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This will permanently delete:', style: AppTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildDeleteItem('All Products'),
                    _buildDeleteItem('All Categories'),
                    _buildDeleteItem('All Sales & Transactions'),
                    _buildDeleteItem('All Customers'),
                    _buildDeleteItem('All Stock History'),
                    _buildDeleteItem('All Ledger Entries'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type "DELETE" to confirm:',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'Type DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.errorColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.toUpperCase() == 'DELETE') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );

      try {
        // Clear all data from database
        final db = DatabaseHelper();
        await db.clearAllData();
        
        // Reload providers
        if (mounted) {
          await context.read<ProductProvider>().loadProducts();
          await context.read<ProductProvider>().loadCategories();
        }

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showResetAppDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.restart_alt, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            Text('Reset App', style: AppTheme.headingSmall),
          ],
        ),
        content: const Text(
          'This will clear all local data and log you out. Your account will not be deleted.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Reset App'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Resetting app...'),
            ],
          ),
        ),
      );

      try {
        // Clear all data
        final db = DatabaseHelper();
        await db.clearAllData();
        
        // Clear shared preferences (except login info)
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Sign out
        if (mounted) {
          await context.read<AuthService>().signOut();
        }

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting app: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Text(text, style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

