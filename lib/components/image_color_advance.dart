// ignore_for_file: must_be_immutable, file_names

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:pms/components/export.dart';

class ImageColorAdvance extends StatefulWidget {
  final ImgComp image;
  Widget Function(PaletteGenerator color, ImgComp image) builder;

  ImageColorAdvance({super.key, required this.builder, required this.image});

  @override
  State<ImageColorAdvance> createState() => _ImageColorAdvanceState();
}

class _ImageColorAdvanceState extends State<ImageColorAdvance> {
  PaletteGenerator color = PaletteGenerator.fromColors([PaletteColor(Colors.transparent, 0)]);

  void init() async {
    var info = await ImgComp.getImageInfo(widget.image.source);
    var image = info.image;
    var rectWidth = image.width.toDouble();
    var rectHeight = image.height.toDouble();
    var colorMap = await PaletteGenerator.fromImage(
      image,
      region: Rect.fromCenter(
        center: Offset(image.width / 2.0, image.height / 2.0),
        width: rectWidth,
        height: rectHeight,
      ),
      maximumColorCount: 5,
    );
    setState(() {
      color = colorMap;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didUpdateWidget(covariant ImageColorAdvance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.source != widget.image.source) {
      init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(color, widget.image);
  }
}
