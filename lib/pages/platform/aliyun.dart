import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pms/db/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AliyunPage extends StatefulWidget {
  const AliyunPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AliyunPageState();
  }

  static String path = '/platform/aliyun';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const AliyunPage();
    },
    transition: Transition.rightToLeft,
  );
}

class _AliyunPageState extends State<AliyunPage> {
  late WebViewController _webViewController;
  Timer? timeref;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.loadRequest(Uri.parse('https://www.alipan.com/sign/in'));
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
      var result = await _webViewController.runJavaScriptReturningResult(
        "JSON.stringify({...window.Global,...JSON.parse(window.localStorage.getItem('token'))})",
      );

      if (result is String) {
        var json = jsonDecode(jsonDecode(result));

        var refreshToken = json['refresh_token'];
        var appId = json['app_id'];

        if (refreshToken is String && appId is String) {
          timeref?.cancel();
          await UserDbModel.createAliyunUser(json);
          Get.back();
        }
      }
    });
  }

  @override
  void dispose() {
    _webViewController.runJavaScript('localStorage.removeItem("token")');
    super.dispose();
    timeref?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('阿里云'.tr)),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
