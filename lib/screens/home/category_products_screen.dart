import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../providers/products_provider.dart';
import '../../widgets/product_card.dart';

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final SoleCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: productsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Brak ofert w kategorii "${category.name}".',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = switch (constraints.maxWidth) {
                < 520 => 2,
                < 820 => 3,
                < 1120 => 4,
                _ => 5,
              };
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, i) => ProductCard(
                  product: list[i],
                  onTap: () => context.push('/product/${list[i].id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text(
            'Nie udało się wczytać ofert.\n$e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
