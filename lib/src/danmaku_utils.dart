import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_track.dart';
import 'package:flutter/rendering.dart';

class DanmakuUtils {
  // 计算文字尺寸
  static Size getDanmakuBulletSizeByText(String text) {
    const constraints = BoxConstraints(
      maxWidth: 999.0, // maxwidth calculated
      minHeight: 0.0,
      minWidth: 0.0,
    );
    RenderParagraph renderParagraph = RenderParagraph(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: DanmakuConfig.bulletLabelSize,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    renderParagraph.layout(constraints);
    double textwidth = renderParagraph
        .getMinIntrinsicWidth(DanmakuConfig.bulletLabelSize)
        .ceilToDouble();
    double textheight =
        renderParagraph.getMinIntrinsicHeight(999).ceilToDouble();
    return Size(textwidth, textheight);
  }

  // 根据文字长度计算每一帧需要run多少距离
  static double getBulletEveryFramerateRunDistance(double bulletWidth) {
    assert(bulletWidth > 0);
    return DanmakuConfig.baseRunDistance +
        (bulletWidth / DanmakuConfig.everyFrameRateRunDistanceScale);
  }

  // 算轨道相对可用区域是否溢出
  static bool isEnableTrackOverflowArea(DanmakuTrack track) =>
      track.offsetTop + track.trackHeight > DanmakuConfig.showAreaHeight;

  // 轨道注入子弹是否会碰撞
  static bool trackInsertBulletHasBump(
      DanmakuBulletModel trackLastBullet, Size needInsertBulletSize,
      {int? offsetMS = 0}) {
    // 是否离开了右边的墙壁
    if (!trackLastBullet.allOutRight) return true;
    double willInsertBulletEveryFramerateRunDistance =
        DanmakuUtils.getBulletEveryFramerateRunDistance(
            needInsertBulletSize.width);
    bool hasInsertOffsetSpace = true;
    double willInsertBulletRunDistance = offsetMS == null
        ? 0
        : (offsetMS / DanmakuConfig.unitTimer) *
            willInsertBulletEveryFramerateRunDistance;
    hasInsertOffsetSpace = hasInsertOffsetSpaceComputed(
        trackLastBullet, willInsertBulletRunDistance);
    if (!hasInsertOffsetSpace) return true;
    // 要注入的节点速度比上一个快
    if (willInsertBulletEveryFramerateRunDistance >
        trackLastBullet.everyFrameRunDistance) {
      // 是否会追尾
      // 将要注入的弹幕全部离开减去上一个弹幕宽度需要的时间
      double willInsertBulletLeaveScreenRemainderTime =
          remainderTimeLeaveScreen(willInsertBulletRunDistance, 0,
              willInsertBulletEveryFramerateRunDistance);
      return trackLastBullet.leaveScreenRemainderTime >
          willInsertBulletLeaveScreenRemainderTime;
    } else {
      return false;
    }
  }

  // 偏移子弹是否有空间能插入
  static hasInsertOffsetSpaceComputed(
      DanmakuBulletModel trackLastBullet, double willInsertBulletRunDistance) {
    return (trackLastBullet.runDistance - trackLastBullet.bulletSize.width) >
        willInsertBulletRunDistance;
  }

  // 子弹剩余多少帧离开屏幕
  static double remainderTimeLeaveScreen(
      double runDistance, double textWidth, double everyFramerateDistance) {
    assert(runDistance >= 0);
    assert(textWidth >= 0);
    assert(everyFramerateDistance > 0);
    double remanderDistance =
        (DanmakuConfig.areaSize.width + textWidth) - runDistance;
    return remanderDistance / everyFramerateDistance;
  }
}
