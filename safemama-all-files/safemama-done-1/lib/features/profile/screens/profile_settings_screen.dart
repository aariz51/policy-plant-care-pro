// lib/features/profile/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/l10n/app_localizations.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  // State and helper methods are preserved, adapted for the new UI
  final _nameController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    final userProfile = ref.read(userProfileNotifierProvider);
    _nameController.text = userProfile.fullName;
    _selectedDueDate = userProfile.userPregnancyDetails?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final profileNotifier = ref.read(userProfileNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    await profileNotifier.saveUserProfile(name: _nameController.text.trim());
    await profileNotifier.updateUserDueDate(_selectedDueDate);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.profileSavedSuccess),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.read(localeProvider).currentLocale;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now().add(const Duration(days: 300)),
      helpText: l10n.profileSetDueDateButton.toUpperCase(),
      locale: locale,
    );

    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() => _selectedDueDate = pickedDate);
    }
  }

  void _signOut() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(l10n.signOutDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancelButtonLabel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.avoidRed),
            child: Text(l10n.signOutButton),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(userProfileNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

  // The build method is completely redesigned
  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isSaving = userProfileState.isSaving;

    // Sync state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_nameController.text != userProfileState.fullName) {
        _nameController.text = userProfileState.fullName;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.profileSettingsTitle),
        elevation: 0,
        backgroundColor: Colors.transparent, // More modern look
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRouter.homePath),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: isSaving ? null : _saveProfile,
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("Save", style: textTheme.titleMedium?.copyWith(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: isSaving,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- NEW: User info card ---
            _buildUserInfoCard(context, userProfileState.fullName, userProfileState.email ?? '', userProfileState.profileImageUrl),
            const SizedBox(height: 24),

            // --- Your Journey Section ---
            _buildSectionHeader("Your Journey"),
            _buildDueDateCard(),
            const SizedBox(height: 24),

            // --- Account Management Section ---
            _buildSectionHeader("Account Management"),
            _buildSignOutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, String name, String email, String imageUrl) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: textTheme.headlineMedium?.copyWith(color: AppTheme.primaryPurple)) : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration.collapsed(hintText: 'Your Name'),
            ),
            const SizedBox(height: 4),
            Text(email, style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDueDateCard() {
     final l10n = AppLocalizations.of(context)!;
     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryPurple),
        ),
        title: Text(l10n.profileDueDateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          _selectedDueDate != null ? DateFormat.yMMMMd().format(_selectedDueDate!) : "Not set",
          style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)
        ),
        trailing: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
        onTap: _pickDueDate,
      ),
    );
  }

  Widget _buildSignOutCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.avoidRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: AppTheme.avoidRed),
        ),
        title: const Text("Sign Out", style: TextStyle(color: AppTheme.avoidRed, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.avoidRed),
        onTap: _signOut,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}