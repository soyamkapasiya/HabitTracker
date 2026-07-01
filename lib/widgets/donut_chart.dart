import 'dart:math';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final String variant; // 'green' | 'rose'

  const DonutChart({
    Key? key,
    required this.percentage,
    this.size = 72,
    this.strokeWidth = 7,
    this.variant = 'green',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              percentage: percentage,
              strokeWidth: strokeWidth,
              variant: variant,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xff1e293b),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final String variant;

  _DonutChartPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.variant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackColor = variant == 'rose' ? const Color(0xffffe4e6) : const Color(0xffe2f0d9);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Paint
    final double sweepAngle = 2 * pi * (percentage / 100).clamp(0.0, 1.0);
    if (sweepAngle <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    if (variant == 'rose') {
      // Circular sweep gradient starting at -90 degrees (top)
      progressPaint.shader = const SweepGradient(
        colors: [Color(0xfff43f5e), Color(0xffec4899), Color(0xfff43f5e)],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(-pi / 2),
      ).createShader(rect);
    } else {
      progressPaint.color = const Color(0xff13854e);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.variant != variant;
  }
}
