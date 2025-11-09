import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../models/model_prize.dart';
import '../models/model_participant.dart';
import '../provider/lottery_provider.dart';
import '../utils/image_utils.dart';
import 'dialogs.dart';

class EarthLotteryView extends StatefulWidget {
  const EarthLotteryView({super.key});

  @override
  State<EarthLotteryView> createState() => _EarthLotteryViewState();
}

class _EarthLotteryViewState extends State<EarthLotteryView> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _rotationY = 0; // Y轴旋转角度
  double _rotationX = 10; // X轴旋转角度
  Map<String, ui.Image> _avatarCache = {}; // 头像缓存（id -> 图像）

  @override
  void initState() {
    super.initState();
    // 初始化旋转动画（20秒一圈）
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(() {
      if (Provider.of<LotteryProvider>(context, listen: false).isRolling) {
        setState(() {
          _rotationY = _rotationController.value * 360;
          _rotationX = 10 + (sin(_rotationController.value * 2 * pi) * 5); // 轻微上下摆动
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当参与者列表变化时，预加载头像
    final provider = Provider.of<LotteryProvider>(context);
    _preloadAvatars(provider.participants);
  }

  // 预加载所有头像
  Future<void> _preloadAvatars(List<Participant> participants) async {
    final newCache = <String, ui.Image>{};
    for (final p in participants) {
      if (p.avatarPath != null && !_avatarCache.containsKey(p.id)) {
        try {
          final image = await loadImage(FileImage(File(p.avatarPath!)));
          newCache[p.id] = image;
        } catch (e) {
          debugPrint('加载头像失败（${p.name}）：$e');
        }
      }
    }
    setState(() => _avatarCache.addAll(newCache));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LotteryProvider>(
      builder: (ctx, provider, _) {
        // 控制旋转状态
        if (provider.isRolling && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!provider.isRolling && _rotationController.isAnimating) {
          _rotationController.stop();
        }

        return Stack(
          children: [
            // 星空背景
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000033), Color(0xFF000066)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 地球抽奖区域
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 透视效果
                  ..rotateY(vm.radians(_rotationY))
                  ..rotateX(vm.radians(_rotationX)),
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.shortestSide * 0.8,
                      MediaQuery.of(context).size.shortestSide * 0.8),
                  painter: EarthPainter(
                    participants: provider.participants,
                    currentWinner: provider.currentWinner,
                    isRolling: provider.isRolling,
                    avatarCache: _avatarCache,
                  ),
                ),
              ),
            ),

            // 顶部操作栏
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('导入名单'),
                    onPressed: provider.isRolling ? null : () => provider.importParticipants(),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_box),
                    label: const Text('添加奖品'),
                    onPressed: provider.isRolling ? null : () async {
                      final prize = await showAddPrizeDialog(context);
                      if (prize != null) provider.addPrize(prize.name,prize.remainingCount);
                    },
                  ),
                  if (provider.prizes.isNotEmpty)
                    DropdownButton<Prize>(
                      value: provider.prizes[provider.currentPrizeIndex],
                      items: provider.prizes.map((prize) {
                        return DropdownMenuItem(
                          value: prize,
                          child: Text(
                            '${prize.name}（剩余：${prize.remainingCount}）',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: provider.isRolling ? null : (prize) {
                        if (prize != null) {
                          provider.switchPrize(provider.prizes.indexOf(prize));
                        }
                      },
                      dropdownColor: Colors.white,
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('导出结果'),
                    onPressed: provider.isRolling ? null : () => provider.exportWinners(),
                  ),
                ],
              ),
            ),

            // 底部控制按钮
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: provider.participants.isEmpty || provider.prizes.isEmpty
                      ? null
                      : provider.isRolling
                      ? provider.stopRolling
                      : provider.startRolling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isRolling ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    provider.isRolling ? '停止抽奖' : '开始抽奖',
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 地球绘制Painter
class EarthPainter extends CustomPainter {
  final List<Participant> participants;
  final Participant? currentWinner;
  final bool isRolling;
  final Map<String, ui.Image> avatarCache;

  EarthPainter({
    required this.participants,
    required this.currentWinner,
    required this.isRolling,
    required this.avatarCache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 绘制地球底色（蓝色渐变）
    final earthPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF4A90E2), Color(0xFF003366)],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, earthPaint);

    // 2. 绘制地球表面光效
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    // 3. 绘制参与者头像
    if (participants.isEmpty) return;

    for (var i = 0; i < participants.length; i++) {
      final p = participants[i];
      final isWinner = currentWinner?.id == p.id;

      // 计算球面坐标（极坐标转平面坐标）
      final angle = (i * (360 / participants.length)) * pi / 180;
      final distance = 0.4 + (i % 6) * 0.1; // 控制距离球心的距离（避免集中）
      final x = center.dx + radius * distance * cos(angle);
      final y = center.dy + radius * distance * sin(angle);

      // 头像大小（中奖时放大）
      final avatarSize = isRolling ? 30 : (isWinner ? 60 : 25);

      // 绘制头像
      if (avatarCache.containsKey(p.id)) {
        final image = avatarCache[p.id]!;
        canvas.save();
        canvas.translate(x, y);

        // 中奖头像添加发光效果
        if (isWinner && !isRolling) {
          final winnerGlow = Paint()
            ..color = Colors.yellow.withOpacity(0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
          canvas.drawCircle(Offset.zero, avatarSize / 2 + 10, winnerGlow);
        }

        // 绘制头像图片
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(-avatarSize / 2, -avatarSize / 2, avatarSize.toDouble(), avatarSize.toDouble()),
          Paint()
            ..colorFilter = ColorFilter.mode(
              Colors.white.withOpacity(isRolling ? 1.0 : (isWinner ? 1.0 : 0.6)),
              BlendMode.srcATop,
            ),
        );
        canvas.restore();
      } else {
        // 无头像时显示姓名首字母
        final textPainter = TextPainter(
          text: TextSpan(
            text: p.name.isNotEmpty ? p.name[0] : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWinner ? 24 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EarthPainter oldDelegate) {
    return oldDelegate.participants != participants ||
        oldDelegate.currentWinner != currentWinner ||
        oldDelegate.isRolling != isRolling ||
        oldDelegate.avatarCache != avatarCache;
  }
}