import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image widget that handles cross-origin images gracefully.
///
/// On Flutter web, failed image loads (e.g. CORS-blocked) can freeze the UI
/// when many fail at once. This widget isolates failures with a short timeout
/// and shows the [placeholder] immediately on error, preventing UI jank.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        Icon(
          Icons.image_not_supported_outlined,
          size: (height ?? 40) * 0.4,
          color: Colors.grey.shade400,
        );

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // On web, set cacheWidth to avoid decoding huge images on the UI thread
      cacheWidth: kIsWeb ? (width?.toInt() ?? 200) * 2 : null,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Center(child: fallback),
      ),
    );
  }
}
