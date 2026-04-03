import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable book cover widget that checks customCoverBase64 first,
/// then falls back to coverUrl, then shows a placeholder icon.
class BookCoverImage extends StatelessWidget {
  final String? customCoverBase64;
  final String? coverUrl;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  const BookCoverImage({
    super.key,
    this.customCoverBase64,
    this.coverUrl,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    // Priority 1: custom cover (base64)
    if (customCoverBase64 != null && customCoverBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(customCoverBase64!),
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildFromUrl(),
      );
    }
    return _buildFromUrl();
  }

  Widget _buildFromUrl() {
    // Priority 2: network cover URL
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    // Priority 3: placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceDark,
      child: Icon(
        Icons.book,
        color: AppColors.textMuted,
        size: iconSize,
      ),
    );
  }
}
