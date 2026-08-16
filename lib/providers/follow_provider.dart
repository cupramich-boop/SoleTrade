import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../models/profile.dart';

/// Id sprzedających, których obserwuje zalogowany użytkownik.
final followingIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return {};
  final data = await supabase
      .from('follows')
      .select('followed_id')
      .eq('follower_id', userId);
  return (data as List).map((e) => e['followed_id'] as String).toSet();
});

/// Pełne profile obserwowanych sprzedających (zakładka "Obserwowani").
final followedSellersProvider = FutureProvider<List<Profile>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('follows')
      .select('profiles!follows_followed_id_fkey(*)')
      .eq('follower_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => Profile.fromJson(e['profiles'] as Map<String, dynamic>))
      .toList();
});

class FollowController {
  Future<void> follow(String sellerId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Musisz być zalogowana, aby obserwować sprzedających.');
    }
    await supabase.from('follows').insert({
      'follower_id': userId,
      'followed_id': sellerId,
    });
  }

  Future<void> unfollow(String sellerId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('followed_id', sellerId);
  }
}

final followControllerProvider = Provider((ref) => FollowController());
