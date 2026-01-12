# EliteMed - Medicine Finder & Price Comparison App

A Flutter mobile application that combines OCR scanning, Firebase database, and Gemini AI to help users find medicine information and compare prices across platforms.

## Features

- 🔍 **Medicine Search**: Search medicines by brand or generic name
- 📷 **OCR Scanning**: Scan prescription images to extract medicine names
- 🔥 **Firebase Integration**: Store and retrieve medicine data from Firebase Realtime Database
- 🤖 **Gemini AI**: Automatically fetch medicine information using Google's Gemini AI when not found in database
- 💰 **Price Comparison**: Compare prices across 6 major pharmacy platforms
- 🎨 **Beautiful UI**: Clean and intuitive interface with the localtest theme

## Project Structure

```
Final/elitemed/
├── lib/
│   ├── main.dart                          # Main app entry point
│   ├── models/
│   │   └── medicine.dart                  # Medicine data model
│   └── services/
│       ├── firebase_service.dart          # Firebase CRUD operations
│       └── gemini_medicine_service.dart   # Gemini AI integration
├── android/
│   ├── app/
│   │   ├── google-services.json           # Firebase configuration
│   │   └── build.gradle.kts               # Android build configuration
│   └── build.gradle.kts                   # Project-level build config
├── .env                                    # Environment variables (API keys)
└── pubspec.yaml                           # Dependencies
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extension
- Firebase account
- Google Gemini API key

### 2. Install Dependencies
```bash
cd "Final/elitemed"
flutter pub get
```

### 3. Configure Firebase
- The Firebase configuration is already set up in `android/app/google-services.json`
- Firebase Realtime Database URL: `https://mediscan-483009-default-rtdb.firebaseio.com`
- Make sure Firebase Realtime Database rules allow read/write access

### 4. Configure Gemini API Key
- Open `.env` file in the project root
- Replace `YOUR_API_KEY_HERE` with your actual Gemini API key:
  ```
  GEMINI_API_KEY=your_actual_api_key_here
  ```

### 5. Build and Run

#### For Development (Debug Mode)
```bash
flutter run
```

#### Build APK (Release Mode)
```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

#### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## How It Works

1. **Search Flow**:
   - User searches for a medicine by name
   - App first queries Firebase database
   - If not found, fetches information from Gemini AI
   - Saves the fetched data to Firebase for future use

2. **OCR Flow**:
   - User scans prescription image
   - Google ML Kit extracts text from image
   - First line is used as medicine name
   - Triggers the search flow

3. **Data Storage**:
   - All medicine data is stored in Firebase in the same JSON format
   - Includes: brand name, generic name, composition, strength, prices from 6 platforms, side effects, etc.

## Medicine Data Format

```json
{
  "brandName": "Medicine Brand Name",
  "genericName": "Generic Name",
  "composition": "Active ingredients",
  "strength": "500mg",
  "dosageForm": "Tablet",
  "price_tata1mg": 100,
  "price_pharmEasy": 105,
  "price_apollo247": 110,
  "price_netmeds": 98,
  "price_medPlus": 102,
  "price_medX": 95,
  "priceType": "Per strip",
  "sideEffects": "Common side effects...",
  "govtVerified": true,
  "OTC": false,
  "trustScore": 4.5,
  "bestPricePlatform": "Netmeds",
  "disclaimer": "Consult healthcare professional..."
}
```

## Dependencies

- `firebase_core`: ^3.8.1
- `firebase_database`: ^11.3.3
- `google_mlkit_text_recognition`: ^0.13.1
- `image_picker`: ^1.1.2
- `image`: ^4.3.0
- `google_generative_ai`: ^0.4.6
- `http`: ^1.2.0
- `flutter_dotenv`: ^5.1.0
- `url_launcher`: ^6.3.1

## Features Implementation

### ✅ OCR Scanner (from Basic-test/ocr)
- Integrated Google ML Kit for text recognition
- Image preprocessing for better accuracy
- High-quality image capture settings

### ✅ Firebase Integration (from Basic-test/firebase)
- Firebase Realtime Database connection
- CRUD operations for medicines
- Real-time data synchronization

### ✅ Gemini AI Integration (from elitemed)
- Automatic medicine information fetching
- Structured JSON response parsing
- Fallback when medicine not in database

### ✅ Theme (from Basic-test/localtest)
- Color scheme: Primary #2E5C8A, Secondary #5EC4D4
- Background: #F5FBFD
- Clean and modern UI design
- Smooth animations and transitions

## Important Notes

1. **No Local JSON**: The app does NOT use local JSON files. All data is stored in Firebase.
2. **API Key Security**: Never commit the `.env` file with actual API keys to version control.
3. **Firebase Rules**: Ensure proper security rules are set in Firebase console for production use.
4. **Permissions**: Camera and internet permissions are configured in AndroidManifest.xml.

## Troubleshooting

### Firebase Connection Issues
- Check internet connection
- Verify google-services.json is properly configured
- Check Firebase console for database URL

### OCR Not Working
- Ensure camera permissions are granted
- Use clear, well-lit images
- Text should be clearly visible

### Gemini API Errors
- Verify API key is correct in .env file
- Check API quota limits
- Ensure internet connection is stable

## Building APK

To build the release APK:

```bash
cd "Final/elitemed"
flutter clean
flutter pub get
flutter build apk --release
```

The APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## License

This project is part of a hackathon submission.

