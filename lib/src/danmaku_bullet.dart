// 弹幕子弹
import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_track.dart';
import 'package:danmaku/src/danmaku_utils.dart';
import 'package:flutter/material.dart';

enum DanmakuBulletType { scroll, fixed }

enum DanmakuBulletPosition { any, bottom }

class DanmakuBulletModel {
  late UniqueKey id;
  late UniqueKey trackId;
  UniqueKey? prevBulletId;
  late Size bulletSize;
  late String text;
  late double offsetY;
  late double _runDistance = 0;
  late double everyFrameRunDistance;
  Color color = Colors.black;
  DanmakuBulletPosition position = DanmakuBulletPosition.any;

  Widget Function(Text)? builder;

  DanmakuBulletType bulletType;

  /// 子弹的x轴位置
  double get offsetX => bulletType == DanmakuBulletType.scroll
      ? _runDistance - bulletSize.width
      : DanmakuConfig.areaSize.width / 2 - (bulletSize.width / 2);

  /// 子弹最大可跑距离 子弹宽度+墙宽度
  double get maxRunDistance =>
      bulletSize.width + DanmakuConfig.areaSize.width;

  /// 子弹整体脱离右边墙壁
  bool get allOutRight => _runDistance > bulletSize.width;

  /// 子弹整体离开屏幕
  bool get allOutLeave => _runDistance > maxRunDistance;

  /// 子弹当前执行的距离
  double get runDistance => _runDistance;

  /// 剩余离开的距离
  double get remanderDistance => needRunDistace - runDistance;

  /// 需要走的距离
  double get needRunDistace =>
      DanmakuConfig.areaSize.width + bulletSize.width;

  /// 离开屏幕剩余需要的时间
  double get leaveScreenRemainderTime =>
      remanderDistance / everyFrameRunDistance;

  /// 子弹执行下一帧
  void runNextFrame() {
    _runDistance += everyFrameRunDistance * DanmakuConfig.bulletRate;
  }

  // 重新绑定轨道
  void rebindTrack(DanmakuTrack track) {
    offsetY = track.offsetTop;
    trackId = track.id;
  }

  // 计算文字尺寸
  void completeSize() {
    bulletSize = DanmakuUtils.getDanmakuBulletSizeByText(text);
  }

  DanmakuBulletModel({
    required this.id,
    required this.trackId,
    required this.text,
    required this.bulletSize,
    required this.offsetY,
    this.bulletType = DanmakuBulletType.scroll,
    required this.color,
    this.prevBulletId,
    this.builder,
    required this.position,
    int? offsetMS,
  }) {
    everyFrameRunDistance =
        DanmakuUtils.getBulletEveryFramerateRunDistance(
            bulletSize.width);
    _runDistance = offsetMS != null
        ? (offsetMS / DanmakuConfig.unitTimer) * everyFrameRunDistance
        : 0;
  }
}

class DanmakuBullet extends StatelessWidget {
  const DanmakuBullet(
      {Key? key,
      required this.danmakuId,
      required this.text,
      this.color = Colors.black,
      this.builder})
      : super(key: key);
  final String text;
  final UniqueKey danmakuId;
  final Color color;

  final Widget Function(Text)? builder;

  /// 构建文字
  Widget buildText() {
    Text textWidget = Text(
      text,
      style: TextStyle(
        fontSize: DanmakuConfig.bulletLabelSize,
        color: color.withOpacity(DanmakuConfig.opacity),
      ),
    );
    if (builder != null) {
      return builder!(textWidget);
    }
    return textWidget;
  }

  /// 构建描边文字
  Widget buildStrokeText() {
    Text textWidget = Text(
      text,
      style: TextStyle(
        fontSize: DanmakuConfig.bulletLabelSize,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.black.withOpacity(DanmakuConfig.opacity),
      ),
    );
    if (builder != null) {
      return builder!(textWidget);
    }
    return textWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Stroked text as border.
        buildStrokeText(),
        // Solid text as fill.
        buildText()
      ],
    );
  }
}
