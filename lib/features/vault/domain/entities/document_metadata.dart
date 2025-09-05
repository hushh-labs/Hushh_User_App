import 'package:equatable/equatable.dart';

class DocumentMetadata extends Equatable {
  final String title;
  final String description;
  final List<String> tags;
  final String category;

  const DocumentMetadata({
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        tags,
        category,
      ];
}
