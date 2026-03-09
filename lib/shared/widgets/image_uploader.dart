import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class ImageUploader extends StatelessWidget {
  final String label;
  final String? currentImageUrl;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;
  final double? width;
  final double height;
  final String? recommendation;

  const ImageUploader({
    super.key,
    required this.label,
    this.currentImageUrl,
    this.onUpload,
    this.onRemove,
    this.width,
    this.height = 160,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
          _buildPreview()
        else
          _buildDropZone(),
        if (recommendation != null) ...[
          const SizedBox(height: 6),
          Text(
            recommendation!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
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
                    child:
                        Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ),
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
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
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          borderRadius: 12,
          dashWidth: 6,
          dashSpace: 4,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.primaryColor.withValues(alpha: 0.03),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload $label',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG, JPG, SVG up to 5MB',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        final extracted = metric.extractPath(distance, end.toDouble());
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
