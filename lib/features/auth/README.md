    # Auth Feature - Clean Architecture Structure

This directory follows Clean Architecture principles with the following structure:

## 📁 Directory Structure

```
auth/
├── domain/                    # Business Logic Layer
│   ├── entities/             # Core business objects
│   │   ├── user.dart
│   │   └── country.dart
│   ├── repositories/         # Repository interfaces
│   │   └── auth_repository.dart
│   ├── usecases/            # Business use cases
│   └── enums.dart           # Business enums
├── data/                     # Data Layer
│   ├── datasources/         # Data sources (API, Local)
│   ├── models/              # Data models
│   │   └── countriesModel.dart
│   └── repositories/        # Repository implementations
└── presentation/            # Presentation Layer
    ├── bloc/               # State management
    │   └── auth_bloc.dart
    ├── pages/              # Screen pages
    │   ├── auth.dart
    │   ├── mainpage.dart
    │   ├── email_input_page.dart
    │   ├── phone_input_page.dart
    │   ├── otp_verification.dart
    │   ├── email_verification.dart
    │   ├── name_input_page.dart
    │   ├── create_first_card.dart
    │   ├── hushh_card_page.dart
    │   ├── card_created_success_page.dart
    │   ├── video_recording_page.dart
    │   └── video_qa_page.dart
    └── widgets/             # Reusable UI components
        ├── country_code_text_field.dart
        ├── email_text_field.dart
        ├── phone_number_text_field.dart
        ├── sign_in_with_email_button.dart
        ├── sign_in_with_phone_button.dart
        ├── email_input_button.dart
        ├── otp_text_field.dart
        ├── otp_heading_section.dart
        ├── resend_otp_button.dart
        ├── social_button.dart
        ├── verifying_bottomsheet.dart
        └── or_separator_widget.dart
```

## 🏗️ Architecture Layers

### Domain Layer
- **Entities**: Core business objects (User, Country)
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Business logic and rules
- **Enums**: Business logic enums (LoginMode, OtpVerificationType)

### Data Layer
- **Data Sources**: Implementation of data access (API, Local Storage)
- **Models**: Data transfer objects and API models
- **Repository Implementations**: Concrete implementations of domain repositories

### Presentation Layer
- **BLoC**: State management using flutter_bloc
- **Pages**: Screen implementations
- **Widgets**: Reusable UI components

## 🔄 Dependencies Flow

```
Presentation → Domain ← Data
     ↓           ↑       ↑
   BLoC → Use Cases → Repository
```

- Presentation layer depends on Domain layer
- Data layer depends on Domain layer
- Domain layer has no dependencies on other layers

## 📝 Key Files

- `domain/enums.dart`: Business logic enums
- `presentation/bloc/auth_bloc.dart`: State management
- `presentation/pages/mainpage.dart`: Main auth entry point
- `presentation/pages/auth.dart`: Auth page implementation
- `data/models/countriesModel.dart`: Country data model

## ✅ Import Structure

All imports have been updated to follow the new structure:
- Domain imports: `../../domain/`
- Data imports: `../../data/`
- Presentation imports: `../` (within presentation layer) 