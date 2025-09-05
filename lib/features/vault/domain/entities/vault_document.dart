import 'package:equatable/equatable.dart';
import 'package:hushh_user_app/features/vault/domain/entities/document_metadata.dart';

class VaultDocument extends Equatable {
  final String id;
  final String userId;
  final String filename;
  final String originalName;
  final String fileType;
  final int fileSize;
  final DateTime uploadDate;
  final DateTime lastModified;
  final DocumentMetadata metadata;
  final DocumentContent content;
  final bool isProcessed;
  final bool isActive;

  const VaultDocument({
    required this.id,
    required this.userId,
    required this.filename,
    required this.originalName,
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    required this.lastModified,
    required this.metadata,
    required this.content,
    required this.isProcessed,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    filename,
    originalName,
    fileType,
    fileSize,
    uploadDate,
    lastModified,
    metadata,
    content,
    isProcessed,
    isActive,
  ];
}

class DocumentContent extends Equatable {
  final String extractedText;
  final String summary;
  final List<String> keywords;
  final int wordCount;

  const DocumentContent({
    required this.extractedText,
    required this.summary,
    required this.keywords,
    required this.wordCount,
  });

  @override
  List<Object?> get props => [extractedText, summary, keywords, wordCount];
}
