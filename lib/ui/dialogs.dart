import 'package:flutter/material.dart';
import '../models/model_prize.dart';

// 添加奖品弹窗
Future<Prize?> showAddPrizeDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final countController = TextEditingController();

  return showDialog<Prize>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('添加奖品'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '奖品名称（如：一等奖）'),
          ),
          TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '奖品数量'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (nameController.text.isNotEmpty && countController.text.isNotEmpty) {
              Navigator.pop(ctx, Prize(
                name: nameController.text,
                totalCount: int.parse(countController.text),
              ));
            }
          },
          child: const Text('确认'),
        ),
      ],
    ),
  );
}