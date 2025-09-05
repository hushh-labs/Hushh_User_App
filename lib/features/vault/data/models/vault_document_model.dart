import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/data/models/document_metadata_model.dart';

class VaultDocumentModel extends VaultDocument {
  const VaultDocumentModel({
    required super.id,
    required super.userId,
    required super.filename,
    required super.originalName,
    required super.fileType,
    required super.fileSize,
    required super.uploadDate,
    required super.lastModified,
    required super.metadata,
    required super.content,
    required super.isProcessed,
    required super.isActive,
  });

  factory VaultDocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VaultDocumentModel(
      id: doc.id,
      userId: data['userId'] as String,
      filename: data['filename'] as String,
      originalName: data['originalName'] as String,
      fileType: data['fileType'] as String,
      fileSize: data['fileSize'] as int,
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      metadata: DocumentMetadataModel.fromMap(data['metadata'] as Map<String, dynamic>),
      content: DocumentContentModel.fromMap(data['content'] as Map<String, dynamic>),
      isProcessed: data['isProcessed'] as bool,
      isActive: data['isActive'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'filename': filename,
      'originalName': originalName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'lastModified': Timestamp.fromDate(lastModified),
      'metadata': (metadata as DocumentMetadataModel).toMap(),
      'content': (content as DocumentContentModel).toMap(),
      'isProcessed': isProcessed,
      'isActive': isActive,
    };
  }
}

class DocumentContentModel extends DocumentContent {
  const DocumentContentModel({
    required super.extractedText,
    required super.summary,
    required super.keywords,
    required super.wordCount,
  });

  factory DocumentContentModel.fromMap(Map<String, dynamic> map) {
    return DocumentContentModel(
      extractedText: map['extractedText'] as String,
      summary: map['summary'] as String,
      keywords: List<String>.from(map['keywords'] as List),
      wordCount: map['wordCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'extractedText': extractedText,
      'summary': summary,
      'keywords': keywords,
      'wordCount': wordCount,
    };
  }
}
