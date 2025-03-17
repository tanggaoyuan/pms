import 'package:get/get.dart';
import 'package:pms/db/export.dart';

class HomeController extends GetxController {
  RxList<AlbumDbModel> musicAlbums = RxList<AlbumDbModel>();
  RxList<AlbumDbModel> videoAlbums = RxList<AlbumDbModel>();

  initMuiceAlbums() async {
    musicAlbums.value = await AlbumDbModel.albums(MediaTagType.muisc);
  }

  initVideoAlbums() async {
    videoAlbums.value = await AlbumDbModel.albums(MediaTagType.video);
  }

  @override
  void onInit() {
    super.onInit();
    initMuiceAlbums();
    initVideoAlbums();
  }
}

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController(), permanent: true);
  }
}
