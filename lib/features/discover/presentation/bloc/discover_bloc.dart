import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/discover_entity.dart';

// Events
abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiscoverData extends DiscoverEvent {
  const LoadDiscoverData();
}

class FilterByCategory extends DiscoverEvent {
  final String category;
  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchDiscover extends DiscoverEvent {
  final String query;
  const SearchDiscover(this.query);

  @override
  List<Object?> get props => [query];
}

// States
abstract class DiscoverState extends Equatable {
  const DiscoverState();

  @override
  List<Object?> get props => [];
}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<DiscoverEntity> items;
  final List<DiscoverCategoryEntity> categories;
  final String? selectedCategory;
  final String? searchQuery;

  const DiscoverLoaded({
    required this.items,
    required this.categories,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [items, categories, selectedCategory, searchQuery];

  DiscoverLoaded copyWith({
    List<DiscoverEntity>? items,
    List<DiscoverCategoryEntity>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return DiscoverLoaded(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class DiscoverError extends DiscoverState {
  final String message;

  const DiscoverError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc() : super(DiscoverInitial()) {
    on<LoadDiscoverData>(_onLoadDiscoverData);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchDiscover>(_onSearchDiscover);
  }

  void _onLoadDiscoverData(
    LoadDiscoverData event,
    Emitter<DiscoverState> emit,
  ) async {
    emit(DiscoverLoading());

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      final items = _getDummyDiscoverItems();
      final categories = _getDummyCategories();

      emit(DiscoverLoaded(items: items, categories: categories));
    } catch (e) {
      emit(DiscoverError('Failed to load discover data: $e'));
    }
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<DiscoverState> emit,
  ) {
    final currentState = state;
    if (currentState is DiscoverLoaded) {
      final updatedCategories = currentState.categories.map((category) {
        return category.copyWith(isSelected: category.id == event.category);
      }).toList();

      final filteredItems = event.category == 'all'
          ? currentState.items
          : currentState.items
                .where((item) => item.category == event.category)
                .toList();

      emit(
        currentState.copyWith(
          items: filteredItems,
          categories: updatedCategories,
          selectedCategory: event.category,
        ),
      );
    }
  }

  void _onSearchDiscover(SearchDiscover event, Emitter<DiscoverState> emit) {
    final currentState = state;
    if (currentState is DiscoverLoaded) {
      final filteredItems = event.query.isEmpty
          ? currentState.items
          : currentState.items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(
                        event.query.toLowerCase(),
                      ) ||
                      item.description.toLowerCase().contains(
                        event.query.toLowerCase(),
                      ) ||
                      item.category.toLowerCase().contains(
                        event.query.toLowerCase(),
                      ),
                )
                .toList();

      emit(
        currentState.copyWith(
          items: filteredItems,
          searchQuery: event.query.isEmpty ? null : event.query,
        ),
      );
    }
  }

  // Dummy data generators
  List<DiscoverEntity> _getDummyDiscoverItems() {
    return [
      DiscoverEntity(
        id: '1',
        title: 'Amazing Tech Gadgets',
        description:
            'Discover the latest technology gadgets that will revolutionize your daily life.',
        imageUrl: 'https://picsum.photos/300/200?random=1',
        category: 'Technology',
        rating: 4.5,
        views: 1250,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      DiscoverEntity(
        id: '2',
        title: 'Healthy Living Tips',
        description:
            'Essential tips for maintaining a healthy lifestyle and wellness routine.',
        imageUrl: 'https://picsum.photos/300/200?random=2',
        category: 'Health',
        rating: 4.8,
        views: 2100,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      DiscoverEntity(
        id: '3',
        title: 'Creative Art Projects',
        description:
            'Explore amazing art projects and creative ideas for all skill levels.',
        imageUrl: 'https://picsum.photos/300/200?random=3',
        category: 'Art',
        rating: 4.2,
        views: 890,
        createdAt: DateTime.now().subtract(Duration(hours: 6)),
      ),
      DiscoverEntity(
        id: '4',
        title: 'Cooking Masterclass',
        description:
            'Learn professional cooking techniques and recipes from top chefs.',
        imageUrl: 'https://picsum.photos/300/200?random=4',
        category: 'Food',
        rating: 4.7,
        views: 3400,
        createdAt: DateTime.now().subtract(Duration(hours: 3)),
      ),
      DiscoverEntity(
        id: '5',
        title: 'Travel Adventures',
        description:
            'Incredible travel destinations and adventure stories from around the world.',
        imageUrl: 'https://picsum.photos/300/200?random=5',
        category: 'Travel',
        rating: 4.6,
        views: 1800,
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
      ),
      DiscoverEntity(
        id: '6',
        title: 'Fitness Motivation',
        description:
            'Get motivated with these amazing fitness routines and workout plans.',
        imageUrl: 'https://picsum.photos/300/200?random=6',
        category: 'Fitness',
        rating: 4.4,
        views: 950,
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ];
  }

  List<DiscoverCategoryEntity> _getDummyCategories() {
    return [
      const DiscoverCategoryEntity(
        id: 'all',
        name: 'All',
        icon: '🌟',
        isSelected: true,
      ),
      const DiscoverCategoryEntity(
        id: 'Technology',
        name: 'Technology',
        icon: '💻',
      ),
      const DiscoverCategoryEntity(id: 'Health', name: 'Health', icon: '🏥'),
      const DiscoverCategoryEntity(id: 'Art', name: 'Art', icon: '🎨'),
      const DiscoverCategoryEntity(id: 'Food', name: 'Food', icon: '🍕'),
      const DiscoverCategoryEntity(id: 'Travel', name: 'Travel', icon: '✈️'),
      const DiscoverCategoryEntity(id: 'Fitness', name: 'Fitness', icon: '💪'),
    ];
  }
}
