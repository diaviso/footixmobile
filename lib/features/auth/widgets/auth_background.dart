import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';

/// Animated gradient background with floating particles for auth screens
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF2D2D2D),
                    Color(0xFF3A3A3A),
                    Color(0xFF2D2D2D),
                    Color(0xFF1A1A1A),
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Radial glow overlay (top-right)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    AppColors.accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Radial glow overlay (bottom-left)
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating particles
          Positioned.fill(
            child: FloatingParticles(count: 12, color: AppColors.accent, maxSize: 6),
          ),

          // Geometric shapes
          const Positioned.fill(child: _GeometricShapes()),

          // Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Glassmorphism card for auth forms
class AuthCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const AuthCard({super.key, required this.child, this.borderRadius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 8),
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

/// Decorative geometric shapes
class _GeometricShapes extends StatefulWidget {
  const _GeometricShapes();

  @override
  State<_GeometricShapes> createState() => _GeometricShapesState();
}

class _GeometricShapesState extends State<_GeometricShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShapesPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ShapesPainter extends CustomPainter {
  final double progress;
  _ShapesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    // Rotating ring top-left
    _drawRing(canvas, Offset(size.width * 0.15, size.height * 0.12), 30, t, 0.06);
    // Rotating ring bottom-right
    _drawRing(canvas, Offset(size.width * 0.85, size.height * 0.88), 25, -t * 0.7, 0.05);
    // Small diamond center-right
    _drawDiamond(canvas, Offset(size.width * 0.9, size.height * 0.35), 12, t * 0.5, 0.07);
    // Small diamond left
    _drawDiamond(canvas, Offset(size.width * 0.08, size.height * 0.65), 10, -t * 0.8, 0.05);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double angle, double opacity) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 1.2), paint);
    canvas.restore();
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, double angle, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size, 0)
      ..lineTo(0, size)
      ..lineTo(-size, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShapesPainter old) => old.progress != progress;
}
