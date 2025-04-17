import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pms/db/user.dart';
import 'package:pms/utils/export.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NeteasePage extends StatefulWidget {
  const NeteasePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NeteasePageState();
  }

  static String path = '/platform/netease';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const NeteasePage();
    },
    transition: Transition.rightToLeft,
  );
}

class _NeteasePageState extends State<NeteasePage> {
  late WebViewController _webViewController;
  final WebviewCookieManager cookieManager = WebviewCookieManager();
  Timer? timeref;
  var isClean = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.loadRequest(
      Uri.parse('https://y.music.163.com/m/login'),
    );
    // _webViewController.setUserAgent(
    //   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    // );
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          // if (request.url.contains('create_session')) {
          //   return NavigationDecision.prevent;
          // }
          return NavigationDecision.navigate;
        },
      ),
    );

    timeref?.cancel();

    timeref = Timer.periodic(const Duration(seconds: 1), (timer) async {
      var cookies = await cookieManager.getCookies('https://y.music.163.com/');
      var cookie = '';
      for (var ck in cookies) {
        cookie += '${ck.name}=${ck.value};';
      }
      var map = Tool.parseCookie(cookie);
      var csrf = map['__csrf'];
      if (csrf is String && csrf.isNotEmpty) {
        timeref?.cancel();
        await UserDbModel.createNeteaseUser(cookie);
        isClean = true;
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (isClean) {
      cookieManager.clearCookies();
    }
    timeref?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('网易云'.tr)),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
