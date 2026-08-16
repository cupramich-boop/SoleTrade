import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../models/chat.dart';
import 'auth_provider.dart';

/// Lista czatów zalogowanego użytkownika (jako kupujący lub sprzedający).
final myChatsProvider = FutureProvider<List<SoleChat>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('chats')
      .select('*, products(title)')
      .or('buyer_id.eq.$userId,seller_id.eq.$userId')
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => SoleChat.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Realtime strumień wiadomości dla danego czatu.
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  chatId,
) {
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());
});

class ChatController {
  /// Znajduje istniejący czat kupujący↔sprzedawca dla oferty, albo tworzy nowy.
  Future<String> getOrCreateChat({
    required String sellerId,
    required String productId,
  }) async {
    final buyerId = supabase.auth.currentUser?.id;
    if (buyerId == null) {
      throw StateError('Musisz być zalogowana, aby napisać do sprzedającej.');
    }
    if (buyerId == sellerId) {
      throw StateError('To Twoja własna oferta.');
    }

    final existing = await supabase
        .from('chats')
        .select()
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await supabase
        .from('chats')
        .insert({
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'product_id': productId,
        })
        .select()
        .single();

    return created['id'] as String;
  }

  Future<void> sendMessage({required String chatId, required String text}) async {
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) return;
    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
    });
  }
}

final chatControllerProvider = Provider((ref) => ChatController());
