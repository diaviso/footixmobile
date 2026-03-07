import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Stadium-inspired auth background: curved red/gold header + white form area
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Stack(
        children: [
          // Stadium-style curved red header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _StadiumHeaderPainter(),
              size: Size(MediaQuery.of(context).size.width, 320),
            ),
          ),

          // Subtle pitch pattern on header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: CustomPaint(
              painter: _PitchPatternPainter(),
              size: Size(MediaQuery.of(context).size.width, 280),
            ),
          ),

          // Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Curved header painter — red gradient with gold accent line
class _StadiumHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main red gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFAA1830),
          Color(0xFFC41E3A),
          Color(0xFFD42E4A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height - 80)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 30,
        size.width,
        size.height - 80,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Gold accent line at the curve
    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        colors: [
          Color(0x00D4AF37),
          Color(0xFFD4AF37),
          Color(0xFFE5C158),
          Color(0xFFD4AF37),
          Color(0x00D4AF37),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final goldPath = Path()
      ..moveTo(0, size.height - 78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 32,
        size.width,
        size.height - 78,
      );

    canvas.drawPath(goldPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle pitch lines on header
class _PitchPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Center circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      60,
      paint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Horizontal center line
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.45),
      Offset(size.width * 0.85, size.height * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Light-mode form card with subtle shadow
class AuthFormCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const AuthFormCard({super.key, required this.child, this.borderRadius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Staggered fade-in for auth form elements
class AuthStaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AuthStaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 80),
  });

  @override
  State<AuthStaggeredItem> createState() => _AuthStaggeredItemState();
}

class _AuthStaggeredItemState extends State<AuthStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Shared input decoration for auth fields — light mode
InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textMutedLight.withValues(alpha: 0.6), fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondaryLight),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF5F3EF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
  );
}

/// Primary red gradient button for auth
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFC41E3A), Color(0xFFE74C5E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? AppColors.neutral300 : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 20),
          label: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
