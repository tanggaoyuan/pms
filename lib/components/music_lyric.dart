import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lyric_xx/Lyricxx.dart';
import 'package:pms/apis/export.dart';

class MusicLyricComp extends StatefulWidget {
  final NetLrc lrc;
  final Duration position;
  final Color color;
  final Function(Duration position) onPositionChanged;

  const MusicLyricComp({
    super.key,
    required this.lrc,
    required this.position,
    required this.onPositionChanged,
    this.color = Colors.white,
  });

  @override
  State<StatefulWidget> createState() {
    return _MusicLyricCompState();
  }
}

class _MusicLyricCompState extends State<MusicLyricComp> {
  late List<LyricSrcItemEntity_c> mainLrcs = [];
  late Map<double, String> translateLrcs = {};
  late Map<double, String> romaLrcs = {};

  late ScrollController _controller;
  late double height = 0;
  late int current = 0;
  Timer? positionLineTimer;
  bool isShowPositionLine = false;
  bool showRangeBlock = false;
  int hoverIndex = 0;

  GlobalKey scrollKey = GlobalKey();

  init() {
    final main = Lyricxx_c.decodeLrcString(widget.lrc.mainLrc);
    final translate = Lyricxx_c.decodeLrcString(widget.lrc.translateLrc);
    final roma = Lyricxx_c.decodeLrcString(widget.lrc.romaLrc);
    setState(() {
      mainLrcs = main.lrc;
      Map<double, String> translateMap = {};
      for (var item in translate.lrc) {
        translateMap[item.time] = item.content;
      }
      translateLrcs = translateMap;

      Map<double, String> romaMap = {};
      for (var item in roma.lrc) {
        romaMap[item.time] = item.content;
      }
      romaLrcs = romaMap;
    });
  }

  int getIndexByPosition(Duration position) {
    for (int i = 0; i < mainLrcs.length; i++) {
      var millTime = position.inSeconds + 0.5;
      if (mainLrcs[i].time <= millTime &&
          ((i == mainLrcs.length - 1) || (mainLrcs[i + 1].time > millTime))) {
        return i;
      }
    }
    return 0;
  }

  updatePosition() {
    if (height == 0 || isShowPositionLine) {
      return;
    }
    var index = getIndexByPosition(widget.position);
    var offset = index * 50 + 25;
    if (current != index) {
      _controller.animateTo(
        offset.toDouble(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
      setState(() {
        current = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        height = scrollKey.currentContext?.size?.height ?? 0;
      });
    });
    setState(() {});
    init();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant MusicLyricComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lrc != widget.lrc) {
      init();
    }
    if (oldWidget.position != widget.position) {
      updatePosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          onPointerMove: (_) {
            positionLineTimer?.cancel();
            var index = (_controller.offset / 50).floor();
            if (!isShowPositionLine || showRangeBlock || index != hoverIndex) {
              isShowPositionLine = true;
              showRangeBlock = false;
              hoverIndex = min(index, mainLrcs.length - 1);
              setState(() {});
            }
          },
          onPointerUp: (_) async {
            await _controller.animateTo(
              hoverIndex * 50 + 25,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            );
            if (mounted) {
              showRangeBlock = true;
              setState(() {});
              positionLineTimer?.cancel();
              positionLineTimer = Timer(const Duration(seconds: 2), () {
                if (mounted) {
                  isShowPositionLine = false;
                  showRangeBlock = false;
                  setState(() {});
                }
              });
            }
          },
          child: ListView.builder(
            key: scrollKey,
            itemCount: mainLrcs.length,
            controller: _controller,
            padding: EdgeInsets.symmetric(vertical: height / 2),
            itemBuilder: (_, index) {
              var mainlrc = mainLrcs[index];
              var tranlrc = translateLrcs[mainlrc.time];
              return SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: Text(
                        mainlrc.content,
                        style: TextStyle(
                          color: current == index
                              ? widget.color
                              : widget.color.withValues(alpha: .6),
                          fontSize: 28.w,
                        ),
                      ),
                    ),
                    if (tranlrc != null)
                      FittedBox(
                        child: Text(
                          tranlrc,
                          style: TextStyle(
                            color: current == index
                                ? widget.color
                                : widget.color.withValues(alpha: .6),
                            fontSize: 26.w,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: height / 2 - 22,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isShowPositionLine
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: showRangeBlock
                          ? widget.color.withValues(alpha: .1)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    height: 44,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            Duration(
                              seconds: mainLrcs[hoverIndex].time.toInt(),
                            ).toString().split('.').first,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1.5, color: widget.color),
                        ),
                        IconButton(
                          onPressed: () {
                            isShowPositionLine = false;
                            showRangeBlock = false;
                            setState(() {});
                            widget.onPositionChanged(
                              Duration(
                                seconds: mainLrcs[hoverIndex].time.toInt(),
                              ),
                            );
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.play,
                            color: widget.color,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
