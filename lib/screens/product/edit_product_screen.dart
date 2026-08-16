import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/constants/product_options.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/categories_provider.dart';
import '../../providers/products_provider.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final _titleCtrl = TextEditingController(text: widget.product.title);
  late final _descCtrl = TextEditingController(
    text: widget.product.description,
  );
  late final _priceCtrl = TextEditingController(
    text: widget.product.price.toStringAsFixed(0),
  );

  late String? _size = widget.product.size.isEmpty ? null : widget.product.size;
  late String? _material =
      widget.product.material.isEmpty ? null : widget.product.material;
  late int _conditionDays = widget.product.conditionDays;
  late String? _categoryId = widget.product.categoryId;
  late final List<ProductImage> _existingImages = List.of(
    widget.product.images,
  );
  final List<XFile> _newImages = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  static const _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };
  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
  };

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 75);
    if (images.isEmpty) return;

    final valid = <XFile>[];
    var rejected = 0;
    for (final image in images) {
      final ext = image.name.split('.').last.toLowerCase();
      if (_allowedExtensions.contains(ext)) {
        valid.add(image);
      } else {
        rejected++;
      }
    }

    if (rejected > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rejected == 1
                ? 'Pominięto 1 plik — obsługiwane są tylko zdjęcia JPG, PNG i WEBP.'
                : 'Pominięto $rejected plików — obsługiwane są tylko zdjęcia JPG, PNG i WEBP.',
          ),
        ),
      );
    }

    if (valid.isNotEmpty) {
      setState(() => _newImages.addAll(valid));
    }
  }

  Future<void> _removeExistingImage(ProductImage image) async {
    setState(() => _existingImages.remove(image));
    await ref.read(productsControllerProvider).deleteImage(image.id);
  }

  Future<void> _setCover(ProductImage image) async {
    setState(() {
      _existingImages
        ..clear()
        ..addAll(
          _existingImages.map(
            (i) => ProductImage(
              id: i.id,
              productId: i.productId,
              imageUrl: i.imageUrl,
              isMain: i.id == image.id,
            ),
          ),
        );
    });
    await ref
        .read(productsControllerProvider)
        .setMainImage(productId: widget.product.id, imageId: image.id);
  }

  Future<void> _uploadNewImages() async {
    final userId = supabase.auth.currentUser!.id;
    final hasCover = _existingImages.any((i) => i.isMain);

    for (var i = 0; i < _newImages.length; i++) {
      final image = _newImages[i];
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$ext';

      await supabase.storage
          .from('product-images')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypes[ext],
            ),
          );

      final url = supabase.storage.from('product-images').getPublicUrl(path);
      await ref
          .read(productsControllerProvider)
          .addImage(
            productId: widget.product.id,
            imageUrl: url,
            isMain: !hasCover && i == 0,
          );
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _size == null ||
        _material == null) {
      setState(() => _error = 'Uzupełnij tytuł, cenę, rozmiar i materiał.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _uploadNewImages();
      await ref
          .read(productsControllerProvider)
          .updateProduct(
            productId: widget.product.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
            conditionDays: _conditionDays,
            size: _size!,
            material: _material!,
            categoryId: _categoryId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zapisano zmiany. Oferta wraca do moderacji.'),
          ),
        );
        ref.invalidate(myProductsProvider);
        ref.invalidate(productDetailProvider(widget.product.id));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      setState(() => _error = 'Nie udało się zapisać zmian. $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj ofertę')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Zdjęcia', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingImages.map(
                    (img) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: img.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        Container(color: AppColors.primaryLight),
                                  ),
                                  if (img.isMain)
                                    Positioned(
                                      left: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Okładka',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(img),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          if (!img.isMain)
                            Positioned(
                              left: 2,
                              bottom: 2,
                              child: GestureDetector(
                                onTap: () => _setCover(img),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star_outline,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ..._newImages.map(
                    (img) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: FutureBuilder<Uint8List>(
                            future: img.readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(color: AppColors.primaryLight);
                              }
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tytuł oferty'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Opis'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cena (zł)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _conditionDays,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Używane (dni)',
                    ),
                    items: ProductOptions.conditionDaysOptions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              ProductOptions.conditionDaysLabel(d),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _conditionDays = v ?? _conditionDays),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _size,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rozmiar'),
                    items: ProductOptions.sizes
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _size = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _material,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Materiał'),
                    items: ProductOptions.materials
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _material = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            categories.when(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategoria'),
                items: list
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
