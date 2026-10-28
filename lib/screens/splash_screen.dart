import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete();
        });
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: Stack(children: [
        Center(
            child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final reveal = Curves.easeInOutCubic
                      .transform(((t - .28) / .34).clamp(0, 1));
                  final word = Curves.easeOutCubic
                      .transform(((t - .64) / .2).clamp(0, 1));
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        width: 210,
                        height: 210,
                        child: Stack(alignment: Alignment.center, children: [
                          CustomPaint(
                              size: const Size(210, 210),
                              painter: _BrandIntroPainter(t)),
                          Opacity(
                              opacity: reveal,
                              child: Transform.scale(
                                  scale: .86 + .14 * reveal,
                                  child: ClipRect(
                                      child: Align(
                                          heightFactor: reveal,
                                          alignment: Alignment.topCenter,
                                          child: SvgPicture.asset(
                                              'SVG/easygradesimbolo.svg',
                                              width: 120,
                                              height: 120))))),
                        ])),
                    const SizedBox(height: 12),
                    Opacity(
                        opacity: word,
                        child: Transform.translate(
                            offset: Offset(0, 18 * (1 - word)),
                            child: const Column(children: [
                              Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: 'easy',
                                        style: TextStyle(
                                            color: AppColors.primary)),
                                    TextSpan(
                                        text: 'grade',
                                        style: TextStyle(
                                            color: AppColors.primaryDark))
                                  ]),
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.6)),
                            ]))),
                  ]);
                })),
      ])));
}

class _BrandIntroPainter extends CustomPainter {
  final double t;
  _BrandIntroPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final lock = Curves.easeOutCubic.transform((t / .22).clamp(0, 1));
    final fade = (1 - ((t - .65) / .25).clamp(0, 1));
    final inset = 18 + 20 * lock;
    p.color = AppColors.primary.withValues(alpha: .8 * fade * lock);
    final r =
        Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    for (final corner in [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft]) {
      final dx = corner.dx < size.width / 2 ? 1.0 : -1.0;
      final dy = corner.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawPath(
          Path()
            ..moveTo(corner.dx, corner.dy + 18 * dy)
            ..lineTo(corner.dx, corner.dy)
            ..lineTo(corner.dx + 18 * dx, corner.dy),
          p);
    }
    final scan = ((t - .14) / .42).clamp(0.0, 1.0);
    final dotFade = (1 - ((t - .33) / .24).clamp(0, 1)) * lock;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final center = Offset(69 + col * 24, 65 + row * 25);
        p.color = AppColors.primary
            .withValues(alpha: dotFade * (col == row ? .95 : .3));
        p.style = col == row ? PaintingStyle.fill : PaintingStyle.stroke;
        canvas.drawCircle(center, 5, p);
      }
    }
    if (scan > 0 && scan < 1) {
      final y = r.top + r.height * scan;
      final line = Paint()
        ..shader = LinearGradient(colors: [
          AppColors.lavender.withValues(alpha: 0),
          AppColors.lavender,
          AppColors.lavender.withValues(alpha: 0)
        ]).createShader(Rect.fromLTWH(r.left, y, r.width, 2))
        ..strokeWidth = 2;
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), line);
    }
    final bloom = ((t - .6) / .22).clamp(0, 1);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color =
          AppColors.lavender.withValues(alpha: math.sin(bloom * math.pi) * .4);
    canvas.drawCircle(size.center(Offset.zero), 62 + bloom * 28, p);
  }

  @override
  bool shouldRepaint(covariant _BrandIntroPainter oldDelegate) =>
      oldDelegate.t != t;
}
