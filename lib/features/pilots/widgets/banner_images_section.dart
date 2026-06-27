import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';
import 'banner_image_picker.dart';

class BannerImagesSection extends StatelessWidget {
  const BannerImagesSection({
    required this.banners,
    required this.onUpload,
    required this.onDelete,
    this.isUploading = false,
    this.deletingPath,
    super.key,
  });

  final List<PilotBannerImageData> banners;
  final ValueChanged<PickedBannerImage> onUpload;
  final ValueChanged<PilotBannerImageData> onDelete;
  final bool isUploading;
  final String? deletingPath;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Banner Images',
      subtitle: 'Supabase Storage: pilot/{pilotId}/banners',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banners.isEmpty)
            const PilotEmptyState(message: 'No banner images found.')
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final banner in banners)
                  _BannerTile(
                    banner: banner,
                    isDeleting: deletingPath == banner.path,
                    onPreview: () => _previewBanner(context, banner),
                    onDelete: () => onDelete(banner),
                  ),
              ],
            ),
          SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: isUploading ? null : () => _pickAndUpload(context),
            icon: isUploading
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(strokeWidth: 2.r),
                  )
                : Icon(Icons.upload_rounded, size: 18.r),
            label: Text(isUploading ? 'Uploading' : 'Upload Banner'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final image = await pickBannerImage();
    if (image == null) {
      return;
    }

    onUpload(image);
  }

  void _previewBanner(BuildContext context, PilotBannerImageData banner) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(AppSpacing.xl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.name, style: AppTextStyles.headingMedium),
                SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: 720.w,
                    height: 320.h,
                    child: _BannerImage(url: banner.url),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    required this.banner,
    required this.isDeleting,
    required this.onPreview,
    required this.onDelete,
  });

  final PilotBannerImageData banner;
  final bool isDeleting;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              height: 92.h,
              width: double.infinity,
              child: _BannerImage(url: banner.url),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            banner.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(onPressed: onPreview, child: const Text('Preview')),
              const Spacer(),
              IconButton(
                tooltip: 'Delete Banner',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: CircularProgressIndicator(strokeWidth: 2.r),
                      )
                    : Icon(Icons.delete_outline, size: 18.r),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const _BannerPlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _BannerPlaceholder(),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primaryBlueLight),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primaryBlue,
          size: 30.r,
        ),
      ),
    );
  }
}
