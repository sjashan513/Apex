/// Architectural role: Shared design system component.
/// Cycles through progressive loading micro-copy during ExecutingQuery state.
/// Timing and messages defined in Design Contract §— Stage 2 State 2.
/// Uses a local Timer — no Riverpod needed. State is purely ephemeral.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ── Message definitions ────────────────────────────────────────────────────

const List<String> _messages = [
  'Deconstructing your query intent...',
  'Structuring optimal ranking dimensions...',
  'Synthesizing ranking data...',
];

const Duration _interval = Duration(milliseconds: 1500);

// ── Component ──────────────────────────────────────────────────────────────

/// Animated cycling text widget for the ExecutingQuery loading state.
/// Advances through [_messages] every 1.5 seconds with an opacity crossfade.
class MicroStateText extends StatefulWidget {
  const MicroStateText({super.key});

  @override
  State<MicroStateText> createState() => _MicroStateTextState();
}

class _MicroStateTextState extends State<MicroStateText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Timer _timer;

  int _currentIndex = 0;
  String _currentMessage = _messages[0];

  @override
  void initState() {
    super.initState();

    // Fade controller — drives the crossfade between messages
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start fully visible
    _fadeController.value = 1.0;

    // Advance message every 1.5 seconds
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _advance() {
    // If on last message — loop, no advance
    if (_currentIndex >= _messages.length - 1) {
      // Pulse fade to signal activity on the looping message
      _fadeController.reverse().then((_) {
        if (mounted) _fadeController.forward();
      });
      return;
    }

    // Fade out → update message → fade in
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _currentMessage = _messages[_currentIndex];
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        _currentMessage,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
