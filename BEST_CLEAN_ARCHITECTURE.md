# Best Possible Clean Architecture Structure

This project implements the **best possible Clean Architecture** with enterprise-level scalability and maintainability.

## 🏗️ Complete Root-Level Structure

```
lib/
├── di/                           # 🎯 ROOT LEVEL DI - Enterprise scalability
│   ├── injection_container.dart  # Main DI container
│   ├── app_module.dart           # Main app module
│   ├── core_module.dart          # Core dependencies
│   ├── auth_module.dart          # Auth feature module
│   └── shared_module.dart        # Shared dependencies
├── shared/                       # 🎯 ROOT LEVEL SHARED - Reusable components
│   ├── domain/                   # Shared domain layer
│   │   ├── entities/             # Base entities
│   │   ├── repositories/         # Base repository interfaces
│   │   └── usecases/             # Base usecase patterns
│   ├── data/                     # Shared data layer
│   │   ├── models/               # Base models
│   │   └── datasources/          # Base data source patterns
│   ├── presentation/             # Shared presentation layer
│   │   ├── bloc/                 # Base BLoC patterns
│   │   └── widgets/              # Base widget patterns
│   ├── di/                       # Shared DI module
│   ├── constants/                # Shared constants
│   └── utils/                    # Shared utilities
├── core/                         # Core functionality
│   ├── constants/                # App constants
│   ├── errors/                   # Error handling
│   ├── network/                  # Network utilities
│   ├── routing/                  # Navigation (GoRouter)
│   ├── services/                 # Firebase services
│   ├── utils/                    # Helper functions
│   └── usecases/                 # Base usecase abstract class
├── features/                     # Feature modules
│   ├── auth/                     # Authentication feature
│   │   ├── domain/               # Business logic
│   │   │   ├── entities/         # Core business objects
│   │   │   ├── repositories/     # Abstract interfaces
│   │   │   └── usecases/         # Business logic
│   │   ├── data/                 # Data layer
│   │   │   ├── datasources/      # Data sources
│   │   │   ├── models/           # Data models
│   │   │   └── repositories/     # Repository implementations
│   │   └── presentation/         # UI layer
│   │       ├── bloc/             # BLoC state management
│   │       ├── pages/            # UI screens
│   │       └── widgets/          # Reusable widgets
│   └── home/                     # Home feature
│       └── presentation/
│           └── pages/
├── app.dart                      # App configuration
└── main.dart                     # App entry point
```

## 🎯 Root-Level Components

### **1. DI (Dependency Injection)**
- **Location**: `lib/di/` - Root level for maximum scalability
- **Purpose**: Centralized dependency management
- **Benefits**: Easy to add/remove features, clean dependency graph

### **2. Shared Components**
- **Location**: `lib/shared/` - Root level for maximum reusability
- **Purpose**: Reusable components across all features
- **Benefits**: DRY principle, consistent patterns, easy maintenance

## 📦 Shared Layer Components

### **Domain Layer** (`shared/domain/`)
```dart
// Base entity for all entities
abstract class BaseEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

// Base repository for all repositories
abstract class BaseRepository<T extends BaseEntity> {
  Future<Either<Failure, T>> getById(String id);
  Future<Either<Failure, List<T>>> getAll();
  Future<Either<Failure, T>> create(T entity);
  Future<Either<Failure, T>> update(T entity);
  Future<Either<Failure, bool>> delete(String id);
}

// Base usecase patterns
abstract class BaseUseCase<Type, Params> implements UseCase<Type, Params>
abstract class SingleUseCase<Type, Param> implements UseCase<Type, Param>
abstract class NoParamUseCase<Type> implements UseCase<Type, NoParams>
```

### **Data Layer** (`shared/data/`)
```dart
// Base model for all models
abstract class BaseModel<T extends BaseEntity> extends Equatable {
  T toEntity();
  factory BaseModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

// Base data source patterns
abstract class BaseDataSource<T extends BaseModel>
abstract class BaseRemoteDataSource<T extends BaseModel>
abstract class BaseLocalDataSource<T extends BaseModel>
```

### **Presentation Layer** (`shared/presentation/`)
```dart
// Base BLoC patterns
abstract class BaseEvent extends Equatable
abstract class BaseState extends Equatable
abstract class BaseBloc<Event extends BaseEvent, State extends BaseState>

// Base widget with BLoC support
abstract class BaseWidget<B extends BaseBloc<E, S>, E extends BaseEvent, S extends BaseState>
```

### **Utilities** (`shared/utils/`)
```dart
// Shared validators
class Validators {
  static bool isValidEmail(String email)
  static bool isValidPassword(String password)
  static bool isValidName(String name)
  static String getPasswordStrength(String password)
}
```

## 🚀 How to Use This Architecture

### **1. Creating a New Feature**

#### **Step 1: Create Feature Structure**
```
features/new_feature/
├── domain/
│   ├── entities/
│   │   └── new_feature_entity.dart
│   ├── repositories/
│   │   └── new_feature_repository.dart
│   └── usecases/
│       └── get_new_feature_usecase.dart
├── data/
│   ├── datasources/
│   │   ├── new_feature_remote_data_source.dart
│   │   └── new_feature_local_data_source.dart
│   ├── models/
│   │   └── new_feature_model.dart
│   └── repositories/
│       └── new_feature_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── new_feature_bloc.dart
    │   ├── new_feature_event.dart
    │   └── new_feature_state.dart
    ├── pages/
    │   └── new_feature_page.dart
    └── widgets/
        └── new_feature_widget.dart
```

#### **Step 2: Extend Base Classes**
```dart
// Entity
class NewFeatureEntity extends BaseEntity {
  final String title;
  final String description;
  
  const NewFeatureEntity({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.title,
    required this.description,
  });
  
  @override
  List<Object?> get props => [id, createdAt, updatedAt, title, description];
}

// Repository
abstract class NewFeatureRepository extends BaseRepository<NewFeatureEntity> {
  // Add feature-specific methods
}

// Use Case
class GetNewFeatureUseCase extends SingleUseCase<NewFeatureEntity, String> {
  final NewFeatureRepository repository;
  
  GetNewFeatureUseCase(this.repository);
  
  @override
  Future<Either<Failure, NewFeatureEntity>> call(String id) async {
    return await repository.getById(id);
  }
}

// Model
class NewFeatureModel extends BaseModel<NewFeatureEntity> {
  final String title;
  final String description;
  
  const NewFeatureModel({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.title,
    required this.description,
  });
  
  @override
  NewFeatureEntity toEntity() {
    return NewFeatureEntity(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      description: description,
    );
  }
  
  factory NewFeatureModel.fromJson(Map<String, dynamic> json) {
    return NewFeatureModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [id, createdAt, updatedAt, title, description];
}

// BLoC
class NewFeatureBloc extends BaseBloc<NewFeatureEvent, NewFeatureState> {
  final GetNewFeatureUseCase getNewFeatureUseCase;
  
  NewFeatureBloc({required this.getNewFeatureUseCase}) 
    : super(NewFeatureInitial()) {
    on<GetNewFeatureRequested>(_onGetNewFeatureRequested);
  }
  
  Future<void> _onGetNewFeatureRequested(
    GetNewFeatureRequested event,
    Emitter<NewFeatureState> emit,
  ) async {
    emit(NewFeatureLoading());
    
    final result = await getNewFeatureUseCase(event.id);
    
    result.fold(
      (failure) => emit(NewFeatureFailure(failure.message)),
      (entity) => emit(NewFeatureSuccess(entity)),
    );
  }
}

// Widget
class NewFeaturePage extends BaseWidget<NewFeatureBloc, NewFeatureEvent, NewFeatureState> {
  @override
  NewFeatureBloc createBloc(BuildContext context) {
    return di.sl<NewFeatureBloc>();
  }
  
  @override
  Widget buildWidget(BuildContext context, NewFeatureState state) {
    if (state is NewFeatureLoading) {
      return buildLoadingWidget();
    } else if (state is NewFeatureSuccess) {
      return NewFeatureWidget(entity: state.entity);
    } else if (state is NewFeatureFailure) {
      return buildErrorWidget(state.message);
    }
    return const Center(child: Text('No data'));
  }
}
```

#### **Step 3: Create DI Module**
```dart
// di/new_feature_module.dart
class NewFeatureModule {
  static void register() {
    final sl = GetIt.instance;
    
    // BLoC
    sl.registerFactory(() => NewFeatureBloc(getNewFeatureUseCase: sl()));
    
    // Use cases
    sl.registerLazySingleton(() => GetNewFeatureUseCase(sl()));
    
    // Repository
    sl.registerLazySingleton<NewFeatureRepository>(
      () => NewFeatureRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ),
    );
    
    // Data sources
    sl.registerLazySingleton<NewFeatureRemoteDataSource>(
      () => NewFeatureRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<NewFeatureLocalDataSource>(
      () => NewFeatureLocalDataSourceImpl(),
    );
  }
}
```

#### **Step 4: Register Module**
```dart
// In app_module.dart
class AppModule {
  static void register() {
    SharedModule.register();
    CoreModule.register();
    AuthModule.register();
    NewFeatureModule.register(); // Add this line
  }
}
```

## 🎯 Best Practices

### **1. Inheritance Hierarchy**
- **Entities**: Extend `BaseEntity`
- **Repositories**: Extend `BaseRepository<T>`
- **Use Cases**: Extend `BaseUseCase`, `SingleUseCase`, or `NoParamUseCase`
- **Models**: Extend `BaseModel<T>`
- **Data Sources**: Extend `BaseDataSource<T>`
- **BLoCs**: Extend `BaseBloc<E, S>`
- **Widgets**: Extend `BaseWidget<B, E, S>`

### **2. Naming Conventions**
- **Entities**: `FeatureEntity`
- **Repositories**: `FeatureRepository`
- **Use Cases**: `GetFeatureUseCase`, `CreateFeatureUseCase`
- **Models**: `FeatureModel`
- **Data Sources**: `FeatureRemoteDataSource`, `FeatureLocalDataSource`
- **BLoCs**: `FeatureBloc`
- **Events**: `GetFeatureRequested`, `CreateFeatureRequested`
- **States**: `FeatureInitial`, `FeatureLoading`, `FeatureSuccess`, `FeatureFailure`

### **3. Error Handling**
- Use `Either<Failure, Success>` pattern
- Handle errors in BLoC with proper state management
- Provide meaningful error messages

### **4. Testing Strategy**
- Test each layer independently
- Mock dependencies using interfaces
- Test BLoC with `blocTest`

## 📊 Benefits of This Architecture

### **1. Scalability**
- Easy to add new features
- Modular dependency injection
- Clear separation of concerns

### **2. Maintainability**
- Consistent patterns across features
- Reusable base classes
- Clear structure

### **3. Testability**
- Each layer can be tested independently
- Easy to mock dependencies
- Clear test boundaries

### **4. Team Collaboration**
- Multiple teams can work independently
- Clear ownership boundaries
- Consistent code patterns

### **5. Performance**
- Lazy loading of dependencies
- Efficient memory usage
- Fast startup

This architecture provides the **best possible foundation** for building large-scale, maintainable Flutter applications with proper separation of concerns and team collaboration! 🚀 