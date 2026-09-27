import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;

  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenCtrl = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(token);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully! You can now log in.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (widget.email == null || widget.email!.isEmpty) return;

    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resendVerification(widget.email!);
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Verification code resent to ${widget.email}' : 'Failed to resend code'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check Your Email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email != null
                    ? 'We sent a verification token to ${widget.email}. Please paste it below to verify.'
                    : 'Please enter the verification token received in your email.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  hintText: 'Paste verification token here...',
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: auth.isLoading ? null : _handleVerify,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Verify Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.email != null)
                TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Text(
                          "Didn't receive email? Resend code",
                          style: TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
