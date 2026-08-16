import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

const _productSelect = '*, product_images(*)';

/// Oferty oznaczone przez moderatora jako "Polecane".
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('status', 'active')
      .eq('is_featured', true)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Wszystkie aktywne oferty — pełny przegląd/wyszukiwanie.
final activeProductsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('status', 'active')
      .order('created_at', ascending: false);
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

/// Aktywne oferty należące do danej kategorii (ekran "Kategoria").
final categoryProductsProvider = FutureProvider.family<List<Product>, SoleCategory>((
  ref,
  category,
) async {
  final data = await supabase
      .from('products')
      .select(_productSelect)
      .eq('status', 'active')
      .eq('category_id', category.id)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

final myProductsProvider = FutureProvider<List<Product>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
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

  /// Aktualizuje pola oferty. Sprzedawca może edytować tylko swoją ofertę
  /// (wymuszone przez RLS) — edycja cofa ją do statusu "pending".
  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required int conditionDays,
    required String size,
    required String material,
    required String? categoryId,
  }) async {
    await supabase
        .from('products')
        .update({
          'title': title,
          'description': description,
          'price': price,
          'condition_days': conditionDays,
          'size': size,
          'material': material,
          'category_id': categoryId,
          'status': 'pending',
        })
        .eq('id', productId);
  }

  Future<void> addImage({
    required String productId,
    required String imageUrl,
    required bool isMain,
  }) async {
    if (isMain) {
      await supabase
          .from('product_images')
          .update({'is_main': false})
          .eq('product_id', productId);
    }
    await supabase.from('product_images').insert({
      'product_id': productId,
      'image_url': imageUrl,
      'is_main': isMain,
    });
  }

  Future<void> setMainImage({
    required String productId,
    required String imageId,
  }) async {
    await supabase
        .from('product_images')
        .update({'is_main': false})
        .eq('product_id', productId);
    await supabase
        .from('product_images')
        .update({'is_main': true})
        .eq('id', imageId);
  }

  Future<void> deleteImage(String imageId) async {
    await supabase.from('product_images').delete().eq('id', imageId);
  }
}

final productsControllerProvider = Provider((ref) => ProductsController());
