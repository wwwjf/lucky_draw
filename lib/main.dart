import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'provider/lottery_provider.dart';
import 'ui/earth_lottery.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 桌面端全屏设置
  /*if ([TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.android].contains(defaultTargetPlatform)) {
    await WindowManager.instance.ensureInitialized();
    await WindowManager.instance.setFullScreen(true);
  }*/
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '地球主题年会抽奖',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LotteryHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LotteryHomePage extends StatelessWidget {
  const LotteryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (ctx) => LotteryProvider(),
        child: const EarthLotteryView(),
      ),
    );
  }
}