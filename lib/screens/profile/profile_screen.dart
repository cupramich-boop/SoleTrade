import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (myProfile != null)
            myProfile.when(
              data: (profile) => Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: profile.avatarUrl != null
                        ? CachedNetworkImageProvider(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 32,
                          )
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
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.star,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${profile.ratingScore.toStringAsFixed(1)} · ${profile.totalSold} sprzedanych',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => const SizedBox.shrink(),
            ),
          const SizedBox(height: 28),
          const Text(
            'Moje oferty',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          myProducts.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text(
                  'Nie masz jeszcze żadnych ofert.',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Column(
                children: list
                    .map(
                      (p) => Card(
                        child: ListTile(
                          title: Text(p.title),
                          subtitle: Text('${p.price.toStringAsFixed(0)} zł · ${p.status.name}'),
                          onTap: () => context.push('/product/${p.id}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Wyloguj się'),
          ),
        ],
      ),
    );
  }
}
