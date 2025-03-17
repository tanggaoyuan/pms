import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/tool.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class UserOperation extends StatefulWidget {
  final MediaTagType type;
  final Function(List<AlbumDbModel> value, UserDbModel user) onSave;

  /// 导入专辑弹窗
  const UserOperation({super.key, required this.onSave, required this.type});

  @override
  State<StatefulWidget> createState() {
    return _UserOperationState();
  }
}

class _UserOperationState extends State<UserOperation>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late RefreshController _refreshController;

  late List<Map<String, dynamic>> tabs = [];

  late List<UserDbModel> users = [];

  UserDbModel? user;
  late String nextMarker = 'init';
  late int favTotal = -1;
  late int subTotal = -1;

  late Map<String, AlbumDbModel> selects = {};
  late List<AlbumDbModel> albums = [];
  late List<String> paths = ['root'];

  @override
  void initState() {
    super.initState();

    var items = [
      {
        "name": '阿里云盘'.tr,
        "icon": ImgCompIcons.aliyun,
        "link": '/aliyun',
        "type": MediaPlatformType.aliyun,
      },
      {
        "name": '哔哩哔哩'.tr,
        "icon": ImgCompIcons.bili,
        "link": '/bili',
        "type": MediaPlatformType.bili,
      },
    ];

    if (widget.type == MediaTagType.muisc) {
      items.add({
        "name": '网易云音乐'.tr,
        "icon": ImgCompIcons.netease,
        "link": '/wanyi',
        "type": MediaPlatformType.netease,
      });
    }
    tabs = items;

    _tabController = TabController(length: tabs.length, vsync: this);
    _refreshController = RefreshController();
    _pageController = PageController();

    setState(() {});

    init();
  }

  @override
  dispose() {
    super.dispose();
    _refreshController.dispose();
    _pageController.dispose();
    _tabController.dispose();
  }

  init() async {
    users = await UserDbModel.users();
    setState(() {});
  }

  fetchAilyun() async {
    var user = this.user;

    if (user == null) {
      return;
    }

    await user.updateToken();

    var response =
        await AliyunApi.search(
          driveId: user.extra.driveId,
          xDeviceId: user.extra.xDeviceId,
          token: user.accessToken,
          xSignature: user.extra.xSignature,
          parentFileIds: [paths.last],
          type: 'folder',
          limit: 20,
          marker:
              (nextMarker.isEmpty || nextMarker == 'init') ? null : nextMarker,
        ).getData();

    var items =
        response.items.where((item) => item.isFolder).map((item) {
          return AlbumDbModel.fromAliFie(user, item, widget.type);
        }).toList();

    if (nextMarker == 'init') {
      albums = items;
    } else {
      albums.addAll(items);
    }

    if (nextMarker == 'init') {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.loadComplete();
    }

    nextMarker = response.nextMarker;
    setState(() {});

    if (nextMarker.isEmpty) {
      _refreshController.loadNoData();
    }
  }

  fetchNetease() async {
    var response =
        await NeteaseApi.getPlaylist(
          cookie: user!.accessToken,
          userId: user!.relationId,
        ).getData();
    var items =
        response.map((item) {
          return AlbumDbModel.fromNetease(user!, item);
        }).toList();

    albums = [
      AlbumDbModel(
        name: '${user!.name}${'的云盘'.tr}',
        cover: user!.cover,
        platform: MediaPlatformType.netease,
        relationId: '${user!.id}_cloud',
        userId: user!.id,
        relationUserId: user!.relationId,
        type: widget.type,
        isSelf: 1,
      ),
      ...items,
    ];

    setState(() {});
    _refreshController.refreshCompleted();
    _refreshController.loadNoData();
  }

  fetchBili() async {
    await user!.updateToken();

    if (favTotal == -1 || favTotal > albums.length) {
      var fav =
          await BiliApi.getFavFolder(
            userId: user!.relationId,
            cookie: user!.accessToken,
            limit: 40,
            page: favTotal == -1 ? 1 : (albums.length / 40).ceil() + 1,
          ).getData();
      var items =
          fav.albums
              .map((item) => AlbumDbModel.fromBili(user!, item, widget.type))
              .toList();
      if (favTotal == -1) {
        albums = items;
      } else {
        albums.addAll(items);
      }
      favTotal = fav.total;
    }

    if (albums.length >= favTotal) {
      var sub =
          await BiliApi.getSubFolder(
            userId: user!.relationId,
            cookie: user!.accessToken,
            limit: 40,
            page: ((albums.length - favTotal) / 40).ceil() + 1,
          ).getData();
      var items =
          sub.albums
              .map((item) => AlbumDbModel.fromBili(user!, item, widget.type))
              .toList();
      albums.addAll(items);
      subTotal = sub.total;
    }

    setState(() {});

    _refreshController.refreshCompleted();
    if (subTotal + favTotal == albums.length) {
      _refreshController.loadNoData();
    } else {
      _refreshController.loadComplete();
    }
  }

  handleRefresh() async {
    if (user!.isAliyunPlatform) {
      nextMarker = 'init';
      await fetchAilyun();
    }

    if (user!.isNeteasePlatform) {
      await fetchNetease();
    }

    if (user!.isBiliPlatform) {
      favTotal = -1;
      subTotal = -1;
      await fetchBili();
    }
  }

  handleLoading() async {
    if (user!.isAliyunPlatform) {
      await fetchAilyun();
    }
    if (user!.isNeteasePlatform) {
      await fetchNetease();
    }
    if (user!.isBiliPlatform) {
      await fetchBili();
    }
  }

  Widget renderUserItem({
    required String img,
    required String title,
    void Function()? onTap,
    void Function()? onLogout,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        margin: EdgeInsets.symmetric(vertical: 10.w),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.w),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: .5),
                    spreadRadius: 1.w,
                    blurRadius: 2.w,
                    offset: Offset(0, 1.w), // changes position of shadow
                  ),
                ],
              ),
              child: ImgComp(source: img, width: 80.w, radius: 10.w),
            ),
            SizedBox(width: 30.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 30.sp),
                softWrap: true,
              ),
            ),
            if (onLogout != null)
              AbsorbPointer(
                absorbing: false,
                child: Container(
                  height: 40.w,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 10.w),
                      ),
                      minimumSize: const WidgetStatePropertyAll(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onLogout,
                    child: Text('退出'.tr, style: TextStyle(fontSize: 22.sp)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget renderAlbumItem({
    void Function()? onTap,
    void Function(bool? value)? onChanged,
    required bool check,
    required String cover,
    required String title,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          ImgComp(source: cover, width: 90.w, fit: BoxFit.cover, radius: 8.w),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              softWrap: true,
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
          AbsorbPointer(
            absorbing: false,
            child: Checkbox(value: check, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  List<Widget> renderUserPage() {
    if (user == null) {
      return [
        TabBar(
          controller: _tabController,
          tabs:
              tabs.map((value) {
                return Tab(text: value['name']);
              }).toList(),
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 600),
              curve: Curves.ease,
            );
          },
        ),
        SizedBox(height: 20.w),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            itemBuilder: (_, index) {
              var map = tabs[index];
              var list =
                  users.where((item) => item.platform == map['type']).toList();
              return ListView.builder(
                itemCount: list.length + 1,
                itemBuilder: (_, index) {
                  if (index == list.length) {
                    return renderUserItem(
                      title: '${'登录'.tr}${map['name']}',
                      img: map['icon'],
                      onTap: () async {
                        try {
                          if (map['type'] == MediaPlatformType.aliyun) {
                            await AliyunPage.to();
                          }

                          if (map['type'] == MediaPlatformType.netease) {
                            await NeteasePage.to();
                          }

                          if (map['type'] == MediaPlatformType.bili) {
                            await BiliPage.to();
                          }

                          EasyLoading.show(
                            status: "加载用户数据中...".tr,
                            maskType: EasyLoadingMaskType.black,
                          );

                          await init();
                          EasyLoading.dismiss();
                        } catch (e) {
                          EasyLoading.dismiss();
                          EasyLoading.showToast(e.toString());
                        }
                      },
                    );
                  }
                  var info = list[index];
                  return renderUserItem(
                    title: info.name,
                    img: info.cover,
                    onTap: () {
                      user = info;
                      setState(() {});
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        _refreshController.requestRefresh();
                      });
                    },
                    onLogout: () async {
                      Tool.showConfirm(
                        title: '退出账号'.tr,
                        content: '退出账号会导致部分数据无法获取'.tr,
                        onConfirm: () async {
                          if (info.isBiliPlatform) {
                            await BiliApi.logout(info.accessToken);
                          }
                          if (info.isNeteasePlatform) {
                            await NeteaseApi.logout(info.accessToken);
                          }
                          if (info.isAliyunPlatform) {
                            await AliyunApi.logout(
                              token: info.accessToken,
                              driveId: info.extra.driveId,
                              xDeviceId: info.extra.xDeviceId,
                              xSignature: info.extra.xSignature,
                              userId: info.relationId,
                            );
                          }
                          await info.remove();
                          users.remove(info);
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ];
    }

    return [];
  }

  List<Widget> renderAlbumPage() {
    if (user == null) {
      return [];
    }
    return [
      SizedBox(height: 20.w),
      Expanded(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: handleRefresh,
          onLoading: handleLoading,
          controller: _refreshController,
          child: ListView.builder(
            itemBuilder: (_, index) {
              var file = albums[index];
              return renderAlbumItem(
                cover: file.cover.isEmpty ? ImgCompIcons.aliDir : file.cover,
                check: selects[file.relationId] != null,
                onChanged: (bool? value) {
                  if (value == true) {
                    selects[file.relationId] = file;
                  } else {
                    selects.remove(file.relationId);
                  }
                  setState(() {});
                },
                title: file.name,
                onTap: () {
                  if (file.isAliyunPlatform) {
                    paths.add(file.relationId);
                    _refreshController.requestRefresh();
                  }
                },
              );
            },
            itemExtent: 100.w,
            itemCount: albums.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> renderAction() {
    var user = this.user;

    if (user == null) {
      return [];
    }

    return [
      if (user.isAliyunPlatform)
        IconButton(
          onPressed: () {
            Tool.showBottomSheet(
              AlbumOperationComp(
                onSave: (value) async {
                  await user.updateToken();

                  var file =
                      await AliyunApi.createDir(
                        driveId: user.extra.driveId,
                        xDeviceId: user.extra.xDeviceId,
                        token: user.accessToken,
                        xSignature: user.extra.xSignature,
                        name: value,
                      ).getData();

                  albums.insert(
                    0,
                    AlbumDbModel.fromAliFie(user, file, widget.type),
                  );
                  setState(() {});

                  Get.back();
                },
              ),
            );
          },
          icon: const FaIcon(FontAwesomeIcons.plus),
        ),
      IconButton(
        onPressed: () {
          if (selects.isEmpty) {
            EasyLoading.showToast('请选择'.tr);
            return;
          }
          widget.onSave(selects.values.toList(), user);
          Get.back();
        },
        icon: const FaIcon(FontAwesomeIcons.check),
      ),
    ];
  }

  back() {
    if (user == null) {
      Get.back();
      return;
    }

    if (paths.length > 1) {
      paths.removeLast();
      _refreshController.requestRefresh();
      return;
    }

    if (user != null) {
      albums = [];
      setState(() {
        user = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(_tabController.index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        back();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(30.w),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: back,
                  icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 36.w),
                ),
                Expanded(
                  child: Text('导入专辑'.tr, style: TextStyle(fontSize: 32.w)),
                ),
                ...renderAction(),
              ],
            ),
            ...renderUserPage(),
            ...renderAlbumPage(),
          ],
        ),
      ),
    );
  }
}
