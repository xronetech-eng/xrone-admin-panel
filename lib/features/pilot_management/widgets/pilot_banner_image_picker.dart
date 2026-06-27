import '../models/pilot_management_model.dart';
import 'pilot_banner_image_picker_stub.dart'
    if (dart.library.html) 'pilot_banner_image_picker_web.dart';

Future<PickedPilotBannerImage?> pickPilotBannerImage() => pickImage();
