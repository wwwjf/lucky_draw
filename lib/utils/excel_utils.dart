import 'package:file_picker/file_picker.dart';
import '../models/model_prize.dart';
import '../models/model_participant.dart';

// 导入参与者名单（简化版：读取CSV格式）
Future<List<Participant>> importParticipants() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (result == null) return [];

  final file = result.files.single;
  final content = String.fromCharCodes(file.bytes!);
  final lines = content.split('\n');
  final participants = <Participant>[];

  // CSV格式：id,姓名,头像路径（可选）
  for (var line in lines.skip(1)) { // 跳过表头
    final parts = line.trim().split(',');
    if (parts.length >= 2) {
      participants.add(Participant(
        id: parts[0].trim(),
        name: parts[1].trim(),
        avatarPath: parts.length >= 3 ? parts[2].trim() : null,
      ));
    }
  }

  // 去重
  return participants.toSet().toList();
}

// 导出中奖结果（简化版：打印到控制台，实际项目需生成Excel）
void exportWinners(List<Prize> prizes) {
  print('===== 中奖结果 =====');
  for (var prize in prizes) {
    print('奖项：${prize.name}（共${prize.totalCount}名）');
    for (var winner in prize.winners) {
      print('- ${winner.name}（${winner.id}）');
    }
  }
}