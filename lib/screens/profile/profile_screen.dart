import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/products_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = supabase.auth.currentUser?.id;
    final myProfile = userId == null
        ? null
        : ref.watch(sellerProfileProvider(userId));
    final myProducts = ref.watch(myProductsProvider);
    final followedSellers = ref.watch(followedSellersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ProfileHeader(myProfile: myProfile, ref: ref),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                const TabBar(
                  tabs: [
                    Tab(text: 'Moje oferty'),
                    Tab(text: 'Obserwowani'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _MyProductsTab(myProducts: myProducts),
              _FollowedSellersTab(followedSellers: followedSellers),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.myProfile, required this.ref});

  final AsyncValue<Profile>? myProfile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (myProfile == null) return const SizedBox.shrink();

    return myProfile!.when(
      data: (profile) => Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: profile.avatarUrl != null
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.star),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '${profile.ratingScore.toStringAsFixed(1)} · ${profile.totalSold} sprzedanych',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider).signOut(),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Wyloguj'),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _MyProductsTab extends StatelessWidget {
  const _MyProductsTab({required this.myProducts});

  final AsyncValue<List<dynamic>> myProducts;

  @override
  Widget build(BuildContext context) {
    return myProducts.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'Nie masz jeszcze żadnych ofert.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                title: Text(p.title as String),
                subtitle: Text(
                  '${(p.price as double).toStringAsFixed(0)} zł · ${p.status.name}',
                ),
                onTap: () => context.push('/product/${p.id}'),
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
    );
  }
}

class _FollowedSellersTab extends StatelessWidget {
  const _FollowedSellersTab({required this.followedSellers});

  final AsyncValue<List<Profile>> followedSellers;

  @override
  Widget build(BuildContext context) {
    return followedSellers.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'Nie obserwujesz jeszcze żadnych sprzedających.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final seller = list[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: seller.avatarUrl != null
                      ? CachedNetworkImageProvider(seller.avatarUrl!)
                      : null,
                  child: seller.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                title: Text(seller.username),
                subtitle: Text(
                  '${seller.ratingScore.toStringAsFixed(1)} · ${seller.totalSold} sprzedanych',
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(
          'Nie udało się wczytać obserwowanych.\n$e',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: AppColors.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
