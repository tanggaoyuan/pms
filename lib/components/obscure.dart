import 'dart:ui';
import 'package:flutter/material.dart';

class ObscureComp extends StatelessWidget {
  final Widget background;
  final ImageFilter? filter;
  final Color? obscureColor;
  final Widget child;
  const ObscureComp({
    super.key,
    required this.child,
    required this.background,
    this.filter,
    this.obscureColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: background),
        ClipRect(
          child: BackdropFilter(
            filter: filter ?? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
                color: obscureColor ?? Colors.black.withValues(alpha: .6)),
          ),
        ),
        child
      ],
    );
  }
}
