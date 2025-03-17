import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TaskPageState();
  }

  static String path = '/task';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const TaskPage();
    },
    transition: Transition.rightToLeft,
  );
}

class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;

  final List<String> tabs = ['下载'.tr, '上传'.tr, '转码'.tr];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: tabs.length, vsync: this);

    var taskController = Get.find<TaskController>();

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (_tabController.index == 0 && taskController.downloads.isNotEmpty) {
        taskController.downloads.refresh();
      }
      if (_tabController.index == 1 && taskController.uploads.isNotEmpty) {
        taskController.uploads.refresh();
      }
      if (_tabController.index == 2 && taskController.formats.isNotEmpty) {
        taskController.formats.refresh();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('任务队列'.tr),
        bottom: TabBar(
          tabs: tabs.map((text) {
            return Tab(text: text);
          }).toList(),
          dividerColor: Colors.white,
          controller: _tabController,
          onTap: (index) {
            _pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.bounceIn);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) {
            _tabController.animateTo(page);
          },
          itemBuilder: (_, tab) {
            return Obx(() {
              var taskController = Get.find<TaskController>();
              var list = [
                taskController.downloads,
                taskController.uploads,
                taskController.formats
              ][tab];
              var mediaMaps = taskController.mediaMaps;

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, index) {
                  var task = list[index];
                  var media = mediaMaps[task.mediaId]!;
                  return Container(
                    padding: EdgeInsets.all(10.w),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 80.w,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 76.w),
                          child: FractionallySizedBox(
                            widthFactor: task.progress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Get.theme.primaryColor
                                    .withValues(alpha: .05),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10.w),
                                  bottomRight: Radius.circular(10.w),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            children: [
                              ImgComp(
                                source: media.cover,
                                cacheKey: media.cacheKey,
                                width: 80.w,
                                fit: BoxFit.cover,
                                radius: 10.w,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      media.name,
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Opacity(
                                        opacity: 0.7,
                                        child: Text(
                                          task.remark,
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                '${task.progress}%',
                                style: TextStyle(fontSize: 20.w),
                              ),
                              SizedBox(width: 10.w),
                              IconButton(
                                onPressed: () {
                                  if (task.status == MediaTaskStatus.pending) {
                                    taskController.pauseTask(task);
                                  } else {
                                    taskController.startTask(task);
                                  }
                                  list.refresh();
                                },
                                icon: [
                                  MediaTaskStatus.pending,
                                  MediaTaskStatus.wait
                                ].contains(task.status)
                                    ? Opacity(
                                        opacity:
                                            task.status == MediaTaskStatus.wait
                                                ? 0.5
                                                : 1,
                                        child: FaIcon(
                                          FontAwesomeIcons.pause,
                                          size: 34.w,
                                        ),
                                      )
                                    : FaIcon(
                                        FontAwesomeIcons.play,
                                        size: 34.w,
                                      ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Tool.showConfirm(
                                    title: '删除'.tr,
                                    content: '${'是否删除'.tr}（${media.name}）',
                                    onConfirm: () async {
                                      await taskController.removeTask(task);
                                      list.refresh();
                                    },
                                  );
                                },
                                icon: Opacity(
                                  opacity: 0.3,
                                  child: FaIcon(
                                    FontAwesomeIcons.xmark,
                                    size: 30.w,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}
