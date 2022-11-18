import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DanmakuRenderManager {
  Ticker? _ticker;

  void run(Function nextFrame, VoidCallback refreshState) {
    _ticker = Ticker((Duration elapsed) {
      // 暂停不执行
      if (!DanmakuConfig.pause) {
        nextFrame();
        refreshState();
      }
    });
    _ticker?.start();
  }

  void dispose() {
    _ticker?.dispose();
  }

  // 渲染下一帧
  List<DanmakuBulletModel> renderNextFrameRate(
      List<DanmakuBulletModel> bullets,
      Function(UniqueKey) allOutLeaveCallBack) {
    List<DanmakuBulletModel> newBullets =
        List.generate(bullets.length, (index) => bullets[index]);
    for (var bulletModel in newBullets) {
      bulletModel.runNextFrame();
      if (bulletModel.allOutLeave) {
        allOutLeaveCallBack(bulletModel.id);
      }
    }
    return newBullets;
  }
}
