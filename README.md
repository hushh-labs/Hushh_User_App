# Hushh User App

A comprehensive Flutter mobile application that combines AI-powered personal data assistant (PDA), real-time chat, product discovery, and smart notifications in one unified platform.

## 🚀 Features

### Core Features
- **Authentication System**: Secure phone/email-based authentication with OTP verification
- **Personal Data Assistant (PDA)**: AI-powered assistant using Google Cloud Vertex AI
- **Real-time Chat**: Firebase Realtime Database powered messaging system
- **Product Discovery**: Browse and discover products with agent-based bidding system
- **Smart Notifications**: Firebase Cloud Messaging with local notification support
- **Profile Management**: User profile creation and management with Hushh cards

### Advanced Features
- **Gmail Integration**: Real-time email monitoring and processing
- **AI-Powered Bidding**: Agent-based product bidding with smart notifications
- **Cross-platform Support**: iOS, Android, Web, Windows, macOS, and Linux
- **Guest Mode**: Limited functionality without authentication
- **Cart Management**: Shopping cart with notification system
- **Video/Audio**: Camera, video recording, and audio processing capabilities

## 🏗️ Architecture

This project follows **Clean Architecture** principles with:

- **Domain Layer**: Entities, repositories, and use cases
- **Data Layer**: Models, data sources, and repository implementations  
- **Presentation Layer**: BLoC pattern for state management, pages, and widgets
- **Dependency Injection**: GetIt for service locator pattern
- **Modular Structure**: Feature-based organization with separate modules

### Project Structure

```
hushh_user_app/
├── lib/
│   ├── core/                    # Core utilities and configurations
│   ├── di/                      # Dependency injection setup
│   ├── features/                # Feature modules
│   │   ├── auth/               # Authentication feature
│   │   ├── chat/               # Real-time messaging
│   │   ├── discover/           # Product discovery
│   │   ├── notifications/      # Push notifications
│   │   ├── pda/               # Personal Data Assistant
│   │   └── profile/           # User profile management
│   ├── shared/                 # Shared utilities and widgets
│   ├── app.dart               # Main app configuration
│   └── main.dart              # Application entry point
├── functions/                  # Firebase Cloud Functions
├── assets/                     # Images, fonts, animations
└── README.md                  # This file
```

## 🛠️ Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.8.1+
- **State Management**: BLoC pattern with flutter_bloc
- **Navigation**: GoRouter for declarative routing
- **Dependency Injection**: GetIt
- **Local Storage**: Hive, SharedPreferences
- **Animations**: Lottie, Flutter Animate

### Backend & Services
- **Firebase Services**:
  - Authentication (Phone/Email OTP)
  - Firestore (NoSQL database)
  - Realtime Database (Chat messaging)
  - Cloud Functions (Serverless backend)
  - Cloud Messaging (Push notifications)
  - Storage (File uploads)
- **Google Cloud**: Vertex AI for PDA functionality
- **Supabase**: Additional backend services

### Additional Integrations
- **Gmail API**: Email monitoring and processing
- **Camera & Media**: Image/video capture and processing
- **Audio**: Recording and playback capabilities
- **WebView**: In-app web content

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **Web** (PWA support)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Linux** (Desktop)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK
- Firebase project setup
- Google Cloud project with Vertex AI enabled
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Hush_user
   ```

2. **Install Flutter dependencies**
   ```bash
   cd hushh_user_app
   flutter pub get
   ```

3. **Configure Firebase**
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Update `firebase_options.dart` with your configuration

4. **Environment Configuration**
   - Create `.env` file in the root directory
   - Add required environment variables (API keys, endpoints)

5. **Firebase Functions Setup**
   ```bash
   cd functions
   npm install
   ```

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d windows       # Windows
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Phone, Email)
3. Set up Firestore database
4. Configure Cloud Messaging
5. Deploy Cloud Functions

### Environment Variables
Create a `.env` file with:
```env
FIREBASE_API_KEY=your_api_key
GOOGLE_CLOUD_PROJECT_ID=your_project_id
VERTEX_AI_ENDPOINT=your_vertex_ai_endpoint
# Add other required variables
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Test with coverage
flutter test --coverage
```

## 📦 Dependencies

### Core Dependencies
- `flutter_bloc` - State management
- `get_it` - Dependency injection
- `go_router` - Navigation
- `firebase_core` - Firebase integration
- `dartz` - Functional programming

### UI & Animation
- `responsive_sizer` - Responsive design
- `lottie` - Animations
- `flutter_svg` - SVG support
- `cached_network_image` - Image caching

### Features
- `camera` - Camera functionality
- `firebase_messaging` - Push notifications
- `google_sign_in` - Google authentication
- `googleapis` - Google APIs integration

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clean Architecture principles
- Use BLoC pattern for state management
- Write unit tests for business logic
- Follow Flutter/Dart style guidelines
- Document new features and APIs

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation in individual feature modules

## 🔄 Version History

- **v1.0.2+137** - Current version
  - Enhanced PDA functionality
  - Improved chat system
  - Better notification handling
  - UI/UX improvements

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Cloud for AI capabilities
- All open-source contributors

---

**Built with ❤️ using Flutter**
