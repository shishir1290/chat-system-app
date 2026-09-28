import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameCtrl = TextEditingController();

  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _isSaving = true);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final success = await auth.uploadAvatar(File(picked.path));
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Avatar updated successfully' : 'Failed to update avatar'),
            backgroundColor: success ? AppColors.primary : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveProfileName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(name: name);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final oldP = _oldPassCtrl.text;
    final newP = _newPassCtrl.text;
    if (oldP.isEmpty || newP.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(oldP, newP);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Failed to change password'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'New Password (min 6 chars)'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isSaving ? null : _changePassword,
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  CustomAvatar(
                    name: user.name,
                    avatarUrl: user.avatar,
                    size: 90,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Profile Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _isSaving ? null : _saveProfileName,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Security Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Update your account security credentials', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final socket = context.read<SocketProvider>();
                  final authProvider = context.read<AuthProvider>();

                  socket.disconnect();
                  nav.popUntil((route) => route.isFirst);
                  await authProvider.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
