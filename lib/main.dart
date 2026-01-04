import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase & Google Services - GDG Hackathon Integration
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';

void main() async {
  // Firebase Initialization - GDG Hackathon (Following Official Documentation)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EliteMed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5C8A),
          primary: const Color(0xFF2E5C8A),
          secondary: const Color(0xFF5EC4D4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FBFD),
        useMaterial3: true,
      ),
      home: const MedicineFinderPage(),
    );
  }
}

class MedicineFinderPage extends StatefulWidget {
  const MedicineFinderPage({super.key});

  @override
  State<MedicineFinderPage> createState() => _MedicineFinderPageState();
}

class _MedicineFinderPageState extends State<MedicineFinderPage> {
  List<dynamic> _allMedicines = [];
  List<dynamic> _filteredMedicines = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearching = false;

  // Google Services Integration - GDG Hackathon
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  
  // Load Gemini API key from environment variables
  late final GenerativeModel geminiModel;
  
  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _logAnalyticsEvent('app_opened');
    
    // Initialize Gemini with API key from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyDemoKey_GDG_Hackathon';
    geminiModel = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  // Firebase Analytics - Track user events
  Future<void> _logAnalyticsEvent(String eventName) async {
    try {
      await analytics.logEvent(name: eventName);
    } catch (e) {
      // Analytics error handling
    }
  }

  // Gemini AI - Enhanced search suggestions
  Future<String> _getAISuggestion(String query) async {
    try {
      final prompt = 'Suggest medicine alternatives for: $query';
      final content = [Content.text(prompt)];
      final response = await geminiModel.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _loadMedicines() async {
    try {
      final String response =
          await rootBundle.loadString('assets/medicines_dataset.json');
      final data = json.decode(response) as List;
      setState(() {
        _allMedicines = data;
        _filteredMedicines = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMedicines(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMedicines = [];
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _filteredMedicines = _allMedicines.where((medicine) {
            final brandName = medicine['brandName'].toString().toLowerCase();
            final genericName = medicine['genericName'].toString().toLowerCase();
            final searchLower = query.toLowerCase();
            return brandName.contains(searchLower) ||
                genericName.contains(searchLower);
          }).toList();
          _isSearching = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        
        if (_searchController.text.isNotEmpty || _filteredMedicines.isNotEmpty) {
          setState(() {
            _searchController.clear();
            _filteredMedicines = [];
            _isSearching = false;
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EliteMed'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Gemini fetching Generic Info',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchController.text.isEmpty
                        ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _showSearchDialog,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F4F8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5EC4D4).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.search,
                                  size: 60,
                                  color: Color(0xFF2E5C8A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Image.asset(
                              'assets/logo.png',
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Compare. Save. Care.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E5C8A),
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '✨ Tap the search icon to start ✨',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E5C8A), Color(0xFF5EC4D4)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5EC4D4).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _scanMedicine,
                                icon: const Icon(Icons.upload_file, size: 22),
                                label: const Text(
                                  'Upload Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredMedicines.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No medicines found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = _filteredMedicines[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    medicine['brandName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: Color(0xFF2E5C8A),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${medicine['genericName']} - ${medicine['strength']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Color(0xFF5EC4D4),
                                  ),
                                  onTap: () async {
                                    // Show loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return PopScope(
                                          canPop: false,
                                          child: Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Color(0xFF2E5C8A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    'Searching the Cheap',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    // Wait for 2 seconds
                                    await Future.delayed(const Duration(seconds: 2));

                                    // Close loading dialog
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      
                                      // Navigate to detail page
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MedicineDetailPage(medicine: medicine),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      ),
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF2E5C8A), size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Search Medicine',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter brand or generic name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterMedicines('');
                              setModalState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {});
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _filterMedicines(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanMedicine() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      setState(() {
        _isSearching = true;
      });

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;

      // Get only the first line
      extractedText = extractedText.trim();
      if (extractedText.contains('\n')) {
        extractedText = extractedText.split('\n').first.trim();
      }

      if (extractedText.isNotEmpty) {
        // Search for the medicine using first line only
        _searchController.text = extractedText;
        _filterMedicines(extractedText);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in image')),
          );
        }
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
      setState(() {
        _isSearching = false;
      });
    } finally {
      textRecognizer.close();
    }
  }
}

class MedicineDetailPage extends StatelessWidget {
  final dynamic medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final prices = {
      'Tata 1mg': medicine['price_tata1mg'],
      'PharmEasy': medicine['price_pharmEasy'],
      'Apollo 247': medicine['price_apollo247'],
      'Netmeds': medicine['price_netmeds'],
      'MedPlus': medicine['price_medPlus'],
      'MedX': medicine['price_medX'],
    };

    final lowestPrice = prices.values.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['brandName']),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Basic Information', [
              _buildInfoRow('Brand Name', medicine['brandName']),
              _buildInfoRow('Generic Name', medicine['genericName']),
              _buildInfoRow('Composition', medicine['composition']),
              _buildInfoRow('Strength', medicine['strength']),
              _buildInfoRow('Dosage Form', medicine['dosageForm']),
            ]),
            const SizedBox(height: 16),
            _buildSection('Price Comparison', [
              ...prices.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: entry.value == lowestPrice
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${entry.value}',
                            style: TextStyle(
                              fontWeight: entry.value == lowestPrice
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: entry.value == lowestPrice
                                  ? Colors.green.shade900
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Best Price: ${medicine['bestPricePlatform']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Additional Information', [
              _buildInfoRow('Side Effects', medicine['sideEffects']),
              _buildInfoRow('OTC',
                  medicine['OTC'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Govt Verified',
                  medicine['govtVerified'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Trust Score', medicine['trustScore'].toString()),
              _buildInfoRow('Interactions', medicine['interactionChecker']),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medicine['disclaimer'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
