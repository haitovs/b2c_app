import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Image uploader widget with preview.
///
/// Shows a drop zone / button to select an image, with preview of the current
/// image (either a network URL or a local placeholder).
class ImageUploader extends StatelessWidget {
  /// Label displayed above the upload area.
  final String label;

  /// Current image URL (if already uploaded).
  final String? currentImageUrl;

  /// Callback when user taps to upload.
  final VoidCallback? onUpload;

  /// Callback when user taps to remove the current image.
  final VoidCallback? onRemove;

  /// Width of the upload area. Defaults to double.infinity.
  final double? width;

  /// Height of the upload area. Defaults to 160.
  final double height;

  const ImageUploader({
    super.key,
    required this.label,
    this.currentImageUrl,
    this.onUpload,
    this.onRemove,
    this.width,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
          _buildPreview()
        else
          _buildDropZone(),
      ],
    );
  }

  Widget _buildPreview() {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              currentImageUrl!,
              width: width ?? double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDropZone(),
            ),
          ),
          // Remove button
          if (onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ),
              ),
            ),
          // Change button
          if (onUpload != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onUpload,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Click to upload',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG, JPG up to 5MB',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
