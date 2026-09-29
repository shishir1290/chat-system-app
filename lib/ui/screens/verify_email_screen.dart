import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import 'screens.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;

  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;

  Future<void> _handleOpenEmailApp() async {
    final emailLaunchUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (_) {}
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
          content: Text(success ? 'Verification link resent to ${widget.email}' : 'Failed to resend verification email'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Email illustration badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withAlpha(60), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We have sent a verification email to:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Please check your inbox (and spam folder) and click the verification link inside to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 36),

              // Open Email App Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mail_rounded, size: 20),
                  label: const Text('Open Email App', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleOpenEmailApp,
                ),
              ),
              const SizedBox(height: 14),

              // Continue to Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Back to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend Email Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the email? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: _isResending ? null : _handleResend,
                    child: _isResending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Text(
                            'Resend',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
