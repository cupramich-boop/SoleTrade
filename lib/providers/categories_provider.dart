import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../models/category.dart';

final categoriesProvider = FutureProvider<List<SoleCategory>>((ref) async {
  final data = await supabase.from('categories').select().order('name');
  return (data as List)
      .map((e) => SoleCategory.fromJson(e as Map<String, dynamic>))
      .toList();
});
