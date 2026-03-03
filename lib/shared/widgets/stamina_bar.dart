import 'package:flutter/material.dart';

/// Segmented stamina/progress bar with color-coded levels.
class StaminaBar extends StatefulWidget {
  final double value; // 0–100
  final double max;
  final String? label;
  final bool showValue;
  final int segments;
  final double height;

  const StaminaBar({
    super.key,
    required this.value,
    this.max = 100,
    this.label,
    this.showValue = true,
    this.segments = 10,
    this.height = 10,
  });

  @override
  State<StaminaBar> createState() => _StaminaBarState();
}

class _StaminaBarState extends State<StaminaBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(StaminaBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double pct) {
    if (pct >= 70) return const Color(0xFF22C55E);
    if (pct >= 40) return const Color(0xFFD4AF37);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (widget.value / widget.max * 100).clamp(0, 100).toDouble();
    final color = _getColor(pct);
    final filledSegments = (pct / 100 * widget.segments).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row
        if (widget.label != null || widget.showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE2E8F5) : const Color(0xFF0A1628),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (widget.showValue)
                  Text(
                    '${pct.round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),

        // Segmented bar
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              height: widget.height,
              child: Row(
                children: List.generate(widget.segments, (i) {
                  final isFilled = i < filledSegments;
                  final segmentProgress = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      (i / widget.segments * 0.7).clamp(0.0, 1.0),
                      ((i + 1) / widget.segments * 0.7 + 0.3).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < widget.segments - 1 ? 2 : 0),
                      child: Transform.scale(
                        scaleY: isFilled ? segmentProgress.value : 1.0,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isFilled
                                ? color
                                : isDark
                                    ? const Color(0xFF111B2E)
                                    : const Color(0xFFEFF3F7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
