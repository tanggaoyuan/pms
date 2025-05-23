import 'package:pms/common/lang/comLang.dart';

Map<String, String> enUS = {
  '音乐': 'Music',
  '设置': 'Settings',
  '主题色': 'Theme Color',
  '语言': 'Language',
  '视频': 'Video',
  '相册': 'Album',
  '本地音乐': 'Local Music',
  '导入专辑': 'Import Album',
  '分享': 'Share',
  '是否删除': 'Whether to delete',
  '删除': 'Delete',
  '条': 'Item',
  '创建专辑': 'Create Album',
  '请输入': 'Please enter',
  '专辑名称': 'Album Name',
  '确定': 'OK',
  '添加到专辑': 'Add to Album',
  '图片加载失败': 'Image Loading Failed',
  '修改信息': 'Modify Information',
  '媒体名称': 'Media Name',
  '艺人': 'Artist',
  '取消': 'Cancel',
  '播放列表': 'Playlist',
  '歌词匹配': 'Lyric Matching',
  '歌词关键字': 'Lyric Keywords',
  '搜索': 'Search',
  '设置歌词中...': 'Setting lyrics...',
  '歌词不存在': 'Lyrics do not exist',
  '设置成功': 'Set successfully',
  '获取歌词异常': 'Exception in fetching lyrics',
  '阿里云盘': 'Alibaba Cloud Disk',
  '哔哩哔哩': 'bilibili',
  '网易云音乐': 'NetEase Cloud Music',
  '的云盘': 'Cloud Disk of',
  '退出': 'Exit',
  '登录': 'Login',
  '退出账号': 'Logout',
  '退出账号会导致部分数据无法获取': 'Logging out will cause some data to be unavailable',
  '请选择': 'Please select',
  '本地视频': 'Local Video',
  '加载中...': 'Loading...',
  '获取数据异常': 'Exception in fetching data',
  '正在删除': 'Deleting...',
  '删除成功': 'Deleted successfully',
  '删除任务失败': 'Failed to delete task',
  '添加中': 'Adding...',
  '已添加': 'Added',
  '添加失败': 'Failed to add',
  '添加下载任务中': 'Adding download task...',
  '已添加下载任务': 'Download task added',
  '添加下载任务失败': 'Failed to add download task',
  '生成上传任务中...': 'Generating upload task...',
  '任务已添加': 'Task added',
  '任务失败': 'Task failed',
  '加载中': 'Loading',
  '获取播放数据异常': 'Exception in fetching play data',
  '暂无数据': 'No data available',
  '已选择': 'Selected',
  '全选': 'Select All',
  '首': 'Track',
  '上传': 'Upload',
  '下载': 'Download',
  '添加歌单': 'Add Playlist',
  '匹配歌词': 'Match Lyrics',
  '添加下载任务中...': 'Adding download task...',
  '正常模式': 'Normal Mode',
  '歌曲切换模式': 'Song Switching Mode',
  '定时模式': 'Timer Mode',
  '定时-15': 'Timer - 15',
  '定时+15': 'Timer + 15',
  '单曲循环': 'Single Track Loop',
  '随机播放': 'Shuffle Play',
  '列表循环': 'List Loop',
  '保存上传文件异常': 'Exception in saving uploaded file',
  '暂停任务': 'Pause Task',
  '条数据': 'Item of data',
  '裁剪': 'Crop',
  '设置封面中': 'Setting cover...',
  '获取异常': 'Exception in fetching',
  '提取音频中...': 'Extracting audio...',
  '操作': 'Operation',
  '存在同名文件是否覆盖': 'Whether to overwrite files with the same name',
  '转码异常': 'Transcoding Exception',
  '存为音频': 'Save as Audio',
  '检测下载链接': 'Detect Download Link',
  '未检测出下载链接': 'No download link detected',
  '开始下载': 'Start Downloading',
  '视频下载': 'Video Download',
  '音频下载': 'Audio Download',
  '下载完成': 'Download Complete',
  '转码': 'Transcoding',
  '转码完成': 'Transcoding Complete',
  '数据已添加到视频库': 'Data has been added to the video library',
  '下载异常': 'Download Exception',
  '下载须知': 'Download Instructions',
  '1、请跳过广告在进行下载，防止解析到广告内容':
      '1. Please skip the advertisement before downloading to prevent parsing advertisement content',
  '2、请切换到你需要的分辨率后，再进行下载':
      '2. Please switch to the resolution you need before downloading',
  '3、下载完成后将会保存到本地视频中':
      '3. It will be saved in the local video after downloading',
  '耳机辅助功能说明': 'Headphone Auxiliary Function Description',
  '启用/关闭：': 'Enable/Disable:',
  '• 通过长按/3次点击进行切换': '• Switch by long press/three clicks',
  '辅助功能关闭情况：': 'When the auxiliary function is disabled:',
  '• 中键点击播放/暂停，双击播放下一首':
      '• Click the middle button to play/pause, double-click to play the next track',
  '• 音量键调节声音': '• Use the volume keys to adjust the volume',
  '辅助功能开启情况：': 'When the auxiliary function is enabled:',
  '• 正常模式': '• Normal Mode',
  '  - 中键点击播放/暂停，双击切换模式':
      '  - Click the middle button to play/pause, double-click to switch mode',
  '  - 音量键调节声音': '  - Use the volume keys to adjust the volume',
  '• 歌曲切换模式': '• Song Switching Mode',
  '  - 中键点击切换播放模式列表播放/单曲循环/随机播放，双击切换模式':
      '  - Click the middle button to switch the play mode (list play/single track loop/shuffle play), double-click to switch mode',
  '  - 音量键上一曲/下一曲': '  - Use the volume keys for previous/next track',
  '• 定时模式': '• Timer Mode',
  '  - 中键点击启用/关闭定时，双击切换模式':
      '  - Click the middle button to enable/disable timer, double-click to switch mode',
  '  - 音量键增加/减少时间，单位为15分钟':
      '  - Use the volume keys to increase/decrease time by 15 minutes',
  '耳机辅助功能': 'Headphone Auxiliary Function',
  '定时关闭': 'Timer Off',
  '任务队列': 'Task Queue',
  '是否删除该数据': 'Do you want to delete this data',
  '提示': 'prompt',
  '更新凭证异常，请手动退出并重新登录':
      'Update credential exception, please log out manually and log in again',
  '当前有下载任务或转码任务正在进行，请等待完成后再清理缓存':
      'There are currently download tasks or transcoding tasks in progress. Please wait for them to complete before clearing the cache.',
  '删除缓存将会导致部分列表图片无法展示，需要对列表进行刷新操作':
      'Deleting the cache will cause some list images to not be displayed, and the list needs to be refreshed.',
  '清理缓存中...': 'Clearing the cache...',
  '清理缓存成功': 'Cache cleared successfully',
  '清理缓存失败': 'Cache clearing failed',
  '计算缓存大小中...': 'Calculating cache size...',
  '清理缓存': 'Clear Cache',
  '导入中...': 'Importing...',
  '当前资源正被加载,已跳过删除':
      'The current resource is being loaded, and the deletion has been skipped.',
  '暂无播放数据': 'There is no playback data yet',
  ...comLang,
};
