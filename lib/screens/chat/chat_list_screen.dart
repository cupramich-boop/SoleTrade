import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/products_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wiadomości')),
      body: chats.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Brak wiadomości. Napisz do sprzedającej, aby rozpocząć czat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _ChatTile(chat: list[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Błąd wczytywania czatów.\n$e')),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});

  final SoleChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = supabase.auth.currentUser?.id;
    final otherId = chat.buyerId == myId ? chat.sellerId : chat.buyerId;
    final otherProfile = ref.watch(sellerProfileProvider(otherId));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: const Icon(Icons.person, color: AppColors.primary),
      ),
      title: otherProfile.when(
        data: (p) => Text(p.username, style: const TextStyle(fontWeight: FontWeight.w600)),
        loading: () => const Text('...'),
        error: (e, st) => const Text('Użytkownik'),
      ),
      subtitle: const Text('Otwórz, aby zobaczyć wiadomości'),
      onTap: () => context.push('/chat/${chat.id}'),
    );
  }
}
