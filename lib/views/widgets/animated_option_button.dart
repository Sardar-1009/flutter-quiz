import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AnimatedOptionButton extends StatefulWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isEnabled;
  final VoidCallback onTap;

  const AnimatedOptionButton({
    super.key,
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<AnimatedOptionButton> createState() => _AnimatedOptionButtonState();
}

class _AnimatedOptionButtonState extends State<AnimatedOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.isCorrect) return AppTheme.success.withOpacity(0.15);
    if (widget.isWrong) return AppTheme.error.withOpacity(0.15);
    if (widget.isSelected) return AppTheme.primary.withOpacity(0.2);
    return AppTheme.surfaceLight;
  }

  Color get _borderColor {
    if (widget.isCorrect) return AppTheme.success;
    if (widget.isWrong) return AppTheme.error;
    if (widget.isSelected) return AppTheme.primary;
    return AppTheme.surfaceLight;
  }

  Color get _textColor {
    if (widget.isCorrect) return AppTheme.success;
    if (widget.isWrong) return AppTheme.error;
    if (widget.isSelected) return AppTheme.primary;
    return AppTheme.textPrimary;
  }

  Widget get _trailingIcon {
    if (widget.isCorrect) {
      return const Icon(Icons.check_circle_rounded,
          color: AppTheme.success, size: 22);
    }
    if (widget.isWrong) {
      return const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 22);
    }
    return const SizedBox.shrink();
  }

  String get _optionLetter => ['A', 'B', 'C', 'D'][widget.index];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.isEnabled
          ? (_) {
              _controller.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.isEnabled
          ? () => _controller.reverse()
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _optionLetter,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: widget.isSelected || widget.isCorrect
                        ? FontWeight.w500
                        : FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _trailingIcon,
            ],
          ),
        ),
      ),
    );
  }
}
