import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'neo_brutalist_container.dart';

class NeoBrutalistButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final double? width;
  final double? height;

  const NeoBrutalistButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppTheme.primaryColor,
    this.shadowColor = Colors.black,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
    this.borderRadius = 0.0,
    this.shadowOffset = 4.0,
    this.width,
    this.height,
  });

  @override
  State<NeoBrutalistButton> createState() => _NeoBrutalistButtonState();
}

class _NeoBrutalistButtonState extends State<NeoBrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset : 0,
          _isPressed ? widget.shadowOffset : 0,
          0,
        ),
        child: NeoBrutalistContainer(
          width: widget.width,
          height: widget.height,
          backgroundColor: widget.backgroundColor,
          shadowColor: widget.shadowColor,
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          borderRadius: widget.borderRadius,
          shadowOffset: _isPressed ? 0 : widget.shadowOffset,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
