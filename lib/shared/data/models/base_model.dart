// Base model for shared data models
import 'package:equatable/equatable.dart';
import '../../domain/entities/base_entity.dart';

abstract class BaseModel<T extends BaseEntity> extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to entity
  T toEntity();

  // Convert from JSON
  factory BaseModel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented');
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('toJson must be implemented');
  }

  @override
  List<Object?> get props => [id, createdAt, updatedAt];
} 