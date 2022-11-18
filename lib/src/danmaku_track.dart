// 弹幕轨道
import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_utils.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class DanmakuTrack {
  final UniqueKey id = UniqueKey();

  UniqueKey? lastBulletId;

  UniqueKey? _bindFixedBulletId; // 绑定的静止定位弹幕ID

  UniqueKey? get bindFixedBulletId => _bindFixedBulletId;

  DanmakuTrack(this._trackHeight, this.offsetTop);

  late double offsetTop;

  late double _trackHeight;

  double get trackHeight => _trackHeight;

  // 允许注入静止弹幕
  bool get allowInsertFixedBullet => bindFixedBulletId == null;

  set trackHeight(double height) {
    _trackHeight = height;
  }

  // 卸载静止定位的子弹
  void unloadFixedBulletId() {
    _bindFixedBulletId = null;
  }

  void unloadLastBulletId() {
    lastBulletId = null;
  }

  void loadFixedBulletId(UniqueKey? bulletId) {
    assert(bulletId != null);
    _bindFixedBulletId = bulletId;
  }
}

class DanmakuTrackManager {
  List<DanmakuTrack> tracks = [];

  double get allTrackHeight {
    if (tracks.isEmpty) return 0;
    return tracks.last.offsetTop + tracks.last.trackHeight;
  }

  // 剩余可用高度
  double get remainderHeight => DanmakuConfig.showAreaHeight - allTrackHeight;

  // 算轨道相对区域是否溢出
  bool get isTrackOverflowArea =>
      allTrackHeight > DanmakuConfig.areaSize.height;

  // 补足屏幕内轨道
  void buildTrackFullScreen() {
    Size singleTextSize = DanmakuUtils.getDanmakuBulletSizeByText('s');
    while (allTrackHeight <
        (DanmakuConfig.areaSize.height - singleTextSize.height)) {
      buildTrack(singleTextSize.height);
    }
  }

  DanmakuTrack buildTrack(double trackHeight) {
    assert(trackHeight > 0);
    DanmakuTrack track = DanmakuTrack(trackHeight, allTrackHeight);
    tracks.add(track);
    return track;
  }

  // 重新计算轨道高度和距顶
  void recountTrackOffset(Map<UniqueKey, DanmakuBulletModel> bulletMap) {
    bool needBuildTrackFullScreen = true;
    Size currentLabelSize = DanmakuUtils.getDanmakuBulletSizeByText('s');
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].trackHeight = currentLabelSize.height;
      tracks[i].offsetTop = currentLabelSize.height * i;
      resetBullletsByTrack(tracks[i], bulletMap);
      // 把溢出可用区域的轨道之后全部删掉
      if ((tracks[i].trackHeight + tracks[i].offsetTop) >
          DanmakuConfig.areaSize.height) {
        for (int j = tracks.length - 1; j >= i; j--) {
          delBullletsByTrack(tracks[j], bulletMap);
        }
        tracks.removeRange(i, tracks.length);
        needBuildTrackFullScreen = false;
        break;
      }
    }
    if (needBuildTrackFullScreen) buildTrackFullScreen();
  }

  // 删除轨道上的所有子弹
  void delBullletsByTrack(
      DanmakuTrack track, Map<UniqueKey, DanmakuBulletModel> bulletMap) {
    if (track.bindFixedBulletId != null) {
      bulletMap.remove(track.bindFixedBulletId);
    }
    UniqueKey? prevBulletId = track.lastBulletId;
    while (prevBulletId != null) {
      UniqueKey? _prevBulletId = bulletMap[prevBulletId]?.prevBulletId;
      bulletMap.remove(prevBulletId);
      prevBulletId = _prevBulletId;
    }
  }

  // 重设轨道上的所有子弹
  void resetBullletsByTrack(
      DanmakuTrack track, Map<UniqueKey, DanmakuBulletModel> bulletMap) {
    if (track.bindFixedBulletId != null) {
      if (bulletMap[track.bindFixedBulletId] == null) return;
      bulletMap[track.bindFixedBulletId]!.offsetY = track.offsetTop;
      Size newBulletSize = DanmakuUtils.getDanmakuBulletSizeByText(
          bulletMap[track.bindFixedBulletId]!.text);
      bulletMap[track.bindFixedBulletId]!.bulletSize = newBulletSize;
    }
    UniqueKey? prevBulletId = track.lastBulletId;
    while (prevBulletId != null) {
      UniqueKey? _prevBulletId = bulletMap[prevBulletId]?.prevBulletId;
      if (bulletMap[prevBulletId] == null) return;
      bulletMap[prevBulletId]!.offsetY = track.offsetTop;
      bulletMap[prevBulletId]!.completeSize();
      prevBulletId = _prevBulletId;
    }
  }

  // 重置底部弹幕位置
  void resetBottomBullets(List<DanmakuBulletModel> bottomBullets,
      {bool reSize = false}) {
    if (bottomBullets.isEmpty) return;
    for (int i = 0; i < bottomBullets.length; i++) {
      bottomBullets[i].rebindTrack(tracks[tracks.length - 1 - i]);
      if (reSize) bottomBullets[i].completeSize();
    }
  }

  // 是否允许建立新轨道
  bool areaAllowBuildNewTrack(double needBuildTrackHeight) {
    assert(needBuildTrackHeight > 0);
    if (tracks.isEmpty) return true;
    return remainderHeight >= needBuildTrackHeight;
  }

  /// 删除轨道上绑定的子弹ID
  void removeTrackBindIdByBulletModel(DanmakuBulletModel bulletModel) {
    // 底部弹幕并没有绑定到轨道上
    if (bulletModel.position == DanmakuBulletPosition.bottom) return;
    if (bulletModel.bulletType == DanmakuBulletType.scroll) {
      tracks
          .firstWhereOrNull((element) => element.lastBulletId == bulletModel.id)
          ?.unloadLastBulletId();
    } else if (bulletModel.bulletType == DanmakuBulletType.fixed) {
      tracks
          .firstWhereOrNull(
              (element) => element.bindFixedBulletId == bulletModel.id)
          ?.unloadFixedBulletId();
    }
  }

  // 卸载全部轨道上绑定的弹幕ID
  unloadAllBullet() {
    for (var track in tracks) {
      track.unloadFixedBulletId();
      track.unloadLastBulletId();
    }
  }
}
