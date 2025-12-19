import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../backup/backup_screen.dart';
import '../auth/login_screen.dart';

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
      appBar: AppBar(
        title: Text('Settings', style: AppTheme.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryColor,
              ),
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
}

