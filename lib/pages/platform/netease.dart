import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pms/db/user.dart';
import 'package:pms/utils/export.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
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

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.loadRequest(Uri.parse('https://music.163.com/'));
    _webViewController.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    );
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {
          String javascript = '''
              var style = document.createElement('style');
              style.textContent = `
                  #g-topbar, #g_iframe { visibility: hidden !important; }

                  .mrc-modal-wrapper { visibility: hidden !important; }

                  div[data-log] {
                      visibility: visible !important;
                      position: fixed;
                      left: 0;
                      top:0;
                      transform: scale(2.5) !important;
                      transform-origin: 0 0 !important;
                      width: 40vw !important;
                      height: 40vh !important;
                      overflow: hidden !important;
                  }
              `;
              document.head.appendChild(style);

              var loginElement = document.querySelector('[data-action="login"]');
              if (loginElement) {
                  loginElement.click();
              } else {
                  console.log('Login element not found');
              }

              setTimeout(function () {
                  var otherLoginModeLink = Array.from(
                      document.querySelectorAll('.mrc-modal-wrapper a')
                  ).find((a) => a.textContent.trim() === '选择其他登录模式');
                  if (otherLoginModeLink) {
                      otherLoginModeLink.click();

                      setTimeout(function () {
                          var checkbox = document.querySelector('input[type="checkbox"]');
                          if (checkbox) {
                              checkbox.click();
                              console.log('Checkbox clicked');

                              setTimeout(function () {
                                  var phoneLoginLink = Array.from(document.querySelectorAll('a')).find(
                                      (a) => a.textContent.includes('手机号登录')
                                  );
                                  if (phoneLoginLink) {
                                      phoneLoginLink.click();
                                      console.log('Phone login link clicked');
                                  } else {
                                      console.log('Phone login link not found');
                                  }
                              }, 100);
                          } else {
                              console.log('Checkbox not found');
                          }
                      }, 100);

                      console.log('Other login mode link clicked');
                  } else {
                      console.log('Other login mode link not found');
                  }
              }, 100);
          ''';
          _webViewController.runJavaScript(javascript);
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

    timeref?.cancel();

    timeref = Timer.periodic(const Duration(seconds: 1), (timer) async {
      var cookies = await cookieManager.getCookies('https://music.163.com/');
      var cookie = '';
      for (var ck in cookies) {
        cookie += '${ck.name}=${ck.value};';
      }
      var map = Tool.parseCookie(cookie);
      var csrf = map['__csrf'];
      if (csrf is String && csrf.isNotEmpty) {
        timeref?.cancel();
        await UserDbModel.createNeteaseUser(cookie);
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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
