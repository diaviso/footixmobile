import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../data/api/api_exception.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/service_providers.dart';
import '../widgets/auth_background.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le lien de réinitialisation est invalide ou a expiré'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go(AppRoutes.forgotPassword);
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(
        token: widget.token,
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() => _isSuccess = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
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
    // Invalid token state
    if (widget.token.isEmpty) {
      return _buildInvalidTokenState();
    }

    // Success state
    if (_isSuccess) {
      return _buildSuccessState();
    }

    // Form state
    return _buildFormState();
  }

  // ── Invalid token state ──
  Widget _buildInvalidTokenState() {
    return AuthBackground(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthStaggeredItem(
              index: 0,
              child: AuthCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cancel_rounded, size: 36, color: AppColors.error),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Lien invalide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Le lien de réinitialisation est invalide ou a expiré.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Request new link button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppDesign.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.forgotPassword),
                            icon: const Icon(Icons.mail_rounded, size: 20),
                            label: const Text(
                              'Demander un nouveau lien',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Success state ──
  Widget _buildSuccessState() {
    return AuthBackground(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthStaggeredItem(
              index: 0,
              child: AuthCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 16),
                        ),
                        child: const Icon(Icons.check_circle_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Mot de passe réinitialisé !',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppDesign.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.login),
                            icon: const Icon(Icons.login_rounded, size: 20),
                            label: const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form state ──
  Widget _buildFormState() {
    return AuthBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AuthStaggeredItem(
              index: 0,
              child: AuthCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Lock icon
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppDesign.glowShadow(AppColors.primary, blur: 16),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Nouveau mot de passe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Choisissez un nouveau mot de passe sécurisé pour votre compte.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // New password field
                            _buildPasswordField(
                              label: 'Nouveau mot de passe',
                              hint: 'Minimum 6 caractères',
                              controller: _passwordController,
                              showPassword: _showPassword,
                              toggleVisibility: () => setState(() => _showPassword = !_showPassword),
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe';
                                if (v.length < 6) return 'Minimum 6 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Confirm password field
                            _buildPasswordField(
                              label: 'Confirmer le mot de passe',
                              hint: 'Retapez votre mot de passe',
                              controller: _confirmController,
                              showPassword: _showConfirm,
                              toggleVisibility: () => setState(() => _showConfirm = !_showConfirm),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Veuillez confirmer le mot de passe';
                                if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: _isLoading ? null : AppDesign.primaryGradient,
                                  color: _isLoading ? Colors.white.withValues(alpha: 0.1) : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _isLoading ? null : AppDesign.glowShadow(AppColors.primary, blur: 12),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.lock_reset_rounded, size: 20),
                                  label: Text(
                                    _isLoading ? 'Réinitialisation...' : 'Réinitialiser le mot de passe',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to login
                      TextButton.icon(
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Retour à la connexion'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback toggleVisibility,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          textInputAction: textInputAction ?? TextInputAction.next,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: Colors.white.withValues(alpha: 0.5)),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              onPressed: toggleVisibility,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
          ),
        ),
      ],
    );
  }
}
