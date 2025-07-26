// Shared module for dependency injection

class SharedModule {
  static void register() {
    // Register shared dependencies here
    // This module will contain dependencies that are shared across multiple features
    
    // Example: Shared services, utilities, etc.
    // sl.registerLazySingleton<SharedService>(() => SharedServiceImpl());
  }
}
