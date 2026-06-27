import 'dart:typed_data';

import 'banner_image_picker_stub.dart'
    if (dart.library.html) 'banner_image_picker_web.dart';

class PickedBannerImage {
  const PickedBannerImage({
    required this.name,
    required this.bytes,
    this.contentType = '',
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

Future<PickedBannerImage?> pickBannerImage() {
  return pickBannerImagePlatform();
}
