/// Architectural role: State 2 — ExecutingQuery UI.
/// Renders the full loading progression: query pill, arc ring,
/// micro-state copy, step indicators, timeout bar, and cancel action.
/// Timeout bar driven by AnimationController at vsync frequency — no jumps.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';

// ── Micro-state definitions ────────────────────────────────────────────────

class _MicroState {
  const _MicroState({
    required this.label,
    required this.message,
    required this.sub,
    required this.arcPercent,
  });
  final String label;
  final String message;
  final String sub;
  final double arcPercent;
}

const List<_MicroState> _microStates = [
  _MicroState(
    label: 'Analyzing intent',
    message: 'Deconstructing your query intent...',
    sub: 'Identifying ranking dimensions',
    arcPercent: 15,
  ),
  _MicroState(
    label: 'Structuring schema',
    message: 'Structuring optimal ranking dimensions...',
    sub: 'Mapping archetype fields',
    arcPercent: 40,
  ),
  _MicroState(
    label: 'Awaiting inference',
    message: 'Synthesizing ranking data...',
    sub: 'Calling OpenAI · waiting for response',
    arcPercent: 65,
  ),
  _MicroState(
    label: 'Auto recovery',
    message: 'Resolving structural discrepancies...',
    sub: 'Revalidating schema',
    arcPercent: 88,
  ),
];

const List<int> _stateTimings = [0, 1500, 3000, 9000];
const int _totalSeconds = 25;

// ── Arc painter ────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = accentColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Component ──────────────────────────────────────────────────────────────

class LoadingView extends StatefulWidget {
  const LoadingView({
    super.key,
    required this.accentColor,
    required this.query,
    required this.onCancel,
  });

  final Color accentColor;
  final String query;
  final VoidCallback onCancel;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with TickerProviderStateMixin {
  int _currentStateIndex = 0;
  double _elapsedSeconds = 0;
  late final Stopwatch _stopwatch;
  late final AnimationController _timeoutController;
  StreamSubscription<int>? _tickerSub;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();

    // Drives the timeout bar — linear over 18 seconds, vsync-accurate
    _timeoutController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    )..forward();

    // Drives micro-state text and step dots — 100ms is fine for text updates
    _tickerSub = Stream.periodic(
      const Duration(milliseconds: 100),
      (tick) => tick,
    ).listen((_) {
      if (!mounted) return;
      final elapsed = _stopwatch.elapsedMilliseconds;

      int targetState = 0;
      for (int i = 0; i < _stateTimings.length; i++) {
        if (elapsed >= _stateTimings[i]) targetState = i;
      }

      setState(() {
        _currentStateIndex = targetState;
        _elapsedSeconds = math.min(
          elapsed / 1000,
          _totalSeconds.toDouble(),
        );
      });
    });
  }

  @override
  void dispose() {
    _tickerSub?.cancel();
    _stopwatch.stop();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _microStates[_currentStateIndex];
    final arcProgress = state.arcPercent / 100;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),

            // Query pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Ranking: ',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textGhost,
                  ),
                  children: [
                    TextSpan(
                      text: widget.query,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 48),

            // Arc progress ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _ArcPainter(
                      progress: arcProgress,
                      accentColor: widget.accentColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.memory_rounded,
                        color: widget.accentColor,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.arcPercent.toInt()}%',
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Micro-state label
            Text(
              state.label.toUpperCase(),
              style: AppTypography.eyebrow.copyWith(
                color: widget.accentColor,
              ),
            ),

            const SizedBox(height: 10),

            // Micro-state message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                state.message,
                key: ValueKey(state.message),
                style: AppTypography.screenTitle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Sub-message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                state.sub,
                key: ValueKey(state.sub),
                style: AppTypography.body.copyWith(
                  color: AppColors.textGhost,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // Step dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _microStates.length * 2 - 1,
                (i) {
                  if (i.isOdd) {
                    final lineIndex = i ~/ 2;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 1,
                      color: lineIndex < _currentStateIndex
                          ? widget.accentColor
                          : AppColors.surfaceRaised,
                    );
                  }
                  final dotIndex = i ~/ 2;
                  final isDone = dotIndex < _currentStateIndex;
                  final isActive = dotIndex == _currentStateIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive
                          ? widget.accentColor
                          : AppColors.surfaceRaised,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color:
                                    widget.accentColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 48),

            // Timeout bar — AnimatedBuilder at vsync frequency, zero jumps
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Track
                      Container(
                        height: 3,
                        color: AppColors.surface,
                      ),
                      // Bar — driven directly by AnimationController
                      AnimatedBuilder(
                        animation: _timeoutController,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            widthFactor: _timeoutController.value,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.accentColor,
                                    AppColors.error,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_elapsedSeconds.toStringAsFixed(0)}s / ${_totalSeconds}s',
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.border,
                    fontSize: 9,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Cancel button
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Cancel query',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textGhost,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
