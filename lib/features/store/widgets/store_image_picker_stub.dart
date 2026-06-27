import 'dart:typed_data';

class StorePickedFile {
  const StorePickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<StorePickedFile?> pickStoreImage() async => null;
