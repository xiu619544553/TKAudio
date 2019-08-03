# TKAudio

# 介绍

功能：

1. 录制wav格式语音，并将其转换为amr。amr语音体积更小，便于传输，并且iOS和Android都能很好的支持播放；

2. 长按录制按钮，有个简单的圆形动效。其中，圆形的大小与说话音量大小有关，声音越大，圆的半径越大；

3. 可以自定义录制时长的大小；

   

效果如下：

![](https://github.com/xiu619544553/TKAudio/blob/master/images/audio.gif)



## 使用

1. 将`AudioTool`拖入工程中
2. 修改Xcode配置：Build Settings > Enable Bitcode = NO
3. Build Phases > Link Binary With Libraries > 导入`AVFoundation.framework`