class Product {
  final int id;
  final String itemCode;
  final String name;
  final String category;
  final double sellingPrice;
  final double? purchasePrice;
  final double? mrp;
  final String unit;
  final double taxRate;
  final String? hsnCode;
  final String? imageUrl;
  final String? description;
  final String? specification;
  final String? size;
  final String? sourceFile;
  final bool inStock;

  Product({
    required this.id,
    required this.itemCode,
    required this.name,
    this.category = 'General',
    this.sellingPrice = 0.0,
    this.purchasePrice,
    this.mrp,
    this.unit = 'Pcs',
    this.taxRate = 18.0,
    this.hsnCode,
    this.imageUrl,
    this.description,
    this.specification,
    this.size,
    this.sourceFile,
    this.inStock = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemCode: json['itemCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      sellingPrice: double.tryParse(json['sellingPrice']?.toString() ?? '0') ?? 0.0,
      purchasePrice: json['purchasePrice'] != null ? double.tryParse(json['purchasePrice'].toString()) : null,
      mrp: json['mrp'] != null ? double.tryParse(json['mrp'].toString()) : null,
      unit: json['unit']?.toString() ?? 'Pcs',
      taxRate: double.tryParse(json['taxRate']?.toString() ?? '18') ?? 18.0,
      hsnCode: json['hsnCode']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      specification: json['specification']?.toString() ?? json['description']?.toString(),
      size: json['size']?.toString(),
      sourceFile: json['sourceFile']?.toString(),
      inStock: json['inStock'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'itemCode': itemCode,
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'mrp': mrp,
      'unit': unit,
      'taxRate': taxRate,
      'hsnCode': hsnCode,
      'imageUrl': imageUrl,
      'description': description,
      'specification': specification,
      'size': size,
      'sourceFile': sourceFile,
      'inStock': inStock,
    };
  }
}
