import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/categories_provider.dart';
import '../../providers/products_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController(text: '1');

  String? _categoryId;
  final List<XFile> _pickedImages = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _sizeCtrl.dispose();
    _materialCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() => _pickedImages.addAll(images));
    }
  }

  Future<List<String>> _uploadImages() async {
    final userId = supabase.auth.currentUser!.id;
    final urls = <String>[];

    for (final image in _pickedImages) {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final path =
          '$userId/${DateTime.now().microsecondsSinceEpoch}.$ext';

      await supabase.storage
          .from('product-images')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      urls.add(supabase.storage.from('product-images').getPublicUrl(path));
    }

    return urls;
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Uzupełnij tytuł i cenę oferty.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final imageUrls = await _uploadImages();
      await ref
          .read(productsControllerProvider)
          .createProduct(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
            conditionDays: int.tryParse(_conditionCtrl.text) ?? 1,
            size: _sizeCtrl.text.trim(),
            material: _materialCtrl.text.trim(),
            categoryId: _categoryId,
            imageUrls: imageUrls,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oferta wysłana do moderacji.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Nie udało się dodać oferty. $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj ofertę')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Zdjęcia',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._pickedImages.map(
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
                  child: TextField(
                    controller: _conditionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Używane (dni)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeCtrl,
                    decoration: const InputDecoration(labelText: 'Rozmiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _materialCtrl,
                    decoration: const InputDecoration(labelText: 'Materiał'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            categories.when(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategoria'),
                items: list
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
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
                  : const Text('Wystaw ofertę'),
            ),
          ],
        ),
      ),
    );
  }
}
