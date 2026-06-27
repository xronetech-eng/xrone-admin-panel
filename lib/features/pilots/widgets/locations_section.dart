import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class LocationsSection extends StatelessWidget {
  const LocationsSection({required this.locations, super.key});

  final List<PilotLocationData> locations;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Locations',
      subtitle: 'Read only',
      child: locations.isEmpty
          ? const PilotEmptyState(message: 'No locations found.')
          : Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final location in locations)
                  _LocationCard(location: location),
              ],
            ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final PilotLocationData location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          PilotInfoRow(label: 'Address', value: location.line1),
          PilotInfoRow(label: 'City', value: location.city),
          PilotInfoRow(label: 'State', value: location.state),
          PilotInfoRow(label: 'Pincode', value: location.pincode),
          PilotInfoRow(label: 'Latitude', value: location.latitude),
          PilotInfoRow(label: 'Longitude', value: location.longitude),
        ],
      ),
    );
  }
}
