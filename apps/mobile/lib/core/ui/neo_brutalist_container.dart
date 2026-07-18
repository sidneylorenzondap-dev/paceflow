import 'package:flutter/material.dart';

class NeoBrutalistContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const NeoBrutalistContainer({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF18181C),
    this.shadowColor = Colors.black,
    this.borderColor = Colors.black,
    this.borderWidth = 3.0,
    this.borderRadius = 0.0,
    this.shadowOffset = 4.0,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(bottom: shadowOffset, right: shadowOffset),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius > borderWidth ? borderRadius - borderWidth : 0),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
