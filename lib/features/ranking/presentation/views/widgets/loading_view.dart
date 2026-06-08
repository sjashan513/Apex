/// Architectural role: State 2 — ExecutingQuery UI.
/// Renders the archetype accent bar and cycling MicroStateText.
/// Stateless — accent color passed from HomeScreen coordinator.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/micro_state_text.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const MicroStateText(),
          ],
        ),
      ),
    );
  }
}
