import 'package:flutter/material.dart';

import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class LicenseSection extends StatelessWidget {
  const LicenseSection({required this.license, super.key});

  final PilotLicenseData license;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'License Details',
      subtitle: 'Read only',
      child: Column(
        children: [
          PilotInfoRow(label: 'License Number', value: license.licenseNumber),
          PilotInfoRow(label: 'Issue Date', value: license.issueDate),
          PilotInfoRow(label: 'Expiry Date', value: license.expiryDate),
          PilotImageTile(
            label: 'License Image',
            fileName: license.licenseImage,
          ),
        ],
      ),
    );
  }
}
