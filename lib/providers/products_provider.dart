import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../models/product.dart';
import '../models/profile.dart';

const _productSelect = '*, product_images(*)';

/// Aktywne, polecane oferty na stronę główną.
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Najnowsze aktywne oferty (osobna karuzela na stronie głównej).
final newestProductsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(12);
  return (data as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  productId,
) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('id', productId)
      .single();
  return Product.fromJson(data);
});

final sellerProfileProvider = FutureProvider.family<Profile, String>((
  ref,
  sellerId,
) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', sellerId)
      .single();
  return Profile.fromJson(data);
});

final myProductsProvider = FutureProvider<List<Product>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('seller_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ProductsController {
  Future<String> createProduct({
    required String title,
    required String description,
    required double price,
    required int conditionDays,
    required String size,
    required String material,
    required String? categoryId,
    required List<String> imageUrls,
  }) async {
    final sellerId = supabase.auth.currentUser?.id;
    if (sellerId == null) {
      throw StateError('Musisz być zalogowana, aby dodać ofertę.');
    }

    final inserted = await supabase
        .from('products')
        .insert({
          'seller_id': sellerId,
          'category_id': categoryId,
          'title': title,
          'description': description,
          'price': price,
          'condition_days': conditionDays,
          'size': size,
          'material': material,
          'status': 'pending',
        })
        .select()
        .single();

    final productId = inserted['id'] as String;

    if (imageUrls.isNotEmpty) {
      await supabase.from('product_images').insert([
        for (var i = 0; i < imageUrls.length; i++)
          {
            'product_id': productId,
            'image_url': imageUrls[i],
            'is_main': i == 0,
          },
      ]);
    }

    return productId;
  }
}

final productsControllerProvider = Provider((ref) => ProductsController());
