import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MusicProgressBarComp extends StatefulWidget {
  final Function(Duration time) onChange;
  final Duration current;
  final Duration duration;

  const MusicProgressBarComp({
    super.key,
    required this.onChange,
    required this.current,
    required this.duration,
  });

  @override
  State<MusicProgressBarComp> createState() => _MusicProgressBarState();
}

class _MusicProgressBarState extends State<MusicProgressBarComp> {
  final GlobalKey globalKey = GlobalKey();
  Duration _current = Duration.zero;
  bool _drag = false;

  void stopDrag() {
    widget.onChange(_current);
    setState(() {
      _drag = false;
    });
  }

  void dragProgress(double x) {
    var width = globalKey.currentContext?.size?.width;
    if (width != null) {
      double rb = x / width;
      rb = rb > 1 ? 1 : (rb < 0 ? 0 : rb);
      int time = (rb * widget.duration.inMilliseconds).toInt();
      setState(() {
        _current = Duration(milliseconds: time);
        _drag = true;
      });
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    Duration position = (_drag ? _current : widget.current);
    double widthFactor =
        position.inMilliseconds / widget.duration.inMilliseconds;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 34.w),
      child: Column(
        children: [
          GestureDetector(
            key: globalKey,
            onHorizontalDragDown: (e) {
              dragProgress(e.localPosition.dx);
            },
            onHorizontalDragUpdate: (e) {
              dragProgress(e.localPosition.dx);
            },
            onHorizontalDragEnd: (_) {
              stopDrag();
            },
            onHorizontalDragCancel: stopDrag,
            child: Container(
              height: 30.w,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Stack(
                fit: StackFit.loose,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 5.w,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.5.w)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -6.w,
                    height: 16.w,
                    child: Row(
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            widthFactor: widthFactor.isNaN
                                ? 0.001
                                : (widthFactor > 1 ? 1 : widthFactor),
                            child: Container(
                              height: 5.w,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2.5.w)),
                            ),
                          ),
                        ),
                        Container(
                          height: 16.w,
                          width: 16.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(position),
                style: TextStyle(
                    fontSize: 22.sp, color: Colors.white.withValues(alpha: .8)),
              ),
              Text(
                formatDuration(widget.duration),
                style: TextStyle(
                    fontSize: 22.sp, color: Colors.white.withValues(alpha: .8)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
