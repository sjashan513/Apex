/// Architectural role: Shared design system component.
/// Primary query input for State 1 (Idle) and recovery states.
/// Owns TextEditingController and FocusNode — disposes both on removal.
/// Submit logic lives in the parent screen — this component fires a callback.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SearchInput extends StatefulWidget {
  const SearchInput({
    super.key,
    required this.onSubmit,
    this.initialValue = '',
    this.isEnabled = true,
  });

  /// Called when the user taps submit or presses enter.
  /// Receives the trimmed query string.
  final ValueChanged<String> onSubmit;
  final String initialValue;
  final bool isEnabled;

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _hasText = widget.initialValue.trim().isNotEmpty;

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmit(query);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52, // Design Contract §10
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.isEnabled,
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accentGlobal,
        onSubmitted: (_) => _handleSubmit(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Ask anything worth ranking...',
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textGhost,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Design Contract §10
            borderSide: const BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.accentGlobal,
              width: 0.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          // Submit button — right side
          suffixIcon: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _hasText ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: _hasText ? _handleSubmit : null,
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentGlobal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.canvas,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
