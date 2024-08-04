import 'dart:ui' as ui show Image;
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

import 'CustomCacheManager.dart';

typedef SVGACustomDrawer = Function(Canvas canvas, int frameIndex);

class SVGADynamicEntity {
  final Map<String, bool> dynamicHidden = {};
  final Map<String, ui.Image> dynamicImages = {};
  final Map<String, TextPainter> dynamicText = {};
  final Map<String, SVGACustomDrawer> dynamicDrawer = {};

  void setHidden(bool value, String forKey) {
    this.dynamicHidden[forKey] = value;
  }

  void setImage(ui.Image image, String forKey) {
    this.dynamicImages[forKey] = image;
  }

  Future<void> setImageWithUrl(String url, String forKey) async {
    var file = await CustomCacheManager.instance.getSingleFile(url);
    Uint8List bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resizedImage = img.copyResize(image, width: 100, height: 100);
    final circularImage = img.copyCropCircle(resizedImage,radius: 80);
    Uint8List im=  Uint8List.fromList(img.encodePng(circularImage));
    this.dynamicImages[forKey] =
        await decodeImageFromList(im);
  }
  Future<void> setImageFromLocal(String url, String forKey) async {
    final ByteData assetImageByteData = await rootBundle.load(url);

    this.dynamicImages[forKey] =
        await decodeImageFromList(assetImageByteData.buffer.asUint8List());
  }

  void setText(TextPainter textPainter, String forKey) {
    if (textPainter.textDirection == null) {
      textPainter.textDirection = TextDirection.ltr;
      textPainter.layout();
    }
    this.dynamicText[forKey] = textPainter;
  }

  void setDynamicDrawer(SVGACustomDrawer drawer, String forKey) {
    this.dynamicDrawer[forKey] = drawer;
  }

  void reset() {
    this.dynamicHidden.clear();
    this.dynamicImages.clear();
    this.dynamicText.clear();
    this.dynamicDrawer.clear();
  }
}
