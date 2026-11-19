import 'quotation_item.dart';

class Quotation {
  final String id;
  final String quotationNumber;
  final DateTime date;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerGstin;
  final String presentationMode; // 'STANDARD', 'COMPACT', 'MACHINERY', 'DETAILED'
  final String quotationType; // 'STANDARD', 'MACHINERY'
  final double totalNet;
  final double totalGst;
  final double installationCharges;
  final double deliveryCharges;
  final double packingCharges;
  final double previousCharges;
  final String packingChargeLabel;
  final String deliveryChargeLabel;
  final String previousChargeLabel;
  final double overallDiscount;
  final double finalAmount;
  final String? preparedBy;
  final String? preparedByPhone;
  final String? rateGivenBy;
  final String? rateGivenByPhone;
  final String documentTitle; // 'QUOTATION', 'ESTIMATE', 'PROFORMA INVOICE'
  final String? createdById;
  final String? createdByEmail;
  final String status; // 'DRAFT', 'ACTIVE', 'ISSUED', 'ACCEPTED', 'REJECTED'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<QuotationItem> items;

  Quotation({
    required this.id,
    required this.quotationNumber,
    required this.date,
    this.customerId,
    this.customerName = 'Walk-in Customer',
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.customerGstin,
    this.presentationMode = 'STANDARD',
    this.quotationType = 'STANDARD',
    this.totalNet = 0.0,
    this.totalGst = 0.0,
    this.installationCharges = 0.0,
    this.deliveryCharges = 0.0,
    this.packingCharges = 0.0,
    this.previousCharges = 0.0,
    this.packingChargeLabel = 'PACKING CHARGES',
    this.deliveryChargeLabel = 'DELIVERY CHARGES',
    this.previousChargeLabel = 'PREVIOUS CHARGES',
    this.overallDiscount = 0.0,
    this.finalAmount = 0.0,
    this.preparedBy,
    this.preparedByPhone,
    this.rateGivenBy,
    this.rateGivenByPhone,
    this.documentTitle = 'QUOTATION',
    this.createdById,
    this.createdByEmail,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    List<QuotationItem> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in (json['items'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(QuotationItem.fromJson(item));
        } else if (item is Map) {
          parsedItems.add(QuotationItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Quotation(
      id: json['id']?.toString() ?? '',
      quotationNumber: json['quotationNumber']?.toString() ?? '',
      date: parsedDate,
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
      customerPhone: json['customerPhone']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
      customerGstin: json['customerGstin']?.toString(),
      presentationMode: json['presentationMode']?.toString() ?? 'STANDARD',
      quotationType: json['quotationType']?.toString() ?? 'STANDARD',
      totalNet: double.tryParse(json['totalNet']?.toString() ?? '0') ?? 0.0,
      totalGst: double.tryParse(json['totalGst']?.toString() ?? '0') ?? 0.0,
      installationCharges: double.tryParse(json['installationCharges']?.toString() ?? '0') ?? 0.0,
      deliveryCharges: double.tryParse(json['deliveryCharges']?.toString() ?? '0') ?? 0.0,
      packingCharges: double.tryParse(json['packingCharges']?.toString() ?? '0') ?? 0.0,
      previousCharges: double.tryParse(json['previousCharges']?.toString() ?? '0') ?? 0.0,
      packingChargeLabel: json['packingChargeLabel']?.toString() ?? 'PACKING CHARGES',
      deliveryChargeLabel: json['deliveryChargeLabel']?.toString() ?? 'DELIVERY CHARGES',
      previousChargeLabel: json['previousChargeLabel']?.toString() ?? 'PREVIOUS CHARGES',
      overallDiscount: double.tryParse(json['overallDiscount']?.toString() ?? '0') ?? 0.0,
      finalAmount: double.tryParse(json['finalAmount']?.toString() ?? '0') ?? 0.0,
      preparedBy: json['preparedBy']?.toString(),
      preparedByPhone: json['preparedByPhone']?.toString(),
      rateGivenBy: json['rateGivenBy']?.toString(),
      rateGivenByPhone: json['rateGivenByPhone']?.toString(),
      documentTitle: json['documentTitle']?.toString() ?? 'QUOTATION',
      createdById: json['createdById']?.toString(),
      createdByEmail: json['createdByEmail']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'customerGstin': customerGstin,
      'presentationMode': presentationMode,
      'quotationType': quotationType,
      'totalNet': totalNet,
      'totalGst': totalGst,
      'installationCharges': installationCharges,
      'deliveryCharges': deliveryCharges,
      'packingCharges': packingCharges,
      'previousCharges': previousCharges,
      'packingChargeLabel': packingChargeLabel,
      'deliveryChargeLabel': deliveryChargeLabel,
      'previousChargeLabel': previousChargeLabel,
      'overallDiscount': overallDiscount,
      'finalAmount': finalAmount,
      'preparedBy': preparedBy,
      'preparedByPhone': preparedByPhone,
      'rateGivenBy': rateGivenBy,
      'rateGivenByPhone': rateGivenByPhone,
      'documentTitle': documentTitle,
      'createdById': createdById,
      'createdByEmail': createdByEmail,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

