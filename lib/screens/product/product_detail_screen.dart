import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/profile.dart';
import '../../providers/chat_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/info_tag.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;
  bool _startingChat = false;

  Future<void> _messageSeller(Product product) async {
    setState(() => _startingChat = true);
    try {
      final chatId = await ref
          .read(chatControllerProvider)
          .getOrCreateChat(sellerId: product.sellerId, productId: product.id);
      if (mounted) context.push('/chat/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  void _openFullscreenGallery(BuildContext context, List<ProductImage> images) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenGallery(images: images, initialIndex: _imageIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        data: (product) => _buildBody(context, product),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Nie znaleziono oferty.\n$e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Product product) {
    final images = product.images;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: images.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _openFullscreenGallery(context, images),
                              child: PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (i) =>
                                    setState(() => _imageIndex = i),
                                itemBuilder: (context, i) => CachedNetworkImage(
                                  imageUrl: images[i].imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: AppColors.primaryLight),
                                ),
                              ),
                            )
                          : Container(color: AppColors.primaryLight),
                    ),
                    Positioned(
                      top: 44,
                      left: 16,
                      child: _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                    ),
                    Positioned(
                      top: 44,
                      right: 16,
                      child: _CircleButton(
                        icon: Icons.more_vert,
                        onTap: () {},
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_imageIndex + 1} / ${images.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.favorite_border,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${product.price.toStringAsFixed(0)} zł',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoTag(
                            icon: Icons.calendar_today_outlined,
                            label: 'Używane ${product.conditionDays} dni',
                          ),
                          InfoTag(
                            icon: Icons.straighten_outlined,
                            label: 'Rozmiar ${product.size}',
                          ),
                          InfoTag(
                            icon: Icons.grain_outlined,
                            label: product.material,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Opis',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'O sprzedającej',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SellerRow(sellerId: product.sellerId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} zł',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _startingChat ||
                            supabase.auth.currentUser?.id == product.sellerId
                        ? null
                        : () => _messageSeller(product),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(
                      supabase.auth.currentUser?.id == product.sellerId
                          ? 'To Twoja oferta'
                          : (_startingChat
                                ? 'Otwieranie...'
                                : 'Napisz do sprzedającej'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initialIndex});

  final List<ProductImage> images;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i].imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _CircleButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SellerRow extends ConsumerStatefulWidget {
  const _SellerRow({required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<_SellerRow> createState() => _SellerRowState();
}

class _SellerRowState extends ConsumerState<_SellerRow> {
  bool _updating = false;

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    setState(() => _updating = true);
    try {
      final controller = ref.read(followControllerProvider);
      if (currentlyFollowing) {
        await controller.unfollow(widget.sellerId);
      } else {
        await controller.follow(widget.sellerId);
      }
      ref.invalidate(followingIdsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider(widget.sellerId));
    final followingAsync = ref.watch(followingIdsProvider);
    final isOwnProfile = supabase.auth.currentUser?.id == widget.sellerId;

    return sellerAsync.when(
      data: (seller) => _content(seller, isOwnProfile, followingAsync),
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _content(
    Profile seller,
    bool isOwnProfile,
    AsyncValue<Set<String>> followingAsync,
  ) {
    final isFollowing = followingAsync.value?.contains(widget.sellerId) ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: seller.avatarUrl != null
              ? CachedNetworkImageProvider(seller.avatarUrl!)
              : null,
          child: seller.avatarUrl == null
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      seller.username,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 15, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.star),
                  const SizedBox(width: 2),
                  Text(
                    '${seller.ratingScore.toStringAsFixed(1)} (${seller.totalSold})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${seller.totalSold}+ sprzedanych',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isOwnProfile) ...[
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _updating ? null : () => _toggleFollow(isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? AppColors.primaryLight
                    : AppColors.primary,
                foregroundColor: isFollowing
                    ? AppColors.primary
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _updating
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isFollowing ? 'Obserwujesz' : 'Obserwuj'),
            ),
          ),
        ],
      ],
    );
  }
}
