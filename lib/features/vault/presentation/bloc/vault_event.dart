import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object> get props => [];
}

class LoadVaultDocuments extends VaultEvent {
  final String userId;

  const LoadVaultDocuments({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UploadVaultDocument extends VaultEvent {
  final String userId;
  final File file;
  final String filename;

  const UploadVaultDocument({
    required this.userId,
    required this.file,
    required this.filename,
  });

  @override
  List<Object> get props => [userId, file, filename];
}

class DeleteVaultDocument extends VaultEvent {
  final String documentId;

  const DeleteVaultDocument({required this.documentId});

  @override
  List<Object> get props => [documentId];
}

class ExtractVaultDocumentContent extends VaultEvent {
  final String documentId;

  const ExtractVaultDocumentContent({required this.documentId});

  @override
  List<Object> get props => [documentId];
}
