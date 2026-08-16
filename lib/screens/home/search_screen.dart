import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/product_options.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/categories_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();

  String? _size;
  String? _material;
  int? _conditionDays;
  String? _categoryId;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount => [
    _size,
    _material,
    _conditionDays,
    _categoryId,
  ].where((v) => v != null).length;

  void _clearFilters() {
    setState(() {
      _size = null;
      _material = null;
      _conditionDays = null;
      _categoryId = null;
    });
  }

  Future<void> _openFilters() async {
    final categories = await ref.read(categoriesProvider.future);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtry',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _size = null;
                            _material = null;
                            _conditionDays = null;
                            _categoryId = null;
                          });
                        },
                        child: const Text('Wyczyść'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategoria'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      ...categories.map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _size,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rozmiar'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      ...ProductOptions.sizes.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => _size = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _material,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Materiał'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      ...ProductOptions.materials.map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => _material = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _conditionDays,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Używane (dni)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      ...ProductOptions.conditionDaysOptions.map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(ProductOptions.conditionDaysLabel(d)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => _conditionDays = v),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Pokaż wyniki'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryCtrl,
          decoration: const InputDecoration(
            hintText: 'Szukaj ofert...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _openFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        data: (list) {
          final query = _queryCtrl.text.trim().toLowerCase();
          final filtered = list.where((p) {
            if (query.isNotEmpty && !p.title.toLowerCase().contains(query)) {
              return false;
            }
            if (_size != null && p.size != _size) return false;
            if (_material != null && p.material != _material) return false;
            if (_conditionDays != null && p.conditionDays != _conditionDays) {
              return false;
            }
            if (_categoryId != null && p.categoryId != _categoryId) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Column(
              children: [
                if (_activeFilterCount > 0) _FilterBar(
                  count: _activeFilterCount,
                  onClear: _clearFilters,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Brak wyników.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              if (_activeFilterCount > 0)
                _FilterBar(count: _activeFilterCount, onClear: _clearFilters),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = switch (constraints.maxWidth) {
                      < 520 => 2,
                      < 820 => 3,
                      < 1120 => 4,
                      _ => 5,
                    };
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, i) => ProductCard(
                        product: filtered[i],
                        onTap: () => context.push('/product/${filtered[i].id}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Błąd wyszukiwania.\n$e')),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            'Aktywne filtry: $count',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Wyczyść')),
        ],
      ),
    );
  }
}
