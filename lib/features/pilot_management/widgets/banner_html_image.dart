import 'package:flutter/widgets.dart';

import 'banner_html_image_stub.dart'
    if (dart.library.html) 'banner_html_image_web.dart';

class PilotBannerHtmlImage extends StatelessWidget {
  const PilotBannerHtmlImage({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return buildBannerHtmlImage(url);
  }
}
