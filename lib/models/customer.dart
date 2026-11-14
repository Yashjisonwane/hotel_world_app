class Customer {
  final String id;
  final String companyName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? billingAddress;
  final String? gstin;
  final String? city;
  final String? state;
  final int quotationsCount;

  Customer({
    required this.id,
    required this.companyName,
    this.contactPerson,
    this.phone,
    this.email,
    this.billingAddress,
    this.gstin,
    this.city,
    this.state,
    this.quotationsCount = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['_count'] != null && json['_count']['quotations'] != null) {
      count = int.tryParse(json['_count']['quotations'].toString()) ?? 0;
    }

    return Customer(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      billingAddress: json['billingAddress']?.toString(),
      gstin: json['gstin']?.toString(),
      city: json['city']?.toString() ?? 'Indore',
      state: json['state']?.toString() ?? 'Madhya Pradesh',
      quotationsCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'billingAddress': billingAddress,
      'gstin': gstin,
      'city': city,
      'state': state,
    };
  }
}

