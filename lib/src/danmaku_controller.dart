import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_bullet_manager.dart';
import 'package:danmaku/src/danmaku_render.dart';
import 'package:danmaku/src/danmaku_scheduler.dart';
import 'package:danmaku/src/danmaku_track.dart';
import 'package:flutter/material.dart';

typedef SetStateCallback = void Function(void Function());

enum AddBulletResCode { success, noSpace }

class AddBulletResBody {
  AddBulletResCode code = AddBulletResCode.success;
  String message = '';
  dynamic data;

  AddBulletResBody(this.code, {required this.message, this.data});
}

class DanmakuController extends ChangeNotifier {
  final DanmakuRenderManager _renderManager = DanmakuRenderManager();
  final DanmakuScheduler _schedulerManager = DanmakuScheduler();

  DanmakuTrackManager get _trackManager => _schedulerManager.trackManager;

  DanmakuBulletManager get _bulletManager => _schedulerManager.bulletManager;

  List<DanmakuBulletModel> get bullets => _bulletManager.bullets;

  bool isFullscreen = false;

  /// 是否暂停
  bool get isPause => DanmakuConfig.pause;

  /// 是否初始化过
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  void refreshState() {
    notifyListeners();
  }

  /// 清除定时器
  @override
  void dispose() {
    super.dispose();
    _renderManager.dispose();
    _schedulerManager.dispose();
  }

  void init(Size size) {
    resizeArea(size);
    _trackManager.buildTrackFullScreen();
    if (_isInitialized) return;
    _isInitialized = true;
    _run();
    _schedulerManager.run();
  }

  Function(List<DanmakuItem>) get load => _schedulerManager.load;

  void addDanmaku(
    String text, {
    Color color = Colors.red,
  }) {
    final item = DanmakuItem(
        duration: _schedulerManager.lastPosition,
        content: text,
        color: color,
        bulletType: DanmakuBulletType.scroll,
        bulletPosition: DanmakuBulletPosition.any,
        builder: (Text text) {
          return Container(
            decoration: BoxDecoration(border: Border.all(color: color)),
            child: Text(text.data!, style: TextStyle(color: color),),
          );
        });
    int index = _schedulerManager.danIndex;
    if (index == -1) {
      index = 0;
    }
    _schedulerManager.danmakuList.insert(index, item);
    _schedulerManager.danIndex = index;
    print(item.duration);
  }

  // 弹幕清屏
  void clearScreen() {
    _bulletManager.removeAllBullet();
    _trackManager.unloadAllBullet();
  }

  void seekTo(Duration position) {
    clearScreen();
    _schedulerManager.seekTo(position);
  }

  /// 暂停
  void pause() {
    DanmakuConfig.pause = true;
  }

  /// 播放
  void play() {
    DanmakuConfig.pause = false;
  }

  /// 修改弹幕速率
  void changeRate(double rate) {
    assert(rate > 0);
    DanmakuConfig.bulletRate = rate;
  }

  /// 设置子弹单击事件
  void setBulletTapCallBack(Function(DanmakuBulletModel) cb) {
    DanmakuConfig.bulletTapCallBack = cb;
  }

  /// 修改透明度
  void changeOpacity(double opacity) {
    assert(opacity <= 1);
    assert(opacity >= 0);
    DanmakuConfig.opacity = opacity;
  }

  /// 修改文字大小
  void changeLabelSize(int size) {
    assert(size > 0);
    DanmakuConfig.bulletLabelSize = size.toDouble();
    DanmakuConfig.areaOfChildOffsetY = DanmakuConfig.getAreaOfChildOffsetY();
    _trackManager.recountTrackOffset(_bulletManager.bulletsMap);
    _trackManager.resetBottomBullets(_bulletManager.bottomBullets,
        reSize: true);
  }

  /// 改变视图尺寸后调用，比如全屏
  void resizeArea(Size size) {
    DanmakuConfig.areaSize = size;
    DanmakuConfig.areaOfChildOffsetY = DanmakuConfig.getAreaOfChildOffsetY();
    _trackManager.recountTrackOffset(_bulletManager.bulletsMap);
    _trackManager.resetBottomBullets(_bulletManager.bottomBullets);
    if (DanmakuConfig.pause) {
      _renderManager.renderNextFrameRate(
          _bulletManager.bullets, _allOutLeaveCallBack);
    }
  }

  /// 修改弹幕最大可展示场景的百分比
  void changeShowArea(double percent) {
    assert(percent <= 1);
    assert(percent >= 0);
    DanmakuConfig.showAreaPercent = percent;
    _trackManager.buildTrackFullScreen();
  }

  /// 请不要调用这个函数
  void delBulletById(UniqueKey bulletId) {
    if (_bulletManager.bulletsMap[bulletId] != null) {
      _trackManager
          .removeTrackBindIdByBulletModel(_bulletManager.bulletsMap[bulletId]!);
      _bulletManager.removeBulletByKey(bulletId);
    }
  }

  // 子弹完全离开后回调
  void _allOutLeaveCallBack(UniqueKey bulletId) {
    if (_bulletManager.bulletsMap[bulletId]?.trackId != null) {
      _trackManager
          .removeTrackBindIdByBulletModel(_bulletManager.bulletsMap[bulletId]!);
      _bulletManager.bulletsMap.remove(bulletId);
    }
  }

  void _run() => _renderManager.run(() {
        _renderManager.renderNextFrameRate(
            _bulletManager.bullets, _allOutLeaveCallBack);
      }, refreshState);
}
