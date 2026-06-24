import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class WidgetCoverBackground extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final Color? fallbackColor;

  const WidgetCoverBackground({
    super.key,
    this.imageUrl,
    required this.child,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (imageUrl != null)
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (_, __, ___) => _fallback,
          )
        else
          _fallback,
        child,
      ],
    );
  }

  Widget get _fallback => Container(
        color: fallbackColor ?? const Color(0xFF151B23),
      );
}
