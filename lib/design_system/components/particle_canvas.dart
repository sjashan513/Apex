/// Architectural role: Shell screen background component.
/// Renders 50-55 animated particles with connection lines using CustomPainter.
/// Uses a Ticker-driven AnimationController — zero widget rebuilds per frame.
/// Scope: State 1 (Idle), State 2 (Loading), State 5 (Humor), State 6 (Error).
/// Never rendered on State 3 (Dashboard) or State 4 (Detail).
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Particle data model ────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });

  double x;
  double y;
  double vx; // velocity x
  double vy; // velocity y
  final double radius;
  final double opacity;
}

// ── Particle system factory ────────────────────────────────────────────────

List<_Particle> _buildParticles(Size size, math.Random rng) {
  const count = 52; // midpoint of 50-55 range from Design Contract
  return List.generate(count, (_) {
    // speed range: 0.2 – 0.25 px/frame from Design Contract §08
    final speed = 0.2 + rng.nextDouble() * 0.05;
    final angle = rng.nextDouble() * 2 * math.pi;
    return _Particle(
      x: rng.nextDouble() * size.width,
      y: rng.nextDouble() * size.height,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed,
      // radius range: 0.3 – 1.7dp from Design Contract §08
      radius: 0.3 + rng.nextDouble() * 1.4,
      // opacity range: 0.06 – 0.40 from Design Contract §08
      opacity: 0.06 + rng.nextDouble() * 0.34,
    );
  });
}

// ── CustomPainter ──────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.particleColor,
    required this.animation,
  }) : super(repaint: animation);

  final List<_Particle> particles;
  final Color particleColor;
  final Animation<double> animation;

  // connection distance: 72-80dp midpoint from Design Contract §08
  static const double _connectionDistance = 76;
  static const double _connectionDistanceSq =
      _connectionDistance * _connectionDistance;

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle positions — bounce off edges
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;

      if (p.x < 0 || p.x > size.width) p.vx *= -1;
      if (p.y < 0 || p.y > size.height) p.vy *= -1;
    }

    // Draw connection lines
    final linePaint = Paint()
      ..strokeWidth = 0.5 // Design Contract §08
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final distSq = dx * dx + dy * dy;

        if (distSq < _connectionDistanceSq) {
          // Opacity fades as distance increases — max 0.10 from Design Contract §08
          final proximity = 1 - (distSq / _connectionDistanceSq);
          linePaint.color = particleColor.withValues(alpha: proximity * 0.10);
          canvas.drawLine(
            Offset(particles[i].x, particles[i].y),
            Offset(particles[j].x, particles[j].y),
            linePaint,
          );
        }
      }
    }

    // Draw particle nodes
    final nodePaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      nodePaint.color = particleColor.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ── Public widget ──────────────────────────────────────────────────────────

/// Animated particle background for shell screens.
/// [isError] switches particle color to red for State 6 per Design Contract §08.
class ParticleCanvas extends StatefulWidget {
  const ParticleCanvas({
    super.key,
    this.isError = false,
  });

  final bool isError;

  @override
  State<ParticleCanvas> createState() => _ParticleCanvasState();
}

class _ParticleCanvasState extends State<ParticleCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Drives the repaint loop — no value used, just the tick signal
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Particles initialized with a placeholder size — repositioned on first paint
    _particles = _buildParticles(const Size(400, 800), _rng);
  }

  @override
  void dispose() {
    // Critical — AnimationController must be disposed or the Ticker leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? AppColors.error : AppColors.accentGlobal;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          particleColor: color,
          animation: _controller,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
