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
        var json = jsonDecode(store);

        if(json is String){
          json = jsonDecode(json);
        }

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
    _webViewController.loadRequest(
      Uri.parse(
        'https://www.bilibili.com?key=${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
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
              var style = document.createElement("style");
        style.textContent = `
            #i_cecream {
                width: 100vw;
                height: 100vh;
                overflow: hidden;
                visibility: hidden;
            }
            .bili-mini-mask {
                visibility: hidden;
            }
            .bili-mini-login-right-wp {
                font-size: 5.3vw; 
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: white;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                visibility: visible;
            }
            .login-tab-item {
                font-size: 5.3vw !important; 
                margin-bottom: 2.67vw !important; 
            }
            .tab__form {
                font-size: 4vw !important; 
            }
            .login-tab-wp, .login-pwd-wp, .btn_wp {
                width: 80vw !important;
                height: auto !important;
            }
            .tab__form {
                width: 100vw;
                height: auto !important;
            }
            .form__item {
                height: 11vw !important; 
            }
            .form__item input {
                font-size: 4vw !important; 
            }
            .btn_primary {
                height: 11vw !important; 
                font-size: 4vw !important; 
                flex: 1;
                line-height: 11vw !important;
            }
            .login-sns-wp, .btn_other {
                display: none;
            }
            .geetest_wind.geetest_panel .geetest_panel_box.geetest_panelshowclick {
                width: 60vw !important;
                height: 60vh !important;
                margin-left: -30vw !important;
                margin-top: -30vh !important;
            }
        `;

            var loginElement = document.querySelector(".go-login-btn");
            if (loginElement) {
                loginElement.click();
               document.head.appendChild(style);
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
    cookieManager.clearCookies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('哔哩哔哩'.tr)),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
