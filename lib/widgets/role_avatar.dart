import 'dart:io';

import 'package:flutter/material.dart';

/// 角色头像：优先展示图片，缺失或加载失败时回退到首字头像。
class RoleAvatar extends StatelessWidget {
  const RoleAvatar({
    super.key,
    required this.fallbackText,
    required this.radius,
    this.imagePath,
  });

  final String fallbackText;
  final double radius;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return CircleAvatar(radius: radius, child: _buildFallback());
    }

    final imageProvider = path.startsWith('assets/')
        ? AssetImage(path) as ImageProvider
        : FileImage(File(path));

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: Image(
          image: imageProvider,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: _buildFallback());
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Text(
      fallbackText,
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
