import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_bullet_manager.dart';
import 'package:danmaku/src/danmaku_controller.dart';
import 'package:danmaku/src/danmaku_track.dart';
import 'package:danmaku/src/danmaku_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';

class DanmakuItem {
  final Duration duration;
  final String content;
  final Color color;
  final DanmakuBulletType bulletType;
  final DanmakuBulletPosition bulletPosition;
  final Widget Function(Text)? builder;

  DanmakuItem({
    required this.duration,
    required this.content,
    required this.color,
    required this.bulletType,
    required this.bulletPosition,
    this.builder,
  });

  @override
  String toString() {
    return 'DanmakuItem(duration: $duration, content: $content, color: $color, bulletType: $bulletType, bulletPosition: $bulletPosition)';
  }
}

class DanmakuScheduler {
  final List<DanmakuItem> danmakuList = [];
  Ticker? _ticker;
  int danIndex = 0;
  Duration position = Duration.zero;
  Duration lastPosition = Duration.zero;

  final DanmakuTrackManager trackManager = DanmakuTrackManager();
  final DanmakuBulletManager bulletManager = DanmakuBulletManager();

  List<DanmakuTrack> get tracks => trackManager.tracks;

  List<DanmakuBulletModel> get bullets => bulletManager.bullets;

  void load(List<DanmakuItem> danmakuList) {
    this.danmakuList.clear();
    this.danmakuList.addAll(danmakuList);
  }

  void run() {
    _ticker = Ticker(_onTick);
    _ticker?.start();
  }

  void _onTick(Duration elapsed) {
    // 暂停不执行
    if (DanmakuConfig.pause) {
      return;
    }
    if (danIndex == -1) {
      return;
    }
    if (danmakuList.isEmpty) {
      return;
    }
    if (danIndex > danmakuList.length - 1) {
      return;
    }
    final item = danmakuList[danIndex];
    lastPosition = position + elapsed;
    if (lastPosition > item.duration) {
      addDanmaku(item);
      danIndex++;
    }
  }

  void seekTo(Duration position) {
    _ticker?.dispose();
    this.position = position;
    danIndex =
        danmakuList.indexWhere((element) => element.duration >= position);
    _ticker = Ticker(_onTick);
    _ticker?.start();
  }

  // 成功返回AddBulletResBody.data为bulletId
  AddBulletResBody addDanmaku(DanmakuItem item) {
    assert(item.content.isNotEmpty);
    // 先获取子弹尺寸
    Size bulletSize = DanmakuUtils.getDanmakuBulletSizeByText(item.content);
    // 寻找可用的轨道
    DanmakuTrack? track = _findAvailableTrack(bulletSize,
        bulletType: item.bulletType,
        position: item.bulletPosition,
        offsetMS: 0);
    // 如果没有找到可用的轨道
    if (track == null) {
      return AddBulletResBody(
        AddBulletResCode.noSpace,
        message: '',
      );
    }
    DanmakuBulletModel? bullet = bulletManager.initBullet(
      item.content, track.id, bulletSize, track.offsetTop,
      prevBulletId: track.lastBulletId,
      position: item.bulletPosition,
      bulletType: item.bulletType,
      color: item.color,
      builder: item.builder,
      offsetMS: 0,
    );
    if (item.bulletType == DanmakuBulletType.scroll) {
      track.lastBulletId = bullet.id;
    } else {
      // 底部弹幕 不记录到轨道上
      // 查询是否可注入弹幕时 底部弹幕 和普通被注入到底部的静止弹幕可重叠
      if (item.bulletPosition == DanmakuBulletPosition.any) {
        track.loadFixedBulletId(bullet.id);
      }
    }
    return AddBulletResBody(AddBulletResCode.success,
        data: bullet.id, message: '');
  }

// 查询可用轨道
  DanmakuTrack? _findAvailableTrack(Size bulletSize,
      {DanmakuBulletType bulletType = DanmakuBulletType.scroll,
      int offsetMS = 0,
      DanmakuBulletPosition position = DanmakuBulletPosition.any}) {
    assert(bulletSize.height > 0);
    assert(bulletSize.width > 0);
    if (position == DanmakuBulletPosition.any) {
      return _findAllowInsertTrack(bulletSize,
          bulletType: bulletType, offsetMS: offsetMS);
    } else {
      return _findAllowInsertBottomTrack(bulletSize);
    }
  }

  /// 获取允许注入的轨道
  DanmakuTrack? _findAllowInsertTrack(Size bulletSize,
      {DanmakuBulletType bulletType = DanmakuBulletType.scroll,
      int offsetMS = 0}) {
    DanmakuTrack? _track;
    // 在现有轨道里找
    for (int i = 0; i < tracks.length; i++) {
      // 当前轨道溢出可用轨道
      if (DanmakuUtils.isEnableTrackOverflowArea(tracks[i])) break;
      bool allowInsert = _trackAllowInsert(tracks[i], bulletSize,
          bulletType: bulletType, offsetMS: offsetMS);
      if (allowInsert) {
        _track = tracks[i];
        break;
      }
    }
    return _track;
  }

  // 查找允许注入的底部轨道
  DanmakuTrack? _findAllowInsertBottomTrack(Size bulletSize) {
    DanmakuTrack? _track;
    // 在现有轨道里找
    // 底部弹幕 指的是 最后几条轨道 从最底下往上发
    for (int i = tracks.length - 1; i >= tracks.length - 3; i--) {
      // 从当前的弹幕里找 有没有在这个轨道上的
      final DanmakuBulletModel? bullet = bulletManager.bottomBullets
          .firstWhereOrNull((element) => element.trackId == tracks[i].id);
      if (bullet == null) {
        _track = tracks[i];
        break;
      }
    }
    return _track;
  }

  /// 查询该轨道是否允许注入
  bool _trackAllowInsert(DanmakuTrack track, Size needInsertBulletSize,
      {DanmakuBulletType bulletType = DanmakuBulletType.scroll,
      int offsetMS = 0}) {
    UniqueKey lastBulletId;
    assert(needInsertBulletSize.height > 0);
    assert(needInsertBulletSize.width > 0);
    // 非底部弹幕 超出配置的可视区域 就不可注入
    if (bulletType == DanmakuBulletType.fixed) {
      return track.allowInsertFixedBullet;
    }
    if (track.lastBulletId == null) return true;
    lastBulletId = track.lastBulletId!;
    DanmakuBulletModel? lastBullet = bulletManager.bulletsMap[lastBulletId];
    if (lastBullet == null) return true;
    return !DanmakuUtils.trackInsertBulletHasBump(
        lastBullet, needInsertBulletSize,
        offsetMS: offsetMS);
  }

  void dispose() {
    _ticker?.dispose();
  }
}
