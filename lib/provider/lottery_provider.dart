
// 抽奖状态管理（用Provider）
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/model_participant.dart';
import '../models/model_prize.dart';



class LotteryProvider extends ChangeNotifier {
  List<Participant> _participants = []; // 所有参与人员
  List<Prize> _prizes = []; // 所有奖品
  int _currentPrizeIndex = 0; // 当前轮次（选中的奖品）
  bool _isRolling = false; // 是否正在滚动
  Participant? _currentWinner; // 当前中奖者
  Timer? _rollTimer; // 滚动计时器

  // 导入参与人员（从Excel/CSV）
  Future<void> importParticipants() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      // 解析Excel（以xlsx为例，具体逻辑需用excel库实现）
      var bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables.values.first;
      _participants = [];
      for (var row in sheet.rows.skip(1)) { // 跳过表头
        String name = row[0]?.value.toString() ?? '';
        String id = row[1]?.value.toString() ?? '';
        if (name.isNotEmpty && id.isNotEmpty) {
          _participants.add(Participant(name: name, id: id));
        }
      }
      // 去重（根据id）
      _participants = _participants.toSet().toList();
      notifyListeners();
    }
  }

  // 添加奖品
  void addPrize(String name, int count) {
    _prizes.add(Prize(name: name, totalCount: count));
    notifyListeners();
  }

  // 开始滚动抽奖
  void startRolling() {
    if (_isRolling || _participants.isEmpty || _prizes.isEmpty) return;
    _isRolling = true;
    _rollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // 筛选未中奖的人员
      final candidates = _participants.where((p) => !p.isWinner).toList();
      if (candidates.isEmpty) {
        stopRolling();
        return;
      }
      // 随机选择一个人员
      _currentWinner = candidates[Random().nextInt(candidates.length)];
      notifyListeners();
    });
  }

  // 停止滚动，确定中奖者
  void stopRolling() {
    if (!_isRolling || _currentWinner == null) return;
    _isRolling = false;
    _rollTimer?.cancel();
    // 标记为中奖
    _currentWinner!.isWinner = true;
    // 添加到当前奖品的中奖列表
    _prizes[_currentPrizeIndex].winners.add(_currentWinner!);
    _prizes[_currentPrizeIndex].remainingCount--;
    notifyListeners();
    // 播放中奖音效（可选）
    _playSound('assets/sounds/win.mp3');
  }

  // 切换奖品轮次
  void switchPrize(int index) {
    _currentPrizeIndex = index;
    notifyListeners();
  }

  // 导出中奖结果
  Future<void> exportWinners() async {
    // 实现逻辑：用excel库生成Excel文件，保存到本地
    // 略（可参考excel库文档）
  }

  // 播放音效
  Future<void> _playSound(String path) async {
    final player = AudioPlayer();
    await player.play(AssetSource(path));
  }

  // getter方法（供UI调用）
  List<Participant> get participants => _participants;
  List<Prize> get prizes => _prizes;
  int get currentPrizeIndex => _currentPrizeIndex;
  bool get isRolling => _isRolling;
  Participant? get currentWinner => _currentWinner;
}