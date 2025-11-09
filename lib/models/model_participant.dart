// 人员模型
class Participant {
  final String name;
  final String id; // 工号（用于去重）
  final String? avatarPath; // 头像本地路径
  bool isWinner;

  Participant({
    required this.name,
    required this.id,
    this.avatarPath,
    this.isWinner = false,
  });
}
