import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const AppIcon({super.key, this.size = 52, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.storefront_rounded, size: size, color: color ?? Colors.white);
  }
}

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double containerSize;
  final Color bgColor;
  const AppLogo({super.key, this.iconSize = 44, this.containerSize = 80, this.bgColor = const Color(0xFF16a34a)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize, height: containerSize,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(containerSize * 0.25)),
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.storefront_rounded, size: iconSize, color: Colors.white),
        Positioned(
          bottom: containerSize * 0.1, right: containerSize * 0.1,
          child: Container(
            width: containerSize * 0.3, height: containerSize * 0.3,
            decoration: const BoxDecoration(color: Color(0xFFfbbf24), shape: BoxShape.circle),
            child: Icon(Icons.currency_exchange, size: containerSize * 0.18, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
