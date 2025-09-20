# Firebase Configuration Files

This directory contains Firebase configuration files for the Libris app.

## Files

- `app_config.dart` - Main Firebase configuration file (ignored by git)
- `app_config.template.dart` - Template Firebase configuration file (committed to git)

## Setup

1. Copy the template file to create your local configuration:
   ```bash
   cp lib/config/app_config.template.dart lib/config/app_config.dart
   ```

2. Update the Firebase configuration values in `app_config.dart` with your actual values:
   - Android Firebase configuration (project ID, API key, etc.)
   - iOS Firebase configuration (project ID, API key, etc.)
   - Firebase services enable/disable flags

## Firebase Configuration

The configuration includes separate settings for Android and iOS platforms:

### Android Configuration
- `androidFirebaseProjectId` - Your Android Firebase project ID
- `androidFirebaseApiKey` - Your Android Firebase API key
- `androidFirebaseMessagingSenderId` - Your Android messaging sender ID
- `androidFirebaseStorageBucket` - Your Android storage bucket
- `androidFirebaseDatabaseUrl` - Your Android Realtime Database URL
- `androidFirebaseAuthDomain` - Your Android auth domain
- `androidFirebaseMeasurementId` - Your Android Analytics measurement ID

### iOS Configuration
- `iosFirebaseProjectId` - Your iOS Firebase project ID
- `iosFirebaseApiKey` - Your iOS Firebase API key
- `iosFirebaseMessagingSenderId` - Your iOS messaging sender ID
- `iosFirebaseStorageBucket` - Your iOS storage bucket
- `iosFirebaseDatabaseUrl` - Your iOS Realtime Database URL
- `iosFirebaseAuthDomain` - Your iOS auth domain
- `iosFirebaseMeasurementId` - Your iOS Analytics measurement ID

## Usage

Import the configuration in your Dart files:

```dart
import 'package:libris_app/config/app_config.dart';

// Use Firebase configuration values
final projectId = AppConfig.firebaseProjectId;
final apiKey = AppConfig.firebaseApiKey;
final isAuthEnabled = AppConfig.enableFirebaseAuth;
```

## Platform-Specific Configuration

The configuration provides getter methods that return platform-specific values:

```dart
// These will return the appropriate values based on your setup
final projectId = AppConfig.firebaseProjectId;
final apiKey = AppConfig.firebaseApiKey;
```

You can modify the getter methods to return different values based on platform or environment.

## Security

- The `app_config.dart` file is ignored by git to prevent sensitive Firebase keys from being committed
- The `app_config.template.dart` file serves as a template and can be safely committed
- Make sure to never commit sensitive information like Firebase API keys or project IDs

## Firebase Services

You can enable/disable Firebase services using the boolean flags:

```dart
static const bool enableFirebaseAuth = true;
static const bool enableFirestore = true;
static const bool enableFirebaseStorage = true;
static const bool enableFirebaseAnalytics = true;
static const bool enableFirebaseCrashlytics = true;
static const bool enableFirebaseMessaging = true;
static const bool enableFirebaseRemoteConfig = true;
```
