import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../models/product.dart';
import '../../services/pricing_engine.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';

class SelectProductModal extends StatefulWidget {
  final Function(Product product, double quantity, double price) onProductSelected;

  const SelectProductModal({super.key, required this.onProductSelected});

  @override
  State<SelectProductModal> createState() => _SelectProductModalState();
}

class _SelectProductModalState extends State<SelectProductModal> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<ProductProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ProductProvider>().search(query);
    });
  }

  void _showAddDetailsSheet(Product product) {
    double qty = 1.0;
    double price = product.sellingPrice;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: product.sellingPrice > 0 ? product.sellingPrice.toStringAsFixed(2) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (product.itemCode.isNotEmpty)
                Text('Code: ${product.itemCode} | Unit: ${product.unit}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      onChanged: (val) => qty = double.tryParse(val) ?? 1.0,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
                      onChanged: (val) => price = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onProductSelected(product, qty, price);
                    Navigator.pop(context);
                  },
                  child: const Text('Add to Quotation'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final backendUrl = settingsProv.backendUrl;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Product from Catalog',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search 7,900+ products by name, code...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Category horizontal scroll
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: prodProv.categories.length,
              itemBuilder: (ctx, idx) {
                final cat = prodProv.categories[idx];
                final isSelected = prodProv.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary500,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.slate950 : AppColors.slate700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) prodProv.setCategory(cat);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Product Results
          Expanded(
            child: prodProv.isLoading && prodProv.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : prodProv.products.isEmpty
                    ? const Center(
                        child: Text('No products found matching your search.'),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: prodProv.products.length + (prodProv.isLoading ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          if (idx >= prodProv.products.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.primary500),
                              ),
                            );
                          }
                          final p = prodProv.products[idx];
                          final imgUrl = ApiConstants.resolveImageUrl(p.imageUrl, backendUrl);

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.slate100,
                                  child: imgUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imgUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => const Icon(
                                            Icons.camera_alt_outlined,
                                            color: AppColors.slate400,
                                            size: 20,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_outlined,
                                          color: AppColors.slate400,
                                          size: 20,
                                        ),
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${p.itemCode.isNotEmpty ? "Code: ${p.itemCode} • " : ""}${p.category}',
                                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    PricingEngine.formatCurrency(p.sellingPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  Text(
                                    '/${p.unit}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                              onTap: () => _showAddDetailsSheet(p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

