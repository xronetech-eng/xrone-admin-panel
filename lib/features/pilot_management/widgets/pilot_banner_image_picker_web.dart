// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/pilot_management_model.dart';

Future<PickedPilotBannerImage?> pickImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  input.click();

  await input.onChange.first;
  final file = input.files?.isEmpty ?? true ? null : input.files!.first;
  if (file == null) {
    return null;
  }

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;

  final result = reader.result;
  if (result is! ByteBuffer) {
    return null;
  }

  return PickedPilotBannerImage(
    name: file.name,
    bytes: Uint8List.view(result),
    contentType: file.type,
  );
}
