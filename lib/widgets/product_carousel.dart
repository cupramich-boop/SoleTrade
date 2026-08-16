import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import 'product_card.dart';
import 'snap_scroll_physics.dart';

/// Pozioma karuzela produktów z przyciąganiem do karty i kropkami postępu.
class ProductCarousel extends StatefulWidget {
  const ProductCarousel({
    super.key,
    required this.products,
    required this.onTap,
  });

  final List<Product> products;
  final void Function(Product product) onTap;

  static const double cardWidth = 168;
  static const double cardHeight = 250;
  static const double spacing = 14;

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final _controller = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    const itemExtent = ProductCarousel.cardWidth + ProductCarousel.spacing;
    final index = (_controller.offset / itemExtent).round().clamp(
      0,
      widget.products.length - 1,
    );
    if (index != _activeIndex) setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final showDots = widget.products.length > 1 && widget.products.length <= 10;

    return Column(
      children: [
        SizedBox(
          height: ProductCarousel.cardHeight,
          child: ListView.separated(
            controller: _controller,
            physics: const SnapScrollPhysics(
              itemExtent: ProductCarousel.cardWidth + ProductCarousel.spacing,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: widget.products.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: ProductCarousel.spacing),
            itemBuilder: (context, i) {
              final product = widget.products[i];
              return SizedBox(
                width: ProductCarousel.cardWidth,
                child: ProductCard(
                  product: product,
                  onTap: () => widget.onTap(product),
                ),
              );
            },
          ),
        ),
        if (showDots) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.products.length, (i) {
              final active = i == _activeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
