class QuotationItem {
  String? id;
  int? productId;
  int serialNumber;
  String name;
  String? sku;
  String? category;
  String? section;
  String? specification;
  String? size;
  double quantity;
  String unit;
  double price;
  double gstRate;
  String? gstText;
  bool isGstAdded;
  bool isGstInclusive;
  double netAmount;
  double gstAmount;
  double grossAmount;
  double installationCharge;
  String? imageUrl;
  String? description;
  String? hsnCode;
  double? purchasePrice;
  double? marginPercent;
  double? mrp;
  double? discountPercent;

  QuotationItem({
    this.id,
    this.productId,
    this.serialNumber = 1,
    this.name = '',
    this.sku,
    this.category,
    this.section,
    this.specification,
    this.size,
    this.quantity = 1.0,
    this.unit = 'Pcs',
    this.price = 0.0,
    this.gstRate = 18.0,
    this.gstText,
    this.isGstAdded = false,
    this.isGstInclusive = false,
    this.netAmount = 0.0,
    this.gstAmount = 0.0,
    this.grossAmount = 0.0,
    this.installationCharge = 0.0,
    this.imageUrl,
    this.description,
    this.hsnCode,
    this.purchasePrice,
    this.marginPercent,
    this.mrp,
    this.discountPercent,
  });

  /// Recalculates mathematical row values matching Hotel World web logic:
  /// NET. AMT = QTY * PRICE
  /// GST AMT = shouldAdd ? (NET. AMT * GST% / 100) : 0
  /// GROSS AMT = NET. AMT + GST AMT + INSTALLATION
  void recalculate({bool? overrideGstAdded}) {
    if (overrideGstAdded != null) {
      isGstAdded = overrideGstAdded;
    }
    netAmount = double.parse((quantity * price).toStringAsFixed(2));
    if (isGstAdded && gstRate > 0) {
      gstAmount = double.parse(((netAmount * gstRate) / 100).toStringAsFixed(2));
    } else {
      gstAmount = 0.0;
    }
    grossAmount = double.parse((netAmount + gstAmount + installationCharge).toStringAsFixed(2));
  }

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    final item = QuotationItem(
      id: json['id']?.toString(),
      productId: json['productId'] != null ? int.tryParse(json['productId'].toString()) : null,
      serialNumber: int.tryParse(json['serialNumber']?.toString() ?? '1') ?? 1,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      category: json['category']?.toString(),
      section: json['section']?.toString(),
      specification: json['specification']?.toString(),
      size: json['size']?.toString(),
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unit: json['unit']?.toString() ?? 'Pcs',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      gstRate: double.tryParse(json['gstRate']?.toString() ?? '18') ?? 18.0,
      gstText: json['gstText']?.toString(),
      isGstAdded: (double.tryParse(json['gstAmount']?.toString() ?? '0') ?? 0) > 0,
      isGstInclusive: json['isGstInclusive'] == true || RegExp(r'\binc[\s.]*gst\b', caseSensitive: false).hasMatch(json['name']?.toString() ?? ''),
      netAmount: double.tryParse(json['netAmount']?.toString() ?? '0') ?? 0.0,
      gstAmount: double.tryParse(json['gstAmount']?.toString() ?? '0') ?? 0.0,
      grossAmount: double.tryParse(json['grossAmount']?.toString() ?? '0') ?? 0.0,
      installationCharge: double.tryParse(json['installationCharge']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      hsnCode: json['hsnCode']?.toString(),
      purchasePrice: double.tryParse(json['purchasePrice']?.toString() ?? json['purchaseCost']?.toString() ?? ''),
      marginPercent: double.tryParse(json['marginPercent']?.toString() ?? ''),
      mrp: double.tryParse(json['mrp']?.toString() ?? ''),
      discountPercent: double.tryParse(json['discountPercent']?.toString() ?? ''),
    );
    return item;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'serialNumber': serialNumber,
      'name': name,
      'sku': sku,
      'category': category,
      'section': section,
      'specification': specification,
      'size': size,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      if (mrp != null) 'mrp': mrp,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'purchasePrice': purchasePrice,
      'marginPercent': marginPercent,
      'gstRate': gstRate,
      if (gstText != null) 'gstText': gstText,
      'isGstAdded': isGstAdded,
      'isGstInclusive': isGstInclusive,
      'netAmount': netAmount,
      'gstAmount': gstAmount,
      'grossAmount': grossAmount,
      'installationCharge': installationCharge,
      'imageUrl': imageUrl,
      'description': description,
      'hsnCode': hsnCode,
    };
  }

  QuotationItem copyWith({
    String? id,
    int? productId,
    int? serialNumber,
    String? name,
    String? sku,
    String? category,
    String? section,
    String? specification,
    String? size,
    double? quantity,
    String? unit,
    double? price,
    double? gstRate,
    String? gstText,
    bool? isGstAdded,
    bool? isGstInclusive,
    double? netAmount,
    double? gstAmount,
    double? grossAmount,
    double? installationCharge,
    String? imageUrl,
    String? description,
    String? hsnCode,
    double? purchasePrice,
    double? marginPercent,
    double? mrp,
    bool clearMrp = false,
    double? discountPercent,
    bool clearDiscount = false,
  }) {
    return QuotationItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      section: section ?? this.section,
      specification: specification ?? this.specification,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      gstText: gstText ?? this.gstText,
      isGstAdded: isGstAdded ?? this.isGstAdded,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      netAmount: netAmount ?? this.netAmount,
      gstAmount: gstAmount ?? this.gstAmount,
      grossAmount: grossAmount ?? this.grossAmount,
      installationCharge: installationCharge ?? this.installationCharge,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      marginPercent: marginPercent ?? this.marginPercent,
      mrp: clearMrp ? null : (mrp ?? this.mrp),
      discountPercent: clearDiscount ? null : (discountPercent ?? this.discountPercent),
    );
  }
}

