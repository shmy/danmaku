import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_utils.dart';
import 'package:flutter/material.dart';

class DanmakuConfig {
  // 帧率
  static int frameRate = 60;

  // 单位帧率所需要的时间
  static int unitTimer = 1000 ~/ DanmakuConfig.frameRate;

  static double bulletLabelSize = 16;

  static double bulletRate = 1.0;

  static Function(DanmakuBulletModel)? bulletTapCallBack;

  static Size areaSize = const Size(0, 0);

  // 展示区域百分比
  static double showAreaPercent = 1.0;

  static double opacity = 1.0;

  static bool pause = false;

  static int baseRunDistance = 1;

  static int everyFrameRateRunDistanceScale = 150;

  /// 弹幕场景基于子组件高度的偏移量。是由于子组件高度不一定能整除轨道高度 为了居中展示 需要有一个偏移量
  static double areaOfChildOffsetY = 0;

  // 展示高度
  static double get showAreaHeight =>
      DanmakuConfig.areaSize.height * DanmakuConfig.showAreaPercent;

  /// 获取弹幕场景基于子组件高度的偏移量。为了居中展示
  static double getAreaOfChildOffsetY({Size? textSize}) {
    Size newTextSize = textSize ?? DanmakuUtils.getDanmakuBulletSizeByText('s');

    return (DanmakuConfig.areaSize.height % newTextSize.height) / 2;
  }
}
