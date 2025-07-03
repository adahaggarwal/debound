import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WeatherAnimations {
  static Widget getRainAnimation() {
    return const RainAnimation();
  }
  
  static Widget getSunAnimation() {
    return const SunAnimation();
  }
  
  static Widget getCloudAnimation() {
    return const CloudAnimation();
  }
  
  static Widget getSnowAnimation() {
    return const SnowAnimation();
  }
}

class RainAnimation extends StatefulWidget {
  const RainAnimation({super.key});

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Offset> _rainDrops;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rainDrops = List.generate(15, (index) {
      return Offset(
        (index * 20.0) % 200,
        -20.0 - (index * 10.0),
      );
    });
    _controller.repeat();
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
      builder: (context, child) {
        return CustomPaint(
          painter: RainPainter(_controller.value, _rainDrops),
          size: const Size(200, 200),
        );
      },
    );
  }
}

class RainPainter extends CustomPainter {
  final double animationValue;
  final List<Offset> rainDrops;

  RainPainter(this.animationValue, this.rainDrops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rainy.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rainDrops.length; i++) {
      final drop = rainDrops[i];
      final y = (drop.dy + animationValue * (size.height + 40)) % (size.height + 40);
      
      canvas.drawLine(
        Offset(drop.dx, y),
        Offset(drop.dx, y + 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SunAnimation extends StatefulWidget {
  const SunAnimation({super.key});

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<SunAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: SunPainter(_rotationAnimation.value),
          size: const Size(100, 100),
        );
      },
    );
  }
}

class SunPainter extends CustomPainter {
  final double rotation;

  SunPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    
    // Draw sun rays
    final rayPaint = Paint()
      ..color = AppColors.sunny
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 / 4) + rotation;
      final start = Offset(
        center.dx + radius * 1.5 * cos(angle),
        center.dy + radius * 1.5 * sin(angle),
      );
      final end = Offset(
        center.dx + radius * 2 * cos(angle),
        center.dy + radius * 2 * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Draw sun circle
    final sunPaint = Paint()
      ..color = AppColors.sunny
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CloudAnimation extends StatefulWidget {
  const CloudAnimation({super.key});

  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<CloudAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _controller.repeat();
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
      builder: (context, child) {
        return CustomPaint(
          painter: CloudPainter(_controller.value),
          size: const Size(150, 100),
        );
      },
    );
  }
}

class CloudPainter extends CustomPainter {
  final double animationValue;

  CloudPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cloudy
      ..style = PaintingStyle.fill;

    final cloudOffset = animationValue * 50;
    
    // Draw cloud shapes
    _drawCloud(canvas, size, paint, cloudOffset);
    _drawCloud(canvas, size, paint, cloudOffset - 100);
  }

  void _drawCloud(Canvas canvas, Size size, Paint paint, double offset) {
    final x = (offset % (size.width + 100)) - 50;
    final y = size.height / 2;
    
    if (x > -50 && x < size.width + 50) {
      // Main cloud body
      canvas.drawCircle(Offset(x, y), 20, paint);
      canvas.drawCircle(Offset(x + 15, y), 25, paint);
      canvas.drawCircle(Offset(x + 30, y), 20, paint);
      canvas.drawCircle(Offset(x + 15, y - 15), 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SnowAnimation extends StatefulWidget {
  const SnowAnimation({super.key});

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Snowflake> _snowflakes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _snowflakes = List.generate(20, (index) {
      return Snowflake(
        x: (index * 15.0) % 200,
        y: -20.0 - (index * 5.0),
        size: 2.0 + (index % 3),
      );
    });
    _controller.repeat();
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
      builder: (context, child) {
        return CustomPaint(
          painter: SnowPainter(_controller.value, _snowflakes),
          size: const Size(200, 200),
        );
      },
    );
  }
}

class Snowflake {
  final double x;
  final double y;
  final double size;

  Snowflake({required this.x, required this.y, required this.size});
}

class SnowPainter extends CustomPainter {
  final double animationValue;
  final List<Snowflake> snowflakes;

  SnowPainter(this.animationValue, this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final snowflake in snowflakes) {
      final y = (snowflake.y + animationValue * (size.height + 50)) % (size.height + 50);
      
      canvas.drawCircle(
        Offset(snowflake.x, y),
        snowflake.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Helper functions for trigonometry
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);