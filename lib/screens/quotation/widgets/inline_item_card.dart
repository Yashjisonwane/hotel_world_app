import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../models/quotation_item.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';
import '../../../providers/product_provider.dart';

class InlineItemCard extends StatefulWidget {
  final QuotationItem item;
  final int index;
  final bool isMachinery;
  final bool isPhotoMode;
  final String gstMode; // 'WITH_GST', 'WITHOUT_GST'
  final ValueChanged<QuotationItem> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<String> onPhotoZoom;

  const InlineItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.isMachinery,
    required this.isPhotoMode,
    required this.gstMode,
    required this.onChanged,
    required this.onDelete,
    required this.onPhotoZoom,
  });

  @override
  State<InlineItemCard> createState() => _InlineItemCardState();
}

class _InlineItemCardState extends State<InlineItemCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _sectionCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _instCtrl;

  late String _unit;
  late double _gstRate;
  late bool _isGstAdded;
  String? _imageUrl;
  bool _isUploadingPhoto = false;

  // Search / Autocomplete state
  Timer? _debounceTimer;
  List<Product> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _specCtrl = TextEditingController(text: widget.item.specification ?? '');
    _sizeCtrl = TextEditingController(text: widget.item.size ?? '');
    _sectionCtrl = TextEditingController(text: widget.item.section ?? '');
    _qtyCtrl = TextEditingController(text: _formatNumber(widget.item.quantity));
    _priceCtrl = TextEditingController(
      text: widget.item.price > 0 ? widget.item.price.toStringAsFixed(2) : '',
    );
    _instCtrl = TextEditingController(
      text: widget.item.installationCharge > 0 ? widget.item.installationCharge.toStringAsFixed(0) : '',
    );

    _unit = widget.item.unit.isNotEmpty ? widget.item.unit : 'Pcs';
    _gstRate = widget.item.gstRate;
    _isGstAdded = widget.item.isGstAdded;
    _imageUrl = widget.item.imageUrl;

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant InlineItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.name != widget.item.name && _nameCtrl.text != widget.item.name) {
      _nameCtrl.text = widget.item.name;
    }
    if (oldWidget.item.specification != widget.item.specification && _specCtrl.text != (widget.item.specification ?? '')) {
      _specCtrl.text = widget.item.specification ?? '';
    }
    if (oldWidget.item.size != widget.item.size && _sizeCtrl.text != (widget.item.size ?? '')) {
      _sizeCtrl.text = widget.item.size ?? '';
    }
    if (oldWidget.item.section != widget.item.section && _sectionCtrl.text != (widget.item.section ?? '')) {
      _sectionCtrl.text = widget.item.section ?? '';
    }
    if (oldWidget.item.unit != widget.item.unit) {
      _unit = widget.item.unit;
    }
    if (oldWidget.item.gstRate != widget.item.gstRate) {
      _gstRate = widget.item.gstRate;
    }
    if (oldWidget.item.isGstAdded != widget.item.isGstAdded) {
      _isGstAdded = widget.item.isGstAdded;
    }
    if (oldWidget.item.imageUrl != widget.item.imageUrl) {
      _imageUrl = widget.item.imageUrl;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameFocusNode.dispose();
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _sizeCtrl.dispose();
    _sectionCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _instCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  void _notifyChange() {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final inst = double.tryParse(_instCtrl.text.trim()) ?? 0.0;

    final updated = widget.item.copyWith(
      serialNumber: widget.index + 1,
      name: _nameCtrl.text.trim(),
      specification: _specCtrl.text.trim().isNotEmpty ? _specCtrl.text.trim() : null,
      size: _sizeCtrl.text.trim().isNotEmpty ? _sizeCtrl.text.trim() : null,
      section: _sectionCtrl.text.trim().isNotEmpty ? _sectionCtrl.text.trim() : null,
      quantity: qty,
      unit: _unit,
      price: price,
      gstRate: _gstRate,
      isGstAdded: _isGstAdded,
      installationCharge: inst,
      imageUrl: _imageUrl,
    );
    updated.recalculate();
    widget.onChanged(updated);
  }

  void _onNameChanged(String query) {
    _notifyChange();

    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      final qLower = query.toLowerCase().trim();
      final localProducts = context.read<ProductProvider>().products;

      // 1. Search local products
      final localMatches = localProducts.where((p) {
        final name = p.name.toLowerCase();
        final sku = (p.itemCode).toLowerCase();
        final cat = p.category.toLowerCase();
        return name.contains(qLower) || sku.contains(qLower) || cat.contains(qLower);
      }).take(10).toList();

      if (localMatches.isNotEmpty) {
        if (mounted) {
          setState(() {
            _suggestions = localMatches;
            _showSuggestions = true;
          });
        }
      } else {
        // 2. Search online catalog
        try {
          final res = await ApiService().getProducts(search: qLower, limit: 10);
          final onlineMatches = res['products'] as List<Product>;
          if (mounted) {
            setState(() {
              _suggestions = onlineMatches;
              _showSuggestions = onlineMatches.isNotEmpty;
            });
          }
        } catch (_) {}
      }
    });
  }

  void _selectProduct(Product prod) {
    setState(() {
      _nameCtrl.text = prod.name;
      if (prod.sellingPrice > 0) {
        _priceCtrl.text = prod.sellingPrice.toStringAsFixed(2);
      }
      if (prod.unit.isNotEmpty) {
        _unit = prod.unit;
      }
      if (prod.taxRate > 0) {
        _gstRate = prod.taxRate;
      }
      if (prod.specification != null && prod.specification!.isNotEmpty) {
        _specCtrl.text = prod.specification!;
      } else if (prod.description != null && prod.description!.isNotEmpty) {
        _specCtrl.text = prod.description!;
      }
      if (prod.size != null && prod.size!.isNotEmpty) {
        _sizeCtrl.text = prod.size!;
      }
      if (prod.imageUrl != null && prod.imageUrl!.isNotEmpty) {
        _imageUrl = prod.imageUrl;
      }
      _suggestions = [];
      _showSuggestions = false;
    });

    widget.item.productId = prod.id;
    widget.item.sku = prod.itemCode;
    widget.item.category = prod.category;
    widget.item.hsnCode = prod.hsnCode;

    _notifyChange();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final file = File(picked.path);
      final api = ApiService();
      final uploadedUrl = await api.uploadProductPhoto(file);

      setState(() {
        _imageUrl = uploadedUrl ?? picked.path;
        _isUploadingPhoto = false;
      });

      _notifyChange();
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo attach nahi ho saki: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Photos strictly follow the user's toggle: when Photos is OFF, photo section is completely hidden.
    final showPhotoSection = widget.isPhotoMode;
    final rowTotal = widget.item.grossAmount;
    final isWithoutGst = widget.gstMode == 'WITHOUT_GST';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CARD HEADER (Exact matching Screenshot 3):
          // #1 (black badge), Code (if any), + Custom Item (amber badge), Delete (red button)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${widget.index + 1}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (widget.item.sku != null && widget.item.sku!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Code: ${widget.item.sku}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // + Custom Item Button (Screenshot 3)
                    InkWell(
                      onTap: () {
                        widget.item.productId = null;
                        if (_nameCtrl.text.isEmpty) {
                          _nameCtrl.text = 'Custom Product';
                          _notifyChange();
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 10, color: Color(0xFFB45309)),
                            SizedBox(width: 3),
                            Text(
                              '+ Custom Item',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button (Screenshot 3)
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline, size: 13, color: Color(0xFFDC2626)),
                            SizedBox(width: 3),
                            Text(
                              'Delete',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PRODUCT NAME / PARTICULAR
                Text(
                  'PRODUCT NAME / PARTICULAR:',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocusNode,
                  onChanged: _onNameChanged,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search product (Deep Fryer, Tandoor, Bhatti...)',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.search, size: 17, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                  ),
                ),

                // AUTOCOMPLETE DROPDOWN
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2563EB), width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, sIdx) {
                        final prod = _suggestions[sIdx];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            prod.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                          ),
                          subtitle: Text(
                            [
                              if (prod.itemCode.isNotEmpty) prod.itemCode,
                              if (prod.category.isNotEmpty) prod.category,
                            ].join(' • '),
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          trailing: Text(
                            '₹${prod.sellingPrice > 0 ? prod.sellingPrice.toStringAsFixed(0) : "0"}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD97706), fontSize: 12.5),
                          ),
                          onTap: () => _selectProduct(prod),
                        );
                      },
                    ),
                  ),

                // MACHINERY EXTRA FIELDS
                if (widget.isMachinery) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('SECTION:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                        const SizedBox(height: 3),
                        TextField(
                          controller: _sectionCtrl,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => _notifyChange(),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: 'e.g. TANDOOR SECTION',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            isDense: true,
                            fillColor: AppColors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('TECHNICAL SPECIFICATIONS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                        const SizedBox(height: 3),
                        TextField(
                          controller: _specCtrl,
                          maxLines: 2,
                          onChanged: (_) => _notifyChange(),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'SS 304, 18 swg, burner, legs...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            fillColor: AppColors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SIZE / DIMENSIONS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _sizeCtrl,
                                    onChanged: (_) => _notifyChange(),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                    decoration: InputDecoration(
                                      hintText: '36x36x34 HT',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      isDense: true,
                                      fillColor: AppColors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('INSTALLATION (+₹):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _instCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _notifyChange(),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      isDense: true,
                                      fillColor: AppColors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // PHOTO ATTACHMENT STRIP
                if (showPhotoSection) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _imageUrl != null && _imageUrl!.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _imageUrl != null && _imageUrl!.isNotEmpty ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const Center(child: Padding(padding: EdgeInsets.all(4), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => widget.onPhotoZoom(_imageUrl!),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _imageUrl!.startsWith('http')
                                          ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                          : Image.file(File(_imageUrl!), fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Photo Attached ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF15803D))),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF2563EB)),
                                    onPressed: () => _pickAndUploadPhoto(ImageSource.camera),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                                    onPressed: () {
                                      setState(() => _imageUrl = null);
                                      _notifyChange();
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.camera_alt, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text('Product Photo:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                  ),
                                  InkWell(
                                    onTap: () => _pickAndUploadPhoto(ImageSource.camera),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Camera', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _pickAndUploadPhoto(ImageSource.gallery),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Gallery', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],

                const SizedBox(height: 8),

                // 3-COLUMN ROW: QTY | UNIT | UNIT RATE (₹) (Exact matching Screenshot 3)
                Row(
                  children: [
                    // Qty
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QTY:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                          const SizedBox(height: 3),
                          TextField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (_) => _notifyChange(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              isDense: true,
                              fillColor: AppColors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Unit
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UNIT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                          const SizedBox(height: 3),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ['Pcs', 'Box', 'Ltr', 'Kg', 'Gm', 'Dzn', 'Pkt', 'Set', 'Nos', 'Mtr'].contains(_unit) ? _unit : 'Pcs',
                                isExpanded: true,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                items: ['Pcs', 'Box', 'Ltr', 'Kg', 'Gm', 'Dzn', 'Pkt', 'Set', 'Nos', 'Mtr']
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _unit = val);
                                    _notifyChange();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Unit Rate (₹)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UNIT RATE (₹):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                          const SizedBox(height: 3),
                          TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            onChanged: (_) => _notifyChange(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                              fillColor: AppColors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ROW TOTAL BOX (Screenshot 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Optional GST rate selector if not without GST
                      if (!isWithoutGst)
                        Row(
                          children: [
                            const Text('GST: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: [0.0, 5.0, 12.0, 18.0, 28.0].contains(_gstRate) ? _gstRate : 18.0,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                items: [0.0, 5.0, 12.0, 18.0, 28.0]
                                    .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%')))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _gstRate = val);
                                    _notifyChange();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() => _isGstAdded = !_isGstAdded);
                                _notifyChange();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isGstAdded ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _isGstAdded ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  _isGstAdded ? '✓ Added' : '👁️ Show',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isGstAdded ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Row Total Value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Row Total:', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          Text(
                            '₹ ${rowTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
