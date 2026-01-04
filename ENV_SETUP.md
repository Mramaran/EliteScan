# Environment Variables Configuration - EliteMed

This document explains how to configure environment variables for the EliteMed application.

## 📋 Setup Instructions

### 1. Copy the Example File
```bash
cp .env.example .env
```

### 2. Get Your API Keys

#### Google Gemini API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Copy the key and paste it in `.env` as `GEMINI_API_KEY`

#### Firebase Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create new one)
3. Click on Settings (⚙️) → Project Settings
4. Scroll to "Your apps" section
5. Select your platform (Android/iOS/Web)
6. Copy the configuration values to `.env`

### 3. Environment Variables Reference

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `GEMINI_API_KEY` | Google Gemini AI API Key | [Google AI Studio](https://makersuite.google.com/app/apikey) |
| `FIREBASE_PROJECT_ID` | Firebase Project ID | Firebase Console → Project Settings |
| `FIREBASE_ANDROID_API_KEY` | Android API Key | Firebase Console → Android App Config |
| `FIREBASE_IOS_API_KEY` | iOS API Key | Firebase Console → iOS App Config |
| `FIREBASE_WEB_API_KEY` | Web API Key | Firebase Console → Web App Config |

## 🔒 Security Best Practices

1. **Never commit `.env` to version control**
   - Already added to `.gitignore`
   - Use `.env.example` for documentation

2. **Use different keys for development/production**
   - Create separate Firebase projects
   - Use different Gemini API keys

3. **Rotate keys regularly**
   - Generate new API keys periodically
   - Revoke old keys after rotation

## 🚀 Usage in Code

The app loads environment variables using `flutter_dotenv`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load .env file
await dotenv.load(fileName: ".env");

// Access variables
final apiKey = dotenv.env['GEMINI_API_KEY'];
```

## 🧪 Testing with Demo Keys

For testing/demo purposes, the app includes fallback demo keys:
- Demo keys are clearly marked with `_Demo_` in the name
- Replace with real keys for production deployment

## ⚠️ Important Notes

- `.env` file is ignored by Git (check `.gitignore`)
- Always use `.env.example` to share configuration structure
- Never share actual API keys in public repositories
- Use environment-specific files for different deployments

## 📚 References

- [Flutter DotEnv Package](https://pub.dev/packages/flutter_dotenv)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Google AI Studio](https://ai.google.dev/)
- [Environment Variables Best Practices](https://12factor.net/config)
