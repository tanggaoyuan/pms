import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BiliPage extends StatefulWidget {
  const BiliPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AliyunPageState();
  }

  static String path = '/platform/bili';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const BiliPage();
    },
    transition: Transition.rightToLeft,
  );
}

class _AliyunPageState extends State<BiliPage> {
  late WebViewController _webViewController;
  Timer? timeref;
  final WebviewCookieManager cookieManager = WebviewCookieManager();

  void check() {
    timeref?.cancel();

    timeref = Timer.periodic(const Duration(seconds: 1), (timer) async {
      var cookies = await cookieManager.getCookies('https://www.bilibili.com/');

      var cookie = '';
      for (var ck in cookies) {
        cookie += '${ck.name}=${ck.value};';
      }
      var map = Tool.parseCookie(cookie);

      var biliJct = map['bili_jct'];

      var store = await _webViewController.runJavaScriptReturningResult(
        "JSON.stringify(localStorage)",
      );

      if (store is String) {
        var json = jsonDecode(jsonDecode(store));

        var acTimeValue = json['ac_time_value'];
        if (biliJct is String &&
            biliJct.isNotEmpty &&
            acTimeValue is String &&
            acTimeValue.isNotEmpty) {
          timer.cancel();
          await UserDbModel.createBiliUser(acTimeValue, cookie);
          _webViewController.clearLocalStorage();
          await cookieManager.clearCookies();
          Get.back();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.loadRequest(Uri.parse('https://www.bilibili.com/'));
    _webViewController.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    );
    _webViewController.enableZoom(false);
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) async {
          String javascript = '''
              var style = document.createElement('style');
              style.textContent = `
                .bili-mini-content-wp {
                    position: absolute !important;
                    top: 0 !important;
                    width: 110vw !important;
                    height: 100vh !important;
                    padding: 0 !important;
                    margin: 0 !important;
                    padding-top:2vh !important;
                    right: 125vw !important;
                       transform: scale(2.5) !important;
                      transform-origin: 0 0 !important;
                           overflow: hidden !important;
                }
              `;
              
              document.head.appendChild(style);

              var loginElement = document.querySelector('.go-login-btn');
              if (loginElement) {
                  loginElement.click();
              } else {
                  console.log('Login element not found');
              }
          
          ''';
          await _webViewController.runJavaScript(javascript);

          check();
        },
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
  }

  @override
  void dispose() {
    super.dispose();
    timeref?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('哔哩哔哩'.tr)),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
