import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

class FoodImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;

  const FoodImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(imageUrl);

    if (url.isEmpty) return _fallback();

    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: height, width: width,
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF16a34a), strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => placeholder ?? SizedBox(
    height: height, width: width,
    child: const Center(
      child: Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey)),
  );
}
