// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'banner_image_picker.dart';

Future<PickedBannerImage?> pickBannerImagePlatform() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();
  final completer = Completer<PickedBannerImage?>();

  input.onChange.first.then((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(
          PickedBannerImage(
            name: file.name,
            bytes: result.asUint8List(),
            contentType: file.type,
          ),
        );
      } else {
        completer.complete(null);
      }
    });
    reader.onError.first.then((_) => completer.complete(null));
  });

  return completer.future;
}
