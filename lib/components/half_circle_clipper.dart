import 'package:flutter/material.dart';

class BottomArcClipper extends CustomClipper<Path> {
  double offset;

  BottomArcClipper({required this.offset});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - offset)
      ..quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width,
        size.height - offset,
      )
      ..lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

class BottomArcClip extends StatelessWidget {
  final Widget child;
  final double offset;

  const BottomArcClip({
    super.key,
    required this.child,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomArcClipper(offset: offset),
      child: child,
    );
  }
}
