# Discover Revamp Feature

This feature follows **Clean Architecture** principles with proper separation of concerns and maintainable code structure.

## Architecture Overview

The feature is organized into the following layers:

### 📁 **Data Layer** (`data/`)
- **Services**: Direct data access and API calls
  - `agent_data_service.dart` - Firestore agent data operations
  - `category_data_service.dart` - Category data with caching
- **Models**: Data transfer objects with serialization
  - `agent_model.dart` - Agent data model with Firestore mapping
  - `category_model.dart` - Category data model
- **Datasources**: External data source implementations
- **Repositories**: Repository pattern implementations
- **Dev Seed**: Development data seeding utilities

### 🏗️ **Domain Layer** (`domain/`)
- **Entities**: Pure business objects without dependencies
  - `agent_entity.dart` - Core agent business object
  - `category_entity.dart` - Core category business object
- **Services**: Business logic coordination
  - `discover_business_service.dart` - Main business logic orchestration
- **Use Cases**: Single-responsibility business operations
  - `get_agents_with_categories.dart` - Fetch agents with resolved categories
- **Repositories**: Abstract contracts (interfaces)

### 🎨 **Presentation Layer** (`presentation/`)
- **Services**: UI-specific logic and data transformation
  - `discover_presentation_service.dart` - Coordinates between UI and business logic
- **Pages**: Screen implementations
  - `discover_revamp_page_clean.dart` - Main discover page with clean architecture
  - `discover_revamp_page.dart` - Legacy implementation (to be replaced)
- **Widgets**: Reusable UI components
- **BLoC**: State management following BLoC pattern

### 🔧 **Dependency Injection** (`di/`)
- Module registration and dependency wiring

## Clean Architecture Benefits

✅ **Separation of Concerns**: Each layer has a single responsibility  
✅ **Testability**: Pure business logic without external dependencies  
✅ **Maintainability**: Clear boundaries and modular structure  
✅ **Scalability**: Easy to add new features without affecting existing code  
✅ **Independence**: UI, business logic, and data sources are decoupled  

## Key Design Patterns

- **Repository Pattern**: Abstract data access
- **Use Case Pattern**: Single-responsibility business operations
- **Service Layer Pattern**: Coordinate complex business logic
- **Model-Entity Mapping**: Clean separation between data and business objects
- **Dependency Injection**: Loose coupling between components

## Usage Examples

### Clean Architecture Implementation

```dart
// ✅ Correct: Using clean architecture
final presentationService = DiscoverPresentationService();
final agents = await presentationService.getDisplayAgents();

// ❌ Avoid: Direct Firestore access in UI
final agents = await FirebaseFirestore.instance.collection('agents').get();
```

### Business Logic Coordination

```dart
// Business service coordinates data fetching and processing
final businessService = DiscoverBusinessService(
  agentDataService: AgentDataService(),
  categoryDataService: CategoryDataService(),
);
final agentsWithCategories = await businessService.getAgentsWithCategories();
```

## Migration Notes

- **Legacy Code**: `discover_revamp_page.dart` contains the old implementation with direct Firestore access
- **New Clean Implementation**: `discover_revamp_page_clean.dart` follows clean architecture principles
- **Gradual Migration**: Other pages can be migrated following the same pattern

## File Organization

```
lib/features/discover_revamp/
├── data/
│   ├── services/
│   │   ├── agent_data_service.dart
│   │   └── category_data_service.dart
│   ├── models/
│   │   ├── agent_model.dart
│   │   └── category_model.dart
│   ├── datasources/
│   ├── repositories/
│   └── dev_seed/
├── domain/
│   ├── entities/
│   │   ├── agent_entity.dart
│   │   └── category_entity.dart
│   ├── services/
│   │   └── discover_business_service.dart
│   ├── usecases/
│   │   └── get_agents_with_categories.dart
│   └── repositories/
├── presentation/
│   ├── services/
│   │   └── discover_presentation_service.dart
│   ├── pages/
│   ├── widgets/
│   └── bloc/
└── di/
```

## Dev: Seed Apple iPhones into all hushhagents

Usage (dev/testing only):

```dart
import 'package:hushh_user_app/features/discover_revamp/data/dev_seed/seed_agent_products.dart';

await seedAllAgentsWithIphones();
```

Notes:
- Iterates all docs in `hushhagents` and writes subcollection `agentProducts` with predefined iPhone docs.
- Converts RFC3339 strings to Firestore `Timestamp` for createdAt/updatedAt/publishedAt.
- Uses batched writes (<=450 per batch) and `merge: true` for idempotency.
