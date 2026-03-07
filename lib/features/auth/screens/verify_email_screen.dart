import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../widgets/auth_background.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.register);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).verifyEmail(
            email: widget.email,
            code: code,
          );
      if (mounted) {
        setState(() => _isVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre compte a été activé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go(AppRoutes.dashboard);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authProvider).error ?? 'Code invalide ou expiré',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──
              const SizedBox(height: 44),
              AuthStaggeredItem(
                index: 0,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isVerified ? Icons.check_circle_rounded : Icons.mark_email_unread_rounded,
                        size: 30,
                        color: _isVerified ? AppColors.success : AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isVerified ? 'Email vérifié !' : 'Vérifiez votre email',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Content card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthStaggeredItem(
                  index: 1,
                  child: AuthFormCard(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: _isVerified ? _buildVerifiedContent() : _buildFormContent(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedContent() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_rounded, size: 32, color: AppColors.success),
        ),
        const SizedBox(height: 18),
        const Text(
          'Votre compte a été activé !',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Redirection en cours...',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        // Description
        Text(
          'Nous avons envoyé un code de vérification à',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Code input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Code de vérification',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              onFieldSubmitted: (_) => _handleVerify(),
              onChanged: (v) {
                final cleaned = v.replaceAll(RegExp(r'\D'), '');
                if (cleaned != v || cleaned.length > 6) {
                  _codeController.text = cleaned.substring(0, cleaned.length.clamp(0, 6));
                  _codeController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _codeController.text.length),
                  );
                }
                setState(() {});
              },
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  color: AppColors.textMutedLight.withValues(alpha: 0.4),
                  letterSpacing: 10,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                errorStyle: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Verify button
        AuthPrimaryButton(
          text: 'Vérifier',
          icon: Icons.verified_rounded,
          isLoading: _isLoading,
          onPressed: _handleVerify,
        ),
        const SizedBox(height: 20),

        // Resend & back
        Text(
          "Vous n'avez pas reçu le code ?",
          style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
        ),
        TextButton(
          onPressed: () async {
            try {
              await ref.read(authServiceProvider).resendVerification(email: widget.email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Un nouveau code a été envoyé'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible de renvoyer le code'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: const Text(
            'Renvoyer',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.register),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text("Retour à l'inscription"),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
