import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
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
    if (_isVerified) {
      return AuthBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AuthStaggeredItem(
                index: 0,
                child: AuthCard(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 16),
                        ),
                        child: const Icon(Icons.check_circle_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text('Email vérifié !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Votre compte a été activé avec succès.\nRedirection en cours...',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 24),
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AuthBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AuthStaggeredItem(
              index: 0,
              child: AuthCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    // Icon
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: AppDesign.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 14),
                      ),
                      child: const Icon(Icons.mail_rounded, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text('Vérifiez votre email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Nous avons envoyé un code de vérification à',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Text(widget.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    const SizedBox(height: 24),

                    // Code input
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Code de vérification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
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
                            _codeController.selection = TextSelection.fromPosition(TextPosition(offset: _codeController.text.length));
                          }
                          setState(() {});
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 8),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
                          errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Verify button
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _codeController.text.length == 6 ? AppDesign.primaryGradient : null,
                          color: _codeController.text.length == 6 ? null : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _codeController.text.length == 6 ? AppDesign.glowShadow(AppColors.primary, blur: 12) : null,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_codeController.text.length == 6 ? _handleVerify : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Vérifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend & back
                    Text("Vous n'avez pas reçu le code ?", style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(authServiceProvider).resendVerification(email: widget.email);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Un nouveau code a été envoyé'), backgroundColor: AppColors.success),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impossible de renvoyer le code'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      child: const Text('Renvoyer', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.register),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text("Retour à l'inscription"),
                      style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
