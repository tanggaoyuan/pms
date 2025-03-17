import 'package:flutter/material.dart';
import 'package:pms/utils/export.dart';

class AutoSizedText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  const AutoSizedText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color,
    this.fontWeight,
  });

  @override
  State<AutoSizedText> createState() => _AutoSizedTextState();
}

class _AutoSizedTextState extends State<AutoSizedText> {
  @override
  Widget build(BuildContext context) {
    var fontSize = widget.fontSize;
    var color = widget.color;
    var fontWeight = widget.fontWeight;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        while (textPainter.didExceedMaxLines && fontSize > 1) {
          fontSize -= 1;
          textPainter.text = TextSpan(
            text: widget.text,
            style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
          );
          textPainter.layout(maxWidth: constraints.maxWidth);
        }

        return Text(
          widget.text,
          style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
          softWrap: false,
          maxLines: 1,
        );
      },
    );
  }
}
