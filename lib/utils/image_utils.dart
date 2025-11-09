import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

// 将ImageProvider转换为可绘制的ui.Image
Future<ui.Image> loadImage(ImageProvider provider) async {
  final Completer<ui.Image> completer = Completer();
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);

  void imageListener(ImageInfo info, bool syncCall) {
    final ui.Image image = info.image;
    completer.complete(image);
    stream.removeListener(ImageStreamListener(imageListener));
  }

  stream.addListener(ImageStreamListener(imageListener));
  return completer.future;
}