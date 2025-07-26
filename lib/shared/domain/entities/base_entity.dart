// Base entity for shared domain entities
import 'package:equatable/equatable.dart';

abstract class BaseEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BaseEntity({required this.id, required this.createdAt, this.updatedAt});

  @override
  List<Object?> get props => [id, createdAt, updatedAt];
}
