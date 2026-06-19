import 'package:flutter/material.dart';

class Duo3dButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback? onPressed;
  final double height;
  final double shadowHeight;
  final double borderRadius;

  const Duo3dButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    this.onPressed,
    this.height = 50,
    this.shadowHeight = 4,
    this.borderRadius = 16,
  });

  @override
  State<Duo3dButton> createState() => _Duo3dButtonState();
}

class _Duo3dButtonState extends State<Duo3dButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double currentShadowHeight = widget.onPressed == null ? 0 : widget.shadowHeight;
    final double translation = _isPressed ? currentShadowHeight : 0;

    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _isPressed = false),
      child: Container(
        height: widget.height + currentShadowHeight,
        decoration: BoxDecoration(
          color: widget.onPressed == null
              ? Colors.grey.shade400
              : widget.shadowColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(0, translation - currentShadowHeight, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? Colors.grey.shade300
                : widget.faceColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
