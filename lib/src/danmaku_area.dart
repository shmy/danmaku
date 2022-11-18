// 弹幕主场景
import 'package:danmaku/src/config.dart';
import 'package:danmaku/src/danmaku_bullet.dart';
import 'package:danmaku/src/danmaku_controller.dart';
import 'package:flutter/material.dart';

class DanmakuArea extends StatefulWidget {
  const DanmakuArea(
      {Key? key, required this.controller, this.bulletTapCallBack})
      : super(key: key);

  final DanmakuController controller;

  final Function(DanmakuBulletModel)? bulletTapCallBack;

  @override
  State<DanmakuArea> createState() => DanmakuAreaState();
}

class DanmakuAreaState extends State<DanmakuArea> {
  DanmakuController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_listener);
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    super.dispose();
  }
  void _listener() {
    setState(() {

    });
  }

  // 构建全部的子弹
  List<Widget> buildAllBullet(BuildContext context) {
    return List.generate(controller.bullets.length,
        (index) => buildBulletToScreen(context, controller.bullets[index]));
  }

  // 构建子弹
  Widget buildBulletToScreen(
      BuildContext context, DanmakuBulletModel bulletModel) {
    DanmakuBullet bullet = DanmakuBullet(
      text: bulletModel.text,
      danmakuId: bulletModel.id,
      color: bulletModel.color,
      builder: bulletModel.builder,
    );
    return Positioned(
        right: bulletModel.offsetX,
        top: bulletModel.offsetY + DanmakuConfig.areaOfChildOffsetY,
        child: DanmakuConfig.bulletTapCallBack == null
            ? bullet
            : GestureDetector(
                onTap: () => DanmakuConfig.bulletTapCallBack?.call(bulletModel),
                child: bullet));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DanmakuConfig.areaSize.height,
      width: DanmakuConfig.areaSize.width,
      child: Stack(
        children: [...buildAllBullet(context)],
      ),
    );
  }
}
