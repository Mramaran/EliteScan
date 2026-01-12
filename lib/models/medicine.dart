class Medicine {
  final String? id;
  final String brandName;
  final String genericName;
  final String composition;
  final String strength;
  final String dosageForm;
  final String category;
  final String manufacturer;
  final String priceUnit;
  final int priceTata1mg;
  final int pricePharmEasy;
  final int priceApollo247;
  final int priceNetmeds;
  final int priceMedPlus;
  final int priceMedX;
  final String priceType;
  final String sideEffects;
  final bool govtVerified;
  final bool otc;
  final String prescription;
  final String interactionChecker;
  final String bestPricePlatform;
  final int bestPrice;
  final double trustScore;

  Medicine({
    this.id,
    required this.brandName,
    required this.genericName,
    required this.composition,
    required this.strength,
    required this.dosageForm,
    required this.category,
    required this.manufacturer,
    required this.priceUnit,
    required this.priceTata1mg,
    required this.pricePharmEasy,
    required this.priceApollo247,
    required this.priceNetmeds,
    required this.priceMedPlus,
    required this.priceMedX,
    required this.priceType,
    required this.sideEffects,
    required this.govtVerified,
    required this.otc,
    required this.prescription,
    required this.interactionChecker,
    required this.bestPricePlatform,
    required this.bestPrice,
    required this.trustScore,
  });

  // Convert Medicine object to Map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'genericName': genericName,
      'composition': composition,
      'strength': strength,
      'dosageForm': dosageForm,
      'category': category,
      'manufacturer': manufacturer,
      'priceUnit': priceUnit,
      'price_tata1mg': priceTata1mg,
      'price_pharmEasy': pricePharmEasy,
      'price_apollo247': priceApollo247,
      'price_netmeds': priceNetmeds,
      'price_medPlus': priceMedPlus,
      'price_medX': priceMedX,
      'priceType': priceType,
      'sideEffects': sideEffects,
      'govtVerified': govtVerified,
      'OTC': otc,
      'prescription': prescription,
      'interactionChecker': interactionChecker,
      'bestPricePlatform': bestPricePlatform,
      'bestPrice': bestPrice,
      'trustScore': trustScore,
    };
  }

  // Create Medicine object from Map (Firebase data)
  factory Medicine.fromJson(String id, Map<dynamic, dynamic> json) {
    return Medicine(
      id: id,
      brandName: json['brandName'] ?? '',
      genericName: json['genericName'] ?? '',
      composition: json['composition'] ?? '',
      strength: json['strength'] ?? '',
      dosageForm: json['dosageForm'] ?? '',
      category: json['category'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      priceUnit: json['priceUnit'] ?? '',
      priceTata1mg: json['price_tata1mg'] ?? 0,
      pricePharmEasy: json['price_pharmEasy'] ?? 0,
      priceApollo247: json['price_apollo247'] ?? 0,
      priceNetmeds: json['price_netmeds'] ?? 0,
      priceMedPlus: json['price_medPlus'] ?? 0,
      priceMedX: json['price_medX'] ?? 0,
      priceType: json['priceType'] ?? '',
      sideEffects: json['sideEffects'] ?? '',
      govtVerified: json['govtVerified'] ?? false,
      otc: json['OTC'] ?? false,
      prescription: json['prescription'] ?? '',
      interactionChecker: json['interactionChecker'] ?? '',
      bestPricePlatform: json['bestPricePlatform'] ?? '',
      bestPrice: json['bestPrice'] ?? 0,
      trustScore: (json['trustScore'] ?? 0.0).toDouble(),
    );
  }

  // Copy with method for updates
  Medicine copyWith({
    String? id,
    String? brandName,
    String? genericName,
    String? composition,
    String? strength,
    String? dosageForm,
    String? category,
    String? manufacturer,
    String? priceUnit,
    int? priceTata1mg,
    int? pricePharmEasy,
    int? priceApollo247,
    int? priceNetmeds,
    int? priceMedPlus,
    int? priceMedX,
    String? priceType,
    String? sideEffects,
    bool? govtVerified,
    bool? otc,
    String? prescription,
    String? interactionChecker,
    String? bestPricePlatform,
    int? bestPrice,
    double? trustScore,
  }) {
    return Medicine(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      genericName: genericName ?? this.genericName,
      composition: composition ?? this.composition,
      strength: strength ?? this.strength,
      dosageForm: dosageForm ?? this.dosageForm,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      priceUnit: priceUnit ?? this.priceUnit,
      priceTata1mg: priceTata1mg ?? this.priceTata1mg,
      pricePharmEasy: pricePharmEasy ?? this.pricePharmEasy,
      priceApollo247: priceApollo247 ?? this.priceApollo247,
      priceNetmeds: priceNetmeds ?? this.priceNetmeds,
      priceMedPlus: priceMedPlus ?? this.priceMedPlus,
      priceMedX: priceMedX ?? this.priceMedX,
      priceType: priceType ?? this.priceType,
      sideEffects: sideEffects ?? this.sideEffects,
      govtVerified: govtVerified ?? this.govtVerified,
      otc: otc ?? this.otc,
      prescription: prescription ?? this.prescription,
      interactionChecker: interactionChecker ?? this.interactionChecker,
      bestPricePlatform: bestPricePlatform ?? this.bestPricePlatform,
      bestPrice: bestPrice ?? this.bestPrice,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}
