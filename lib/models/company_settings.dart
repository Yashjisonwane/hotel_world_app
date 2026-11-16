import 'dart:convert';

class StandardTerm {
  final String id;
  final String text;
  final String color;
  final bool hasPrefix;

  StandardTerm({
    required this.id,
    required this.text,
    this.color = '#ffffff',
    this.hasPrefix = true,
  });

  factory StandardTerm.fromJson(Map<String, dynamic> json) {
    return StandardTerm(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      color: json['color']?.toString() ?? '#ffffff',
      hasPrefix: json['hasPrefix'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'color': color,
      'hasPrefix': hasPrefix,
    };
  }
}

class CompanySettings {
  final int id;
  final String companyName;
  final String tagline;
  final String? logoUrl;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String gstin;
  final String pan;
  final String quotePrefix;
  final int defaultValidityDays;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branch;
  final List<StandardTerm> standardTerms;

  CompanySettings({
    this.id = 1,
    this.companyName = 'HOTEL WORLD',
    this.tagline = 'ALL TYPES OF HOTELWARE & CATERING CROCKERY',
    this.logoUrl,
    this.phone = '94250-63550 / 70007-72501',
    this.email = 'hotelworld2017@gmail.com',
    this.website = 'www.hotelworld.in',
    this.address = '215 , JAWAHAR MARG (RAJMOHALLA) INDORE , M.P',
    this.gstin = '23ADBPC6221H1Z9',
    this.pan = 'ADBPC6221H',
    this.quotePrefix = 'HW/26-27/',
    this.defaultValidityDays = 15,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.branch,
    this.standardTerms = const [],
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    List<StandardTerm> terms = [];
    if (json['standardTerms'] != null && json['standardTerms'] is List) {
      for (var t in (json['standardTerms'] as List)) {
        if (t is Map<String, dynamic>) {
          terms.add(StandardTerm.fromJson(t));
        } else if (t is Map) {
          terms.add(StandardTerm.fromJson(Map<String, dynamic>.from(t)));
        }
      }
    } else if (json['termsAndConditions'] != null) {
      try {
        final parsed = jsonDecode(json['termsAndConditions'].toString());
        if (parsed is Map && parsed['standardTerms'] is List) {
          for (var t in (parsed['standardTerms'] as List)) {
            terms.add(StandardTerm.fromJson(Map<String, dynamic>.from(t)));
          }
        }
      } catch (_) {}
    }

    if (terms.isEmpty) {
      terms = [
        StandardTerm(id: 't-0', text: '100% ADVANCE PAYMENT', color: '#ffffff', hasPrefix: true),
        StandardTerm(id: 't-1', text: 'DELIVERY : IN A WEEK', color: '#ffffff', hasPrefix: true),
        StandardTerm(id: 't-2', text: 'PAYMENT METHOD : IMPS / CHEQUE / CASH', color: '#ffffff', hasPrefix: true),
        StandardTerm(id: 't-3', text: 'GST - EXTRA AND AS MENTIONED', color: '#ffffff', hasPrefix: true),
        StandardTerm(id: 't-4', text: 'OTHER CHARG - EXTRA', color: '#ef4444', hasPrefix: false),
        StandardTerm(id: 't-5', text: 'FREIGHT - EXTRA', color: '#ef4444', hasPrefix: false),
      ];
    }

    return CompanySettings(
      id: int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      companyName: json['companyName']?.toString() ?? 'HOTEL WORLD',
      tagline: json['tagline']?.toString() ?? 'ALL TYPES OF HOTELWARE & CATERING CROCKERY',
      logoUrl: json['logoUrl']?.toString(),
      phone: json['phone']?.toString() ?? '94250-63550 / 70007-72501',
      email: json['email']?.toString() ?? 'hotelworld2017@gmail.com',
      website: json['website']?.toString() ?? 'www.hotelworld.in',
      address: json['address']?.toString() ?? '215 , JAWAHAR MARG (RAJMOHALLA) INDORE , M.P',
      gstin: json['gstin']?.toString() ?? '23ADBPC6221H1Z9',
      pan: json['pan']?.toString() ?? 'ADBPC6221H',
      quotePrefix: json['quotePrefix']?.toString() ?? 'HW/26-27/',
      defaultValidityDays: int.tryParse(json['defaultValidityDays']?.toString() ?? '15') ?? 15,
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      branch: json['branch']?.toString(),
      standardTerms: terms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'tagline': tagline,
      'logoUrl': logoUrl,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'gstin': gstin,
      'pan': pan,
      'quotePrefix': quotePrefix,
      'defaultValidityDays': defaultValidityDays,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branch': branch,
      'standardTerms': standardTerms.map((t) => t.toJson()).toList(),
    };
  }
}

