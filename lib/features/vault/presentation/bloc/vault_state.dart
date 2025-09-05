import 'package:equatable/equatable.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';

abstract class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object> get props => [];
}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final List<VaultDocument> documents;

  const VaultLoaded({this.documents = const []});

  @override
  List<Object> get props => [documents];
}

class VaultError extends VaultState {
  final String message;

  const VaultError(this.message);

  @override
  List<Object> get props => [message];
}

class VaultDocumentUploading extends VaultState {
  final double progress;

  const VaultDocumentUploading(this.progress);

  @override
  List<Object> get props => [progress];
}

class VaultDocumentUploaded extends VaultState {
  final VaultDocument document;

  const VaultDocumentUploaded(this.document);

  @override
  List<Object> get props => [document];
}
