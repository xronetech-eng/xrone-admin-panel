import 'package:flutter/widgets.dart';

import 'responsive_breakpoints.dart';

enum DeviceScreenType { mobile, tablet, desktop }

abstract final class ResponsiveHelper {
  static DeviceScreenType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= ResponsiveBreakpoints.desktopMin) {
      return DeviceScreenType.desktop;
    }

    if (width >= ResponsiveBreakpoints.tabletMin) {
      return DeviceScreenType.tablet;
    }

    return DeviceScreenType.mobile;
  }

  static bool isDesktop(BuildContext context) {
    return deviceType(context) == DeviceScreenType.desktop;
  }

  static bool isTablet(BuildContext context) {
    return deviceType(context) == DeviceScreenType.tablet;
  }

  static bool isMobile(BuildContext context) {
    return deviceType(context) == DeviceScreenType.mobile;
  }

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return switch (deviceType(context)) {
      DeviceScreenType.desktop => desktop ?? tablet ?? mobile,
      DeviceScreenType.tablet => tablet ?? mobile,
      DeviceScreenType.mobile => mobile,
    };
  }
}
