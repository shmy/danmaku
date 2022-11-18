import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:flutter/material.dart';

class DanmakuBulletManager {
  Map<UniqueKey, DanmakuBulletModel> _bullets = {};

  List<DanmakuBulletModel> get bullets => _bullets.values.toList();

  // 返回所有的底部弹幕
  List<DanmakuBulletModel> get bottomBullets => bullets
      .where((element) => element.position == DanmakuBulletPosition.bottom)
      .toList();

  List<UniqueKey> get bulletKeys => _bullets.keys.toList();

  Map<UniqueKey, DanmakuBulletModel> get bulletsMap => _bullets;

  // 记录子弹到map中
  recordBullet(DanmakuBulletModel bullet) {
    _bullets[bullet.id] = bullet;
  }

  void removeBulletByKey(UniqueKey id) => _bullets.remove(id);

  void removeAllBullet() {
    _bullets = {};
  }

  // 初始化一个子弹
  DanmakuBulletModel initBullet(
      String text, UniqueKey trackId, Size bulletSize, double offsetY,
      {DanmakuBulletType bulletType = DanmakuBulletType.scroll,
      required DanmakuBulletPosition position,
      required Color color,
      UniqueKey? prevBulletId,
      int offsetMS = 0,
      Widget Function(Text)? builder}) {
    assert(bulletSize.height > 0);
    assert(bulletSize.width > 0);
    assert(offsetY >= 0);
    UniqueKey bulletId = UniqueKey();
    DanmakuBulletModel bullet = DanmakuBulletModel(
        color: color,
        id: bulletId,
        trackId: trackId,
        text: text,
        position: position,
        bulletSize: bulletSize,
        offsetY: offsetY,
        offsetMS: offsetMS,
        prevBulletId: prevBulletId,
        bulletType: bulletType,
        builder: builder);
    // 记录到表上
    recordBullet(bullet);
    return bullet;
  }
}
