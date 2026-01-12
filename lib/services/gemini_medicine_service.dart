import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine.dart';

/// Service class for interacting with Gemini API to get medicine information
class GeminiMedicineService {
  late final GenerativeModel _model;
  final String apiKey;

  GeminiMedicineService({required this.apiKey}) {
    // Initialize the Gemini model with gemini-2.5-flash as per documentation
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  /// Get medicine information from Gemini and convert to Medicine format for Firebase
  /// 
  /// [medicineName] The name of the medicine to look up
  /// Returns a [Medicine] object that can be saved to Firebase
  /// Throws an exception if the API call fails
  Future<Medicine> getMedicineInfo(String medicineName) async {
    try {
      // Create a structured prompt to get medicine information in Firebase format
      final prompt = '''
You are a pharmaceutical pricing database API with access to current Indian medicine market data. 

Search for REAL pricing information for: "$medicineName" from Indian online pharmacies.

CRITICAL INSTRUCTIONS:
1. Research actual current prices from Tata 1mg, PharmEasy, Apollo 247, Netmeds, MedPlus, and MedX
2. Prices should reflect REAL market rates in Indian Rupees (₹)
3. Verify manufacturer name and strength from official sources
4. Return prices for standard packaging (typically per 10 tablets/capsules or per strip)

Return ONLY a JSON object with this EXACT structure (no markdown, no code blocks, no extra text):
{
  "brandName": "Exact brand name as sold in India",
  "genericName": "Generic/chemical name (e.g., Paracetamol, Azithromycin)",
  "composition": "Active ingredient with strength (e.g., Paracetamol 650mg)",
  "strength": "Dosage strength (e.g., 650mg, 500mg, 10mg) - ONLY the strength value",
  "dosageForm": "Form: Tablet, Capsule, Syrup, Injection, Cream, etc.",
  "category": "Category: Pain & Fever, Antibiotic, Antacid, Allergy, Diabetes, BP, Cholesterol, etc.",
  "manufacturer": "Actual manufacturer company (e.g., Micro Labs, GSK, Cipla, Sun Pharma)",
  "priceUnit": "per 10 tablets",
  "price_tata1mg": 100,
  "price_pharmEasy": 105,
  "price_apollo247": 110,
  "price_netmeds": 98,
  "price_medPlus": 102,
  "price_medX": 95,
  "priceType": "indicative_per_10_tablets",
  "sideEffects": "Nausea;Skin rash;Allergic reactions",
  "govtVerified": true,
  "OTC": false,
  "prescription": "Not Required",
  "interactionChecker": "Alcohol;Warfarin;Other paracetamol products",
  "bestPricePlatform": "netmeds",
  "bestPrice": 0,
  "trustScore": 4.5
}

PRICING GUIDELINES (CRITICAL):
- ALL prices MUST be greater than 0 (NEVER use 0 for any price)
- Research actual prices from Indian pharmacy websites
- Common medicine price ranges in India:
  * Paracetamol 500-650mg: ₹20-35 per 10 tablets
  * Antibiotics (Azithromycin): ₹280-320 per 5 tablets
  * Antacids: ₹70-120 per 10 tablets
  * Diabetes medicines: ₹15-550 per 10 tablets
  * BP medicines: ₹20-100 per 10 tablets
  * Cholesterol medicines: ₹35-120 per 10 tablets
- Prices should vary by 5-15% across platforms (add small variations)
- If exact price unknown, estimate based on medicine type and category
- MINIMUM price for any medicine: ₹10
- Set bestPrice to the LOWEST price among all platforms
- Set bestPricePlatform to the platform with lowest price (usually netmeds or apollo247)
- OTC should be TRUE only for non-prescription medicines like Paracetamol, Cetirizine
- All price values MUST be integers (no decimals)
- FORBIDDEN: Never set any price to 0 or negative values

VALIDATION:
- Verify medicine exists in Indian market
- Cross-check manufacturer with brand name
- Ensure realistic price ranges for the medicine type
- If medicine not found, return closest match with actual data

Return ONLY the JSON object. NO explanations, NO markdown, NO code blocks.
''';

      // Generate content using Gemini API
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Clean the response text - remove markdown code blocks if present
      String jsonText = response.text!.trim();
      
      // Remove markdown code blocks if present
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      
      jsonText = jsonText.trim();

      // Parse the JSON response
      final Map<String, dynamic> jsonData = json.decode(jsonText);

      // Validate and fix prices - ensure no price is 0
      int validatePrice(dynamic price, int defaultPrice) {
        if (price == null) return defaultPrice;
        int parsedPrice = price is int ? price : int.tryParse(price.toString()) ?? defaultPrice;
        return parsedPrice > 0 ? parsedPrice : defaultPrice;
      }

      // Get base price or use a reasonable default based on medicine type
      int basePrice = validatePrice(jsonData['bestPrice'], 50);
      if (basePrice < 10) basePrice = 50; // Minimum reasonable price

      // Ensure all prices are non-zero with slight variations
      int price1mg = validatePrice(jsonData['price_tata1mg'], basePrice + 2);
      int pricePharmEasy = validatePrice(jsonData['price_pharmEasy'], basePrice + 1);
      int priceApollo = validatePrice(jsonData['price_apollo247'], basePrice + 3);
      int priceNetmeds = validatePrice(jsonData['price_netmeds'], basePrice);
      int priceMedPlus = validatePrice(jsonData['price_medPlus'], basePrice + 1);
      int priceMedX = validatePrice(jsonData['price_medX'], basePrice + 5);

      // Calculate best price from validated prices
      List<int> allPrices = [price1mg, pricePharmEasy, priceApollo, priceNetmeds, priceMedPlus, priceMedX];
      int calculatedBestPrice = allPrices.reduce((a, b) => a < b ? a : b);

      // Determine best platform
      String bestPlatform = 'tata1mg';
      if (pricePharmEasy == calculatedBestPrice) bestPlatform = 'pharmEasy';
      if (priceApollo == calculatedBestPrice) bestPlatform = 'apollo247';
      if (priceNetmeds == calculatedBestPrice) bestPlatform = 'netmeds';
      if (priceMedPlus == calculatedBestPrice) bestPlatform = 'medPlus';
      if (priceMedX == calculatedBestPrice) bestPlatform = 'medX';

      // Create Medicine object from Gemini response
      // Generate a temporary ID (will be replaced when saved to Firebase)
      final medicine = Medicine(
        id: null, // Will be set by Firebase
        brandName: jsonData['brandName'] ?? medicineName,
        genericName: jsonData['genericName'] ?? medicineName,
        composition: jsonData['composition'] ?? 'Information not available',
        strength: jsonData['strength'] ?? 'Not specified',
        dosageForm: jsonData['dosageForm'] ?? 'Tablet',
        category: jsonData['category'] ?? 'General',
        manufacturer: jsonData['manufacturer'] ?? 'Various',
        priceUnit: jsonData['priceUnit'] ?? 'per 10 tablets',
        priceTata1mg: price1mg,
        pricePharmEasy: pricePharmEasy,
        priceApollo247: priceApollo,
        priceNetmeds: priceNetmeds,
        priceMedPlus: priceMedPlus,
        priceMedX: priceMedX,
        priceType: jsonData['priceType'] ?? 'indicative_per_10_tablets',
        sideEffects: jsonData['sideEffects'] ?? '',
        govtVerified: jsonData['govtVerified'] ?? false,
        otc: jsonData['OTC'] ?? false,
        prescription: jsonData['prescription'] ?? 'Consult doctor',
        interactionChecker: jsonData['interactionChecker'] ?? '',
        bestPricePlatform: bestPlatform,
        bestPrice: calculatedBestPrice,
        trustScore: (jsonData['trustScore'] ?? 4.0).toDouble(),
      );

      return medicine;
    } catch (e) {
      throw Exception('Failed to get medicine information from Gemini: $e');
    }
  }
}
