
import 'model_participant.dart';

class Prize {
  final String name; // 奖品名称
  final int totalCount; // 总数量
  int remainingCount; // 剩余数量
  List<Participant> winners; // 中奖者列表

  Prize({
    required this.name,
    required this.totalCount,
  })  : remainingCount = totalCount,
        winners = [];
}