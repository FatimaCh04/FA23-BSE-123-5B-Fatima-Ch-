import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/backup_service.dart';
import '../../widgets/common/custom_button.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FileSystemEntity> _localBackups = [];
  List<drive.File> _cloudBackups = [];
  bool _isLoadingLocal = true;
  bool _isLoadingCloud = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalBackups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalBackups() async {
    setState(() => _isLoadingLocal = true);
    final backupService = context.read<BackupService>();
    _localBackups = await backupService.getLocalBackups();
    setState(() => _isLoadingLocal = false);
  }

  Future<void> _loadCloudBackups() async {
    setState(() => _isLoadingCloud = true);
    final backupService = context.read<BackupService>();
    _cloudBackups = await backupService.getGoogleDriveBackups();
    setState(() => _isLoadingCloud = false);
  }

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Backup & Restore',
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
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          onTap: (index) {
            if (index == 1 && _cloudBackups.isEmpty) {
              _loadCloudBackups();
            }
          },
          tabs: const [
            Tab(text: 'Local Backup'),
            Tab(text: 'Google Drive'),
          ],
        ),
      ),
      body: Consumer<BackupService>(
        builder: (context, backupService, _) {
          return Column(
            children: [
              // Progress Indicator
              if (backupService.isBackingUp || backupService.isRestoring)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              backupService.backupStatus,
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: backupService.progress,
                        backgroundColor: AppTheme.dividerColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLocalBackupTab(backupService),
                    _buildCloudBackupTab(backupService),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocalBackupTab(BackupService backupService) {
    return Column(
      children: [
        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Create Local Backup',
            icon: Icons.save,
            isLoading: backupService.isBackingUp,
            onPressed: () async {
              final path = await backupService.createLocalBackup();
              if (path != null && mounted) {
                _loadLocalBackups();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Backup created successfully'), backgroundColor: AppTheme.snackBarAdd),
                );
              }
            },
          ),
        ),

        // Last Backup Info
        if (backupService.lastBackupTime != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last backup',
                          style: AppTheme.labelMedium
                              .copyWith(color: AppTheme.successColor),
                        ),
                        Text(
                          _formatDateTime(backupService.lastBackupTime!),
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Local Backups', style: AppTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: _loadLocalBackups,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // Backup List
        Expanded(
          child: _isLoadingLocal
              ? const Center(child: CircularProgressIndicator())
              : _localBackups.isEmpty
                  ? _buildEmptyState('No local backups found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _localBackups.length,
                      itemBuilder: (context, index) {
                        final backup = _localBackups[index];
                        final stat = backup.statSync();
                        final fileName = backup.path.split('/').last;
                        return _buildBackupCard(
                          fileName,
                          stat.modified,
                          _formatFileSize(stat.size),
                          onRestore: () =>
                              _restoreLocalBackup(backup.path, backupService),
                          onDelete: () =>
                              _deleteLocalBackup(backup.path, backupService),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCloudBackupTab(BackupService backupService) {
    return Column(
      children: [
        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Backup to Google Drive',
            icon: Icons.cloud_upload,
            isLoading: backupService.isBackingUp,
            onPressed: () async {
              final success = await backupService.createGoogleDriveBackup();
              if (success && mounted) {
                _loadCloudBackups();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text('Backup uploaded to Google Drive'),
                      backgroundColor: AppTheme.snackBarAdd),
                );
              }
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Google Drive Backups', style: AppTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: _loadCloudBackups,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // Cloud Backup List
        Expanded(
          child: _isLoadingCloud
              ? const Center(child: CircularProgressIndicator())
              : _cloudBackups.isEmpty
                  ? _buildEmptyState('No Google Drive backups found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cloudBackups.length,
                      itemBuilder: (context, index) {
                        final backup = _cloudBackups[index];
                        return _buildBackupCard(
                          backup.name ?? 'Backup',
                          backup.createdTime,
                          backup.size != null
                              ? _formatFileSize(int.parse(backup.size!))
                              : 'Unknown',
                          onRestore: () => _restoreCloudBackup(
                              backup.id!, backupService),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildBackupCard(
    String name,
    DateTime? date,
    String size, {
    VoidCallback? onRestore,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_zip,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (date != null) ...[
                      Text(
                        _formatDateTime(date),
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      size,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore, color: AppTheme.primaryColor),
                onPressed: onRestore,
                tooltip: 'Restore',
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backup_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _restoreLocalBackup(
      String path, BackupService backupService) async {
    final confirm = await _showRestoreConfirmation();
    if (confirm != true) return;

    final success = await backupService.restoreFromLocalBackup(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Restore completed' : 'Restore failed',
          ),
        ),
      );
    }
  }

  Future<void> _restoreCloudBackup(
      String fileId, BackupService backupService) async {
    final confirm = await _showRestoreConfirmation();
    if (confirm != true) return;

    final success = await backupService.restoreFromGoogleDrive(fileId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Restore completed' : 'Restore failed',
          ),
        ),
      );
    }
  }

  Future<void> _deleteLocalBackup(
      String path, BackupService backupService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await backupService.deleteLocalBackup(path);
      if (success && mounted) {
        _loadLocalBackups();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Backup deleted'), backgroundColor: AppTheme.snackBarDelete),
        );
      }
    }
  }

  Future<bool?> _showRestoreConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all current data with the backup data. '
          'This action cannot be undone. Are you sure?',
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
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

