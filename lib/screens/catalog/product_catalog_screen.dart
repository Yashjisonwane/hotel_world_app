import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../models/product.dart';
import '../../services/pricing_engine.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        context.read<ProductProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ProductProvider>().search(query);
    });
  }

  void _showPricingCalculatorSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        int selectedRule = 1;
        // Rule 1 inputs
        double r1Multiplier = 30.0;
        double r1Margin = 15.0;
        // Rule 2 inputs
        double r2BuyDisc = 50.0;
        double r2SellDisc = 10.0;
        // Rule 3 inputs
        double r3CompDisc = 50.0;
        double r3Gst = 5.0;
        double r3Freight = 6.0;
        double r3Margin = 15.0;

        return StatefulBuilder(
          builder: (sCtx, setModalState) {
            Map<String, dynamic> calcResult;
            if (selectedRule == 1) {
              calcResult = PricingEngine.calculateRule1(
                code: product.itemCode,
                multiplier: r1Multiplier,
                marginRate: r1Margin,
              );
            } else if (selectedRule == 2) {
              calcResult = PricingEngine.calculateRule2(
                mrp: product.mrp ?? product.sellingPrice,
                buyingDiscount: r2BuyDisc,
                sellingDiscount: r2SellDisc,
              );
            } else {
              calcResult = PricingEngine.calculateRule3(
                mrp: product.mrp ?? product.sellingPrice,
                companyDiscount: r3CompDisc,
                gstRate: r3Gst,
                freightRate: r3Freight,
                marginRate: r3Margin,
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pricing Engine Calculator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate700)),
                    Text('Item Code: ${product.itemCode} | MRP: ₹${product.mrp ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                    const SizedBox(height: 14),

                    // Rule selector
                    Row(
                      children: [
                        _buildRuleTab(1, 'Rule 1 (Code)', selectedRule, () => setModalState(() => selectedRule = 1)),
                        const SizedBox(width: 6),
                        _buildRuleTab(2, 'Rule 2 (MRP)', selectedRule, () => setModalState(() => selectedRule = 2)),
                        const SizedBox(width: 6),
                        _buildRuleTab(3, 'Rule 3 (Co.)', selectedRule, () => setModalState(() => selectedRule = 3)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (selectedRule == 1) ...[
                      Text('Multiplier: ${r1Multiplier.toInt()}'),
                      Slider(
                        value: r1Multiplier,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r1Multiplier = v),
                      ),
                      Text('Margin %: ${r1Margin.toInt()}%'),
                      Slider(
                        value: r1Margin,
                        min: 0,
                        max: 40,
                        divisions: 40,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r1Margin = v),
                      ),
                    ] else if (selectedRule == 2) ...[
                      Text('Buying Discount %: ${r2BuyDisc.toInt()}%'),
                      Slider(
                        value: r2BuyDisc,
                        min: 10,
                        max: 70,
                        divisions: 60,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r2BuyDisc = v),
                      ),
                      Text('Selling Discount %: ${r2SellDisc.toInt()}%'),
                      Slider(
                        value: r2SellDisc,
                        min: 0,
                        max: 40,
                        divisions: 40,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r2SellDisc = v),
                      ),
                    ] else ...[
                      Text('Company Discount %: ${r3CompDisc.toInt()}%'),
                      Slider(
                        value: r3CompDisc,
                        min: 10,
                        max: 70,
                        divisions: 60,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r3CompDisc = v),
                      ),
                      Text('Margin %: ${r3Margin.toInt()}%'),
                      Slider(
                        value: r3Margin,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        activeColor: AppColors.primary500,
                        onChanged: (v) => setModalState(() => r3Margin = v),
                      ),
                    ],

                    const SizedBox(height: 14),
                    // Result box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate950,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            calcResult['summary'] ?? '',
                            style: const TextStyle(color: AppColors.slate300, fontSize: 12),
                          ),
                          const Divider(color: AppColors.slate700, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Buying Cost (Cost)', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                                  Text(PricingEngine.formatCurrency((calcResult['buyingPrice'] as num?)?.toDouble() ?? 0.0),
                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Selling Rate (Final)', style: TextStyle(color: AppColors.primary400, fontSize: 11)),
                                  Text(PricingEngine.formatCurrency((calcResult['sellingPrice'] as num?)?.toDouble() ?? 0.0),
                                      style: const TextStyle(color: AppColors.primary400, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRuleTab(int ruleNum, String label, int current, VoidCallback onTap) {
    final isSelected = ruleNum == current;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary500 : AppColors.slate100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.slate950 : AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditProductModal({Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final codeCtrl = TextEditingController(text: product?.itemCode ?? '');
    final priceCtrl = TextEditingController(text: product != null && product.sellingPrice > 0 ? product.sellingPrice.toStringAsFixed(2) : '');
    final mrpCtrl = TextEditingController(text: product?.mrp != null ? product!.mrp!.toStringAsFixed(2) : '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    String category = product?.category ?? 'General';
    String unit = product?.unit ?? 'Pcs';
    double taxRate = product?.taxRate ?? 18.0;
    File? selectedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setMState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product != null ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Photo selector
                    Center(
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (picked != null) {
                            setMState(() => selectedPhoto = File(picked.path));
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate300),
                          ),
                          child: selectedPhoto != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedPhoto!, fit: BoxFit.cover))
                              : const Icon(Icons.add_a_photo, color: AppColors.slate500, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Item Code / SKU'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling Price (₹) *'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: mrpCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'MRP (₹)'))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: ['Pcs', 'Set', 'Nos', 'Kg', 'Mtr', 'Box', 'Pair'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => unit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text) ?? 0.0;
                          if (name.isEmpty) return;

                          final success = await context.read<ProductProvider>().saveProduct(
                                id: product?.id,
                                name: name,
                                itemCode: codeCtrl.text.trim(),
                                category: category,
                                sellingPrice: price,
                                mrp: double.tryParse(mrpCtrl.text),
                                unit: unit,
                                taxRate: taxRate,
                                description: descCtrl.text.trim(),
                                photoFile: selectedPhoto,
                              );
                          if (success && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product successfully save ho gaya!'), backgroundColor: AppColors.success),
                            );
                          }
                        },
                        child: Text(product != null ? 'Update Product' : 'Add to Catalog'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final backendUrl = settingsProv.backendUrl;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // NO HAMBURGER SIDEBAR
        title: const Text('PRODUCT CATALOG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prodProv.fetchProducts(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Category Filter
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search 7,900+ products by name, code...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prodProv.categories.length,
                    itemBuilder: (ctx, idx) {
                      final cat = prodProv.categories[idx];
                      final isSelected = prodProv.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.primary500,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.slate950 : AppColors.slate700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            if (val) prodProv.setCategory(cat);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Products List
          Expanded(
            child: prodProv.isLoading && prodProv.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : prodProv.products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : RefreshIndicator(
                        onRefresh: () => prodProv.fetchProducts(refresh: true),
                        child: ListView.separated(
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
                                    width: 50,
                                    height: 50,
                                    color: AppColors.slate100,
                                    child: imgUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imgUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(
                                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(
                                  '${p.itemCode.isNotEmpty ? "Code: ${p.itemCode} • " : ""}${p.category}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          PricingEngine.formatCurrency(p.sellingPrice),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text('/${p.unit}', style: const TextStyle(fontSize: 10, color: AppColors.slate500)),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calculate_outlined, color: AppColors.primary700, size: 20),
                                      tooltip: 'Pricing Engine Calculator',
                                      onPressed: () => _showPricingCalculatorSheet(p),
                                    ),
                                    if (auth.isAdmin || auth.canManageCatalog)
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showAddEditProductModal(product: p);
                                          } else if (val == 'delete') {
                                            prodProv.deleteProduct(p.id);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: (auth.isAdmin || auth.canManageCatalog)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary500,
              foregroundColor: AppColors.slate950,
              icon: const Icon(Icons.add),
              label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddEditProductModal(),
            )
          : null,
    );
  }
}

