import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
    if (widget.token.isEmpty) return _buildInvalidTokenState();
    if (_isSuccess) return _buildSuccessState();
    return _buildFormState();
  }

  Widget _buildInvalidTokenState() {
    return AuthBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                      child: const Icon(Icons.link_off_rounded, size: 30, color: AppColors.error),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Lien invalide',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthStaggeredItem(
                  index: 1,
                  child: AuthFormCard(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cancel_rounded, size: 32, color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Le lien de réinitialisation est invalide ou a expiré.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          AuthPrimaryButton(
                            text: 'Demander un nouveau lien',
                            icon: Icons.mail_rounded,
                            isLoading: false,
                            onPressed: () => context.go(AppRoutes.forgotPassword),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return AuthBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                      child: const Icon(Icons.check_circle_rounded, size: 30, color: AppColors.success),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mot de passe modifié !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthStaggeredItem(
                  index: 1,
                  child: AuthFormCard(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
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
                          const SizedBox(height: 16),
                          Text(
                            'Votre mot de passe a été modifié avec succès.\nVous pouvez maintenant vous connecter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          AuthPrimaryButton(
                            text: 'Se connecter',
                            icon: Icons.login_rounded,
                            isLoading: false,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
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
                      child: const Icon(Icons.lock_reset_rounded, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nouveau mot de passe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Form card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthStaggeredItem(
                  index: 1,
                  child: AuthFormCard(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Text(
                            'Choisissez un nouveau mot de passe sécurisé pour votre compte.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                          ),
                          const SizedBox(height: 24),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // New password
                                const Text(
                                  'Nouveau mot de passe',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
                                  decoration: authInputDecoration(
                                    hint: 'Minimum 6 caractères',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMutedLight,
                                      ),
                                      onPressed: () => setState(() => _showPassword = !_showPassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe';
                                    if (v.length < 6) return 'Minimum 6 caractères';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Confirm password
                                const Text(
                                  'Confirmer le mot de passe',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _confirmController,
                                  obscureText: !_showConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleSubmit(),
                                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
                                  decoration: authInputDecoration(
                                    hint: 'Retapez votre mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMutedLight,
                                      ),
                                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Veuillez confirmer le mot de passe';
                                    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                // Submit
                                AuthPrimaryButton(
                                  text: _isLoading ? 'Réinitialisation...' : 'Réinitialiser le mot de passe',
                                  icon: Icons.lock_reset_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _handleSubmit,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Back to login
              AuthStaggeredItem(
                index: 2,
                child: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Retour à la connexion',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryLight,
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
}
