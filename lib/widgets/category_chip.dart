import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, this.iconUrl, this.onTap});

  final String label;
  final String? iconUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: iconUrl != null && iconUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: iconUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.checkroom_outlined,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.checkroom_outlined,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
