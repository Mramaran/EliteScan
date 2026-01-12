import 'package:firebase_database/firebase_database.dart';
import '../models/medicine.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Reference to medicines node
  DatabaseReference get medicinesRef => _database.child('medicines');

  /// Upload a single medicine to Firebase Realtime Database
  Future<String> addMedicine(Medicine medicine) async {
    try {
      // Generate a new key for the medicine
      final newMedicineRef = medicinesRef.push();
      
      // Create medicine with the generated ID
      final medicineWithId = medicine.copyWith(id: newMedicineRef.key);
      
      // Set the medicine data
      await newMedicineRef.set(medicineWithId.toJson());
      
      return newMedicineRef.key!;
    } catch (e) {
      throw Exception('Failed to add medicine: $e');
    }
  }

  /// Upload multiple medicines from JSON data
  Future<void> uploadMedicinesFromJson(List<Map<String, dynamic>> medicinesJson) async {
    try {
      final Map<String, dynamic> updates = {};
      
      for (var medicineJson in medicinesJson) {
        // Generate a new key for each medicine
        final newKey = medicinesRef.push().key;
        
        // Add the ID to the medicine data
        medicineJson['id'] = newKey;
        
        // Add to updates map
        updates['medicines/$newKey'] = medicineJson;
      }
      
      // Perform batch update
      await _database.update(updates);
    } catch (e) {
      throw Exception('Failed to upload medicines: $e');
    }
  }

  /// Get all medicines from Firebase
  Future<List<Medicine>> getAllMedicines() async {
    try {
      final snapshot = await medicinesRef.get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final List<Medicine> medicines = [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      data.forEach((key, value) {
        medicines.add(Medicine.fromJson(key, value as Map<dynamic, dynamic>));
      });
      
      return medicines;
    } catch (e) {
      throw Exception('Failed to get medicines: $e');
    }
  }

  /// Listen to medicines changes in real-time
  Stream<List<Medicine>> getMedicinesStream() {
    return medicinesRef.onValue.map((event) {
      final List<Medicine> medicines = [];
      
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          medicines.add(Medicine.fromJson(key, value as Map<dynamic, dynamic>));
        });
      }
      
      return medicines;
    });
  }

  /// Get a single medicine by ID
  Future<Medicine?> getMedicineById(String id) async {
    try {
      final snapshot = await medicinesRef.child(id).get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      return Medicine.fromJson(id, snapshot.value as Map<dynamic, dynamic>);
    } catch (e) {
      throw Exception('Failed to get medicine: $e');
    }
  }

  /// Update a medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      if (medicine.id == null) {
        throw Exception('Medicine ID cannot be null');
      }
      
      await medicinesRef.child(medicine.id!).update(medicine.toJson());
    } catch (e) {
      throw Exception('Failed to update medicine: $e');
    }
  }

  /// Delete a medicine
  Future<void> deleteMedicine(String id) async {
    try {
      await medicinesRef.child(id).remove();
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }

  /// Calculate Levenshtein distance between two strings (for fuzzy matching)
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List.generate(s2.length + 1, (i) => i);
    List<int> v1 = List.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[s2.length];
  }

  /// Calculate similarity percentage between two strings
  double _calculateSimilarity(String s1, String s2) {
    int distance = _levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    if (maxLength == 0) return 100.0;
    return ((maxLength - distance) / maxLength) * 100;
  }

  /// Search medicines by name with fuzzy matching for typos
  Future<List<Medicine>> searchMedicinesByName(String query) async {
    try {
      final allMedicines = await getAllMedicines();
      query = query.trim();
      
      // First, try exact contains match
      List<Medicine> exactMatches = allMedicines.where((medicine) {
        return medicine.brandName.toLowerCase().contains(query.toLowerCase()) ||
               medicine.genericName.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (exactMatches.isNotEmpty) {
        return exactMatches;
      }

      // If no exact matches, try fuzzy matching for typos
      List<Medicine> fuzzyMatches = [];
      Map<Medicine, double> medicineScores = {};
      
      for (var medicine in allMedicines) {
        String queryLower = query.toLowerCase();
        String brandLower = medicine.brandName.toLowerCase();
        String genericLower = medicine.genericName.toLowerCase();
        
        // Calculate Levenshtein distance for both names
        int brandDistance = _levenshteinDistance(queryLower, brandLower);
        int genericDistance = _levenshteinDistance(queryLower, genericLower);
        
        // Calculate similarity percentages
        double brandSimilarity = _calculateSimilarity(queryLower, brandLower);
        double genericSimilarity = _calculateSimilarity(queryLower, genericLower);
        
        // Special handling for very close matches (1-3 character differences)
        // For strings of similar length, if distance is small, it's likely a typo
        bool isCloseMatch = false;
        if (queryLower.length >= 5) {  // Only for reasonably long queries
          int maxLength = queryLower.length > brandLower.length ? queryLower.length : brandLower.length;
          int genericMaxLength = queryLower.length > genericLower.length ? queryLower.length : genericLower.length;
          
          // If distance is <= 3 and lengths are similar, consider it a close match
          if (brandDistance <= 3 && (maxLength - queryLower.length).abs() <= 2) {
            isCloseMatch = true;
          }
          if (genericDistance <= 3 && (genericMaxLength - queryLower.length).abs() <= 2) {
            isCloseMatch = true;
          }
        }
        
        // Also check word-by-word similarity for multi-word names
        List<String> queryWords = queryLower.split(' ');
        List<String> brandWords = brandLower.split(' ');
        List<String> genericWords = genericLower.split(' ');
        
        double maxWordSimilarity = 0.0;
        for (String qWord in queryWords) {
          if (qWord.length < 3) continue; // Skip very short words
          
          for (String bWord in brandWords) {
            if (bWord.length < 3) continue;
            double sim = _calculateSimilarity(qWord, bWord);
            if (sim > maxWordSimilarity) maxWordSimilarity = sim;
          }
          for (String gWord in genericWords) {
            if (gWord.length < 3) continue;
            double sim = _calculateSimilarity(qWord, gWord);
            if (sim > maxWordSimilarity) maxWordSimilarity = sim;
          }
        }
        
        // Calculate overall score
        double maxSimilarity = brandSimilarity > genericSimilarity ? brandSimilarity : genericSimilarity;
        
        // Accept if:
        // 1. Close match (1-3 character difference)
        // 2. Similarity >= 65% for full string match
        // 3. Word similarity >= 75% for multi-word names
        if (isCloseMatch || maxSimilarity >= 65 || maxWordSimilarity >= 75) {
          fuzzyMatches.add(medicine);
          medicineScores[medicine] = maxSimilarity > maxWordSimilarity ? maxSimilarity : maxWordSimilarity;
        }
      }
      
      // Sort by similarity score (highest first)
      if (medicineScores.isNotEmpty) {
        fuzzyMatches.sort((a, b) {
          double scoreA = medicineScores[a] ?? 0;
          double scoreB = medicineScores[b] ?? 0;
          return scoreB.compareTo(scoreA);
        });
      }

      return fuzzyMatches;
    } catch (e) {
      throw Exception('Failed to search medicines: $e');
    }
  }

  /// Get medicines by category
  Stream<List<Medicine>> getMedicinesByCategory(String category) {
    return medicinesRef
        .orderByChild('genericName')
        .equalTo(category)
        .onValue
        .map((event) {
      final List<Medicine> medicines = [];
      
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          medicines.add(Medicine.fromJson(key, value as Map<dynamic, dynamic>));
        });
      }
      
      return medicines;
    });
  }

  /// Delete all medicines (use with caution!)
  Future<void> deleteAllMedicines() async {
    try {
      await medicinesRef.remove();
    } catch (e) {
      throw Exception('Failed to delete all medicines: $e');
    }
  }
}
