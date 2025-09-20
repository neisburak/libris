# Libris - Book Tracker

A Flutter app for managing your personal book collection with quotations and hashtags. Built with Firebase and Riverpod for state management.

## Features

- **Book Management**: Add, edit, and organize books with reading status (Will Read, Reading, Read)
- **Quotation System**: Save memorable quotes from books with page numbers and hashtags
- **Search Functionality**: Search books by title/author or quotations by content, book name, or hashtags
- **Reading Progress**: Track reading progress with page numbers and progress bars
- **Book Ratings**: Rate books from 1-5 stars
- **Hashtag Organization**: Organize quotations with custom hashtags for easy discovery

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **Firebase**: Backend services (Firestore, Authentication)
- **Riverpod**: State management
- **Material Design 3**: Modern UI components

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase project

### 2. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create a Firestore database
4. Get your Firebase configuration:
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - For Web: Get the config from Project Settings > General > Your apps

5. Update `lib/firebase_options.dart` with your actual Firebase configuration:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'your-actual-web-api-key',
     appId: 'your-actual-web-app-id',
     messagingSenderId: 'your-actual-sender-id',
     projectId: 'your-actual-project-id',
     authDomain: 'your-actual-project-id.firebaseapp.com',
     storageBucket: 'your-actual-project-id.appspot.com',
   );
   // ... update other platforms similarly
   ```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── models/           # Data models (Book, Quotation)
├── providers/        # Riverpod providers for state management
├── screens/          # UI screens
├── services/         # Firebase service layer
├── firebase_options.dart  # Firebase configuration
└── main.dart         # App entry point
```

## Usage

1. **Adding Books**: Tap the + button on the Books tab to add a new book
2. **Managing Reading Status**: Books are organized into three categories: Will Read, Reading, and Read
3. **Adding Quotations**: From any book detail screen, tap + to add quotations with hashtags
4. **Searching**: Use the Search tab to find books or quotations by various criteria
5. **Hashtag Discovery**: Browse all hashtags in the Search tab to find related quotations

## Data Structure

### Book Model
- Title, Author, Description
- Reading Status (Will Read, Reading, Read)
- Progress tracking (current page, total pages)
- Rating (1-5 stars)
- Cover image URL

### Quotation Model
- Content (the actual quote)
- Associated book reference
- Page number
- Hashtags array
- Personal notes
- Creation/update timestamps

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
