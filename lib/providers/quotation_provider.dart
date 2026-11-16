import 'package:flutter/material.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class QuotationProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Quotation> _quotations = [];
  bool _isLoading = false;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  // Active quotation state (for creating or editing)
  String? _editingQuotationId;
  String _quotationNumber = '';
  DateTime _quotationDate = DateTime.now();
  String? _customerId;
  String _customerName = 'Walk-in Customer';
  String _customerPhone = '';
  String _customerEmail = '';
  String _customerAddress = '';
  String _customerGstin = '';
  String _presentationMode = 'STANDARD';
  String _quotationType = 'STANDARD'; // 'STANDARD' or 'MACHINERY'
  String _documentTitle = 'QUOTATION';
  String? _preparedBy;
  String? _rateGivenBy;
  String _gstMode = 'WITH_GST'; // 'WITH_GST' or 'WITHOUT_GST'

  List<QuotationItem> _items = [];
  double _packingCharges = 0.0;
  double _deliveryCharges = 0.0;
  double _previousCharges = 0.0;
  String _packingChargeLabel = 'PACKING CHARGES';
  String _deliveryChargeLabel = 'DELIVERY CHARGES';
  String _previousChargeLabel = 'PREVIOUS CHARGES';
  double _overallDiscount = 0.0;

  QuotationProvider(this._apiService) {
    fetchQuotations(refresh: true);
  }

  // Getters
  List<Quotation> get quotations => _quotations;
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;

  void addItem(QuotationItem item) {
    _items.add(item);
    notifyListeners();
  }

  // Active Quotation Getters
  String? get editingQuotationId => _editingQuotationId;
  String get quotationNumber => _quotationNumber;
  DateTime get quotationDate => _quotationDate;
  String? get customerId => _customerId;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get customerEmail => _customerEmail;
  String get customerAddress => _customerAddress;
  String get customerGstin => _customerGstin;
  String get presentationMode => _presentationMode;
  String get quotationType => _quotationType;
  String get documentTitle => _documentTitle;
  String? get preparedBy => _preparedBy;
  String? get rateGivenBy => _rateGivenBy;
  String get gstMode => _gstMode;

  List<QuotationItem> get items => _items;
  double get packingCharges => _packingCharges;
  double get deliveryCharges => _deliveryCharges;
  double get previousCharges => _previousCharges;
  String get packingChargeLabel => _packingChargeLabel;
  String get deliveryChargeLabel => _deliveryChargeLabel;
  String get previousChargeLabel => _previousChargeLabel;
  double get overallDiscount => _overallDiscount;

  // Calculations
  double get totalNetAmt {
    return _items.fold(0.0, (sum, it) => sum + it.netAmount);
  }

  double get totalGstAmt {
    return _items.fold(0.0, (sum, it) => sum + it.gstAmount);
  }

  double get totalInstallationAmt {
    return _items.fold(0.0, (sum, it) => sum + it.installationCharge);
  }

  double get totalGrossAmt {
    final sub = totalNetAmt + totalGstAmt + totalInstallationAmt + _packingCharges + _deliveryCharges + _previousCharges;
    return double.parse(sub.toStringAsFixed(2));
  }

  double get finalAmount {
    final net = totalGrossAmt - _overallDiscount;
    return net > 0 ? double.parse(net.toStringAsFixed(2)) : 0.0;
  }

  // ---------------- QUOTATION LIST METHODS ----------------
  Future<void> fetchQuotations({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _quotations = [];
    }
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.getQuotations(
        page: _currentPage,
        limit: 30,
        search: _searchQuery,
        status: _selectedStatus,
      );
      final List<Quotation> loaded = res['quotations'] as List<Quotation>;
      if (refresh) {
        _quotations = loaded;
      } else {
        _quotations.addAll(loaded);
      }
      _totalCount = res['total'] ?? _quotations.length;
      _totalPages = res['totalPages'] ?? 1;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(String status) async {
    _selectedStatus = status;
    await fetchQuotations(refresh: true);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await fetchQuotations(refresh: true);
  }

  Future<void> deleteQuotation(String id) async {
    try {
      await _apiService.deleteQuotation(id);
      _quotations.removeWhere((q) => q.id == id);
      _totalCount = (_totalCount > 0) ? _totalCount - 1 : 0;
      notifyListeners();
    } catch (_) {}
  }

  // ---------------- CREATE / EDIT QUOTATION LOGIC ----------------
  void initNewQuotation({String prefix = 'HW/26-27/'}) {
    _editingQuotationId = null;
    final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _quotationNumber = '$prefix$randomSuffix';
    _quotationDate = DateTime.now();
    _customerId = null;
    _customerName = 'Walk-in Customer';
    _customerPhone = '';
    _customerEmail = '';
    _customerAddress = '';
    _customerGstin = '';
    _presentationMode = 'STANDARD';
    _quotationType = 'STANDARD';
    _documentTitle = 'QUOTATION';
    _preparedBy = null;
    _rateGivenBy = null;
    _gstMode = 'WITH_GST';
    _items = [];
    _packingCharges = 0.0;
    _deliveryCharges = 0.0;
    _previousCharges = 0.0;
    _packingChargeLabel = 'PACKING CHARGES';
    _deliveryChargeLabel = 'DELIVERY CHARGES';
    _previousChargeLabel = 'PREVIOUS CHARGES';
    _overallDiscount = 0.0;

    // Pre-populate Row 1 (Ready to use immediately without clicking modals!)
    final firstRow = QuotationItem(
      serialNumber: 1,
      name: '',
      quantity: 1,
      unit: 'Pcs',
      price: 0.0,
      gstRate: 18.0,
      isGstAdded: true,
      section: 'EQUIPMENT SECTION',
    );
    firstRow.recalculate();
    _items = [firstRow];

    notifyListeners();
  }

  void loadQuotationForEdit(Quotation q) {
    _editingQuotationId = q.id;
    _quotationNumber = q.quotationNumber;
    _quotationDate = q.date;
    _customerId = q.customerId;
    _customerName = q.customerName;
    _customerPhone = q.customerPhone ?? '';
    _customerEmail = q.customerEmail ?? '';
    _customerAddress = q.customerAddress ?? '';
    _customerGstin = q.customerGstin ?? '';
    _presentationMode = q.presentationMode;
    _quotationType = q.quotationType;
    _documentTitle = q.documentTitle;
    _preparedBy = q.preparedBy;
    _rateGivenBy = q.rateGivenBy;
    _packingCharges = q.packingCharges;
    _deliveryCharges = q.deliveryCharges;
    _previousCharges = q.previousCharges;
    _packingChargeLabel = q.packingChargeLabel;
    _deliveryChargeLabel = q.deliveryChargeLabel;
    _previousChargeLabel = q.previousChargeLabel;
    _overallDiscount = q.overallDiscount;

    _items = q.items.map((it) {
      final copy = it.copyWith();
      copy.recalculate();
      return copy;
    }).toList();

    _gstMode = q.totalGst > 0 ? 'WITH_GST' : 'WITHOUT_GST';
    notifyListeners();
  }

  void setCustomer(Customer customer) {
    _customerId = customer.id;
    _customerName = customer.companyName;
    _customerPhone = customer.phone ?? '';
    _customerEmail = customer.email ?? '';
    _customerAddress = customer.billingAddress ?? '';
    _customerGstin = customer.gstin ?? '';
    notifyListeners();
  }

  void setCustomerDetails({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
  }) {
    _customerName = name;
    if (phone != null) _customerPhone = phone;
    if (email != null) _customerEmail = email;
    if (address != null) _customerAddress = address;
    if (gstin != null) _customerGstin = gstin;
    notifyListeners();
  }

  void toggleQuotationType() {
    _quotationType = _quotationType == 'MACHINERY' ? 'STANDARD' : 'MACHINERY';
    if (_quotationType == 'MACHINERY') {
      for (var it in _items) {
        if (it.section == null || it.section!.trim().isEmpty) {
          it.section = 'EQUIPMENT SECTION';
        }
      }
    }
    notifyListeners();
  }

  void togglePresentationMode() {
    _presentationMode = _presentationMode == 'PHOTO' ? 'STANDARD' : 'PHOTO';
    notifyListeners();
  }

  void selectProductForItem(int index, Product prod) {
    if (index >= 0 && index < _items.length) {
      final it = _items[index];
      it.productId = prod.id;
      it.name = prod.name;
      it.sku = prod.itemCode;
      it.category = prod.category;
      if (prod.unit.isNotEmpty) it.unit = prod.unit;
      if (prod.sellingPrice > 0) it.price = prod.sellingPrice;
      if (_gstMode == 'WITHOUT_GST') {
        it.gstRate = 0.0;
      } else {
        it.gstRate = prod.taxRate;
      }
      if (prod.imageUrl != null && prod.imageUrl!.isNotEmpty) {
        it.imageUrl = prod.imageUrl;
      }
      if (prod.specification != null && prod.specification!.isNotEmpty) {
        it.specification = prod.specification;
      } else if (prod.description != null && prod.description!.isNotEmpty) {
        it.specification = prod.description;
      }
      if (prod.size != null && prod.size!.isNotEmpty) {
        it.size = prod.size;
      }
      it.recalculate();
      notifyListeners();
    }
  }

  void setQuotationMeta({
    String? quotationNumber,
    DateTime? date,
    String? documentTitle,
    String? presentationMode,
    String? quotationType,
    String? preparedBy,
    String? rateGivenBy,
  }) {
    if (quotationNumber != null) _quotationNumber = quotationNumber;
    if (date != null) _quotationDate = date;
    if (documentTitle != null) _documentTitle = documentTitle;
    if (presentationMode != null) _presentationMode = presentationMode;
    if (quotationType != null) _quotationType = quotationType;
    if (preparedBy != null) _preparedBy = preparedBy;
    if (rateGivenBy != null) _rateGivenBy = rateGivenBy;
    notifyListeners();
  }

  void setGstMode(String mode) {
    _gstMode = mode;
    final shouldAdd = mode == 'WITH_GST';
    for (var it in _items) {
      it.recalculate(overrideGstAdded: shouldAdd);
    }
    notifyListeners();
  }

  void addProductToItems(Product product) {
    final newItem = QuotationItem(
      productId: product.id,
      serialNumber: _items.length + 1,
      name: product.name,
      sku: product.itemCode,
      category: product.category,
      unit: product.unit,
      price: product.sellingPrice,
      gstRate: product.taxRate,
      isGstAdded: _gstMode == 'WITH_GST',
      imageUrl: product.imageUrl,
      description: product.description,
      hsnCode: product.hsnCode,
    );
    newItem.recalculate();
    _items.add(newItem);
    notifyListeners();
  }

  void addCustomItem({
    required String name,
    double quantity = 1.0,
    String unit = 'Pcs',
    double price = 0.0,
    double gstRate = 18.0,
    String? specification,
    String? size,
    double installationCharge = 0.0,
    String? imageUrl,
    String? section,
  }) {
    final newItem = QuotationItem(
      serialNumber: _items.length + 1,
      name: name,
      quantity: quantity,
      unit: unit,
      price: price,
      gstRate: gstRate,
      isGstAdded: _gstMode == 'WITH_GST',
      specification: specification,
      size: size,
      installationCharge: installationCharge,
      imageUrl: imageUrl,
      section: section ?? (_quotationType == 'MACHINERY' ? 'EQUIPMENT SECTION' : null),
    );
    newItem.recalculate();
    _items.add(newItem);
    notifyListeners();
  }

  void addNewBlankRow({String? section}) {
    final newItem = QuotationItem(
      serialNumber: _items.length + 1,
      name: '',
      quantity: 1.0,
      unit: 'Pcs',
      price: 0.0,
      gstRate: _gstMode == 'WITH_GST' ? 18.0 : 0.0,
      isGstAdded: _gstMode == 'WITH_GST',
      section: section ?? (_quotationType == 'MACHINERY' ? 'EQUIPMENT SECTION' : null),
    );
    newItem.recalculate();
    _items.add(newItem);
    notifyListeners();
  }

  List<String> get machinerySections {
    final list = <String>[];
    for (var it in _items) {
      final s = (it.section != null && it.section!.trim().isNotEmpty)
          ? it.section!.trim().toUpperCase()
          : 'EQUIPMENT SECTION';
      if (!list.contains(s)) list.add(s);
    }
    if (list.isEmpty) list.add('EQUIPMENT SECTION');
    return list;
  }

  void renameSection(String oldName, String newName) {
    final target = newName.trim().toUpperCase();
    for (var it in _items) {
      final current = (it.section != null && it.section!.trim().isNotEmpty)
          ? it.section!.trim().toUpperCase()
          : 'EQUIPMENT SECTION';
      if (current == oldName.toUpperCase()) {
        it.section = target;
      }
    }
    notifyListeners();
  }

  void addSection(String sectionName) {
    addNewBlankRow(section: sectionName.trim().toUpperCase());
  }

  void updateItem(int index, QuotationItem updated) {
    if (index >= 0 && index < _items.length) {
      updated.recalculate();
      _items[index] = updated;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      // Re-index serial numbers
      for (int i = 0; i < _items.length; i++) {
        _items[i].serialNumber = i + 1;
      }
      notifyListeners();
    }
  }

  void setAdditionalCharges({
    double? packing,
    double? delivery,
    double? previous,
    String? packingLabel,
    String? deliveryLabel,
    String? previousLabel,
    double? discount,
  }) {
    if (packing != null) _packingCharges = packing;
    if (delivery != null) _deliveryCharges = delivery;
    if (previous != null) _previousCharges = previous;
    if (packingLabel != null) _packingChargeLabel = packingLabel;
    if (deliveryLabel != null) _deliveryChargeLabel = deliveryLabel;
    if (previousLabel != null) _previousChargeLabel = previousLabel;
    if (discount != null) _overallDiscount = discount;
    notifyListeners();
  }

  /// Builds a complete in-memory Quotation model from active screen state
  Quotation buildCurrentQuotation() {
    return Quotation(
      id: _editingQuotationId ?? 'LOCAL-${DateTime.now().millisecondsSinceEpoch}',
      quotationNumber: _quotationNumber,
      date: _quotationDate,
      customerId: _customerId,
      customerName: _customerName.trim().isEmpty ? 'Walk-in Customer' : _customerName.trim(),
      customerPhone: _customerPhone,
      customerEmail: _customerEmail,
      customerAddress: _customerAddress,
      customerGstin: _customerGstin,
      presentationMode: _presentationMode,
      quotationType: _quotationType,
      documentTitle: _documentTitle,
      preparedBy: _preparedBy,
      rateGivenBy: _rateGivenBy,
      totalNet: totalNetAmt,
      totalGst: totalGstAmt,
      installationCharges: totalInstallationAmt,
      deliveryCharges: _deliveryCharges,
      packingCharges: _packingCharges,
      previousCharges: _previousCharges,
      packingChargeLabel: _packingChargeLabel,
      deliveryChargeLabel: _deliveryChargeLabel,
      previousChargeLabel: _previousChargeLabel,
      overallDiscount: _overallDiscount,
      finalAmount: finalAmount,
      status: 'ACTIVE',
      items: List<QuotationItem>.from(_items),
    );
  }

  /// Duplicates an existing quotation with a new quote number & date
  void duplicateQuotation(String quoteId, {String prefix = 'HW/26-27/'}) {
    final original = _quotations.firstWhere((q) => q.id == quoteId);
    _editingQuotationId = null;
    final randomNum = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _quotationNumber = '$prefix$randomNum';
    _quotationDate = DateTime.now();
    _customerId = original.customerId;
    _customerName = original.customerName;
    _customerPhone = original.customerPhone ?? '';
    _customerEmail = original.customerEmail ?? '';
    _customerAddress = original.customerAddress ?? '';
    _customerGstin = original.customerGstin ?? '';
    _presentationMode = original.presentationMode;
    _quotationType = original.quotationType;
    _documentTitle = original.documentTitle;
    _preparedBy = original.preparedBy ?? '';
    _rateGivenBy = original.rateGivenBy ?? '';
    _gstMode = original.totalGst > 0 ? 'WITH_GST' : 'WITHOUT_GST';

    _deliveryCharges = original.deliveryCharges;
    _packingCharges = original.packingCharges;
    _previousCharges = original.previousCharges;
    _deliveryChargeLabel = original.deliveryChargeLabel;
    _packingChargeLabel = original.packingChargeLabel;
    _previousChargeLabel = original.previousChargeLabel;
    _overallDiscount = original.overallDiscount;

    _items = original.items.map((it) {
      return it.copyWith(id: null);
    }).toList();

    notifyListeners();
  }

  Future<Quotation?> saveActiveQuotation({bool fallbackToLocal = true}) async {
    _isLoading = true;
    notifyListeners();

    final localQuote = buildCurrentQuotation();

    try {
      final payload = <String, dynamic>{
        if (_editingQuotationId != null) 'id': _editingQuotationId,
        'quotationNumber': _quotationNumber,
        'date': _quotationDate.toIso8601String(),
        'customerId': _customerId,
        'customerName': _customerName.trim().isEmpty ? 'Walk-in Customer' : _customerName.trim(),
        'customerPhone': _customerPhone,
        'customerEmail': _customerEmail,
        'customerAddress': _customerAddress,
        'customerGstin': _customerGstin,
        'presentationMode': _presentationMode,
        'quotationType': _quotationType,
        'documentTitle': _documentTitle,
        'preparedBy': _preparedBy,
        'rateGivenBy': _rateGivenBy,
        'totalNet': totalNetAmt,
        'totalGst': totalGstAmt,
        'installationCharges': totalInstallationAmt,
        'deliveryCharges': _deliveryCharges,
        'packingCharges': _packingCharges,
        'previousCharges': _previousCharges,
        'packingChargeLabel': _packingChargeLabel,
        'deliveryChargeLabel': _deliveryChargeLabel,
        'previousChargeLabel': _previousChargeLabel,
        'overallDiscount': _overallDiscount,
        'finalAmount': finalAmount,
        'status': 'ACTIVE',
        'items': _items.map((it) => it.toJson()).toList(),
      };

      final saved = await _apiService.saveQuotation(payload);
      final idx = _quotations.indexWhere((q) => q.id == saved.id || q.quotationNumber == saved.quotationNumber);
      if (idx != -1) {
        _quotations[idx] = saved;
      } else {
        _quotations.insert(0, saved);
        _totalCount++;
      }

      _isLoading = false;
      notifyListeners();
      return saved;
    } catch (e) {
      _isLoading = false;
      if (fallbackToLocal) {
        // Offline / Connection error fallback: save locally so PDF generation & editing never block!
        final idx = _quotations.indexWhere((q) => q.id == localQuote.id || q.quotationNumber == localQuote.quotationNumber);
        if (idx != -1) {
          _quotations[idx] = localQuote;
        } else {
          _quotations.insert(0, localQuote);
          _totalCount++;
        }
        notifyListeners();
        return localQuote;
      }
      notifyListeners();
      return null;
    }
  }
}
