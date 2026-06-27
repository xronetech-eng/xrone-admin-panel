import 'dart:js_interop';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

class StorePickedFile {
  const StorePickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<StorePickedFile?> pickStoreImage() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';
  input.click();
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.length == 0) return null;
  final file = files.item(0);
  if (file == null) return null;

  final reader = web.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;
  final result = reader.result;
  if (result == null) return null;

  final bytes = (result as JSArrayBuffer).toDart.asUint8List();
  return StorePickedFile(name: file.name, bytes: bytes);
}
