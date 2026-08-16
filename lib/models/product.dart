enum ProductStatus { pending, active, sold, rejected }

ProductStatus productStatusFromString(String value) {
  return ProductStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ProductStatus.pending,
  );
}

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final bool isMain;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.isMain = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    imageUrl: json['image_url'] as String,
    isMain: json['is_main'] as bool? ?? false,
  );
}

class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String description;
  final double price;
  final int conditionDays;
  final String size;
  final String material;
  final ProductStatus status;
  final List<ProductImage> images;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.conditionDays,
    required this.size,
    required this.material,
    required this.status,
    this.images = const [],
    this.createdAt,
  });

  String get mainImageUrl {
    if (images.isEmpty) return '';
    final main = images.where((i) => i.isMain).toList();
    return main.isNotEmpty ? main.first.imageUrl : images.first.imageUrl;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['product_images'] as List<dynamic>? ?? [];
    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      conditionDays: json['condition_days'] as int? ?? 0,
      size: json['size'] as String? ?? '',
      material: json['material'] as String? ?? '',
      status: productStatusFromString(json['status'] as String? ?? 'pending'),
      images: rawImages
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
