## 声明

该项目仅供学习使用，不提供任何安装包，开源协议 GPLv2

## 功能

支持 iOS、Android，提供哔哩哔哩、网易云、阿里云盘音视频资源的导入与下载，集成网易云盘与阿里云 盘上传功能，提供视频裁剪与音频提取能力，支持在线播放、歌词同步匹配、后台播放通知、定时关闭播 放，并支持多语言和主题色切换。

## 运行

- 请使用 fvm 运行该项目,版本限制 3.6.0 到 3.6.2，3.7.0 以上模拟器模糊效果会造成闪退
- 由于 ffmpeg-kit 停止维护了，这里使用了两个其他修复源，请根据运行环境修改 pubspec.yaml

## 效果

<img src="static/1.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/2.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/3.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/4.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/5.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/6.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/7.png" alt="preview" style="zoom: 50%;" width='300px' />
<img src="static/8.png" alt="preview" style="zoom: 50%;" width='300px' />

## 使用的相关库

- 统一修改 app 图标 [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)

- 闪屏页 [flutter_native_splash](https://pub-web.flutter-io.cn/packages/flutter_native_splash)

- 组件全局状态、路由、主题色、多语言管理 [getx](https://pub-web.flutter-io.cn/packages/get)

- 设计稿适配 [flutter_screenutil](https://pub-web.flutter-io.cn/packages/flutter_screenutil)

- toast [flutter_easyloading ](https://pub-web.flutter-io.cn/packages/flutter_easyloading)

- 应用储存路径获取 [path_provider](https://pub-web.flutter-io.cn/packages/path_provider)

- 内嵌页面 [webview_flutter](https://pub-web.flutter-io.cn/packages/webview_flutter)

- 页面 cookie 管理 [webview_cookie_manager_plus](https://pub-web.flutter-io.cn/packages/webview_cookie_manager_plus)

- unicode 编码转正常字符 [string_normalizer](https://pub-web.flutter-io.cn/packages/string_normalizer)

- 处理文件名的特殊字符 [sanitize_filename](https://pub-web.flutter-io.cn/packages/sanitize_filename)

- 请求工具 [dio](https://pub-web.flutter-io.cn/packages/dio)

- 数据库 [sqflite](https://pub-web.flutter-io.cn/packages/sqflite)

- json 类储存 [hive](https://pub-web.flutter-io.cn/packages/hive)

- 日志工具 [logger](https://pub-web.flutter-io.cn/packages/logger)

- 列表组件 [pull_to_refresh](https://pub-web.flutter-io.cn/packages/pull_to_refresh)

- 图片缓存 [cached_network_image](https://pub-web.flutter-io.cn/packages/cached_network_image)

- 播放进度 [audio_video_progress_bar](https://pub-web.flutter-io.cn/packages/audio_video_progress_bar)

- 图标库 [font_awesome_flutter](https://pub-web.flutter-io.cn/packages/font_awesome_flutter)

- 媒体播放器 [media_player_plugin](https://pub-web.flutter-io.cn/packages/media_player_plugin)
