// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildBannerHtmlImage(String url) {
  final viewType = 'pilot-management-banner-${url.hashCode}';
  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final image = html.ImageElement(src: url)
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.display = 'block';

      image.onLoad.listen((_) {
        debugPrint('[Banner] image loaded');
      });
      image.onError.listen((error) {
        debugPrint('[Banner] image failed=$error');
      });

      return image;
    });
  } on Object {
    // The view factory may already be registered after rebuilds.
  }

  return HtmlElementView(viewType: viewType);
}
