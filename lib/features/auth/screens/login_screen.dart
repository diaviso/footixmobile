import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bienvenue ${ref.read(authProvider).user?.firstName ?? ''} !',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ref.read(authProvider).error ?? '';
        if (errorMsg.contains('EMAIL_NOT_VERIFIED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Un code de vérification a été envoyé à votre email'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(
            '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_emailController.text.trim())}',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.isNotEmpty ? errorMsg : 'Email ou mot de passe incorrect'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).googleLogin();
      if (mounted && ref.read(authProvider).isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bienvenue ${ref.read(authProvider).user?.firstName ?? ''} !',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la connexion Google'),
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
              // ── Header area (inside the red curve) ──
              const SizedBox(height: 40),
              AuthStaggeredItem(
                index: 0,
                child: Column(
                  children: [
                    // Football icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Footix',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz football entre amis',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Session expired banner ──
              Consumer(builder: (context, ref, _) {
                final authError = ref.watch(authProvider).error;
                if (authError != null && authError.contains('déconnecté')) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authError,
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(authProvider.notifier).clearError(),
                            child: Icon(Icons.close_rounded, color: Colors.amber.shade600, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // ── Form card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthStaggeredItem(
                  index: 1,
                  child: AuthFormCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.login_rounded, size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Connexion',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email
                                _fieldLabel('Email'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
                                  decoration: authInputDecoration(
                                    hint: 'vous@exemple.com',
                                    icon: Icons.mail_outline_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Veuillez entrer votre email';
                                    if (!v.contains('@')) return 'Email invalide';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                _fieldLabel('Mot de passe'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
                                  decoration: authInputDecoration(
                                    hint: '••••••••',
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
                                    if (v == null || v.isEmpty) return 'Veuillez entrer votre mot de passe';
                                    return null;
                                  },
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push(AppRoutes.forgotPassword),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Login button
                                AuthPrimaryButton(
                                  text: _isLoading ? 'Connexion...' : 'Se connecter',
                                  icon: Icons.arrow_forward_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // OR divider
                          // Google sign-in hidden for now
                          // Row(
                          //   children: [
                          //     Expanded(child: Divider(color: AppColors.borderLight.withValues(alpha: 0.5))),
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(horizontal: 14),
                          //       child: Text('OU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMutedLight)),
                          //     ),
                          //     Expanded(child: Divider(color: AppColors.borderLight.withValues(alpha: 0.5))),
                          //   ],
                          // ),
                          // const SizedBox(height: 20),
                          // _GoogleSignInButton(
                          //   onPressed: _isLoading ? null : _handleGoogleLogin,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Register link ──
              AuthStaggeredItem(
                index: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}

// ── Google sign-in button ──
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleSignInButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0DCD5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuer avec Google',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, bluePaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.3, whitePaint);

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.9, height: h * 0.9),
      -1.0, 0.8, true, redPaint,
    );

    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.9, height: h * 0.9),
      1.5, 0.8, true, yellowPaint,
    );

    final greenPaint = Paint()..color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.9, height: h * 0.9),
      2.3, 1.0, true, greenPaint,
    );

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.28, whitePaint);

    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.35, w * 0.42, h * 0.3), bluePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.42, w * 0.42, h * 0.16), whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
