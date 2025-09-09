import '../../domain/entities/drive_file.dart';

class DriveFileModel {
  final String id;
  final String fileId;
  final String userUid;
  final String? name;
  final String? mimeType;
  final int? size;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final bool? shared;
  final String? webViewLink;
  final String? thumbnailLink;
  final bool trashed;
  final DateTime insertedAt;

  DriveFileModel({
    required this.id,
    required this.fileId,
    required this.userUid,
    this.name,
    this.mimeType,
    this.size,
    this.createdTime,
    this.modifiedTime,
    this.shared,
    this.webViewLink,
    this.thumbnailLink,
    this.trashed = false,
    DateTime? insertedAt,
  }) : insertedAt = insertedAt ?? DateTime.now();

  DriveFile toEntity() => DriveFile(
    id: id,
    fileId: fileId,
    userUid: userUid,
    name: name,
    mimeType: mimeType,
    size: size,
    createdTime: createdTime,
    modifiedTime: modifiedTime,
    shared: shared,
    webViewLink: webViewLink,
    thumbnailLink: thumbnailLink,
    trashed: trashed,
    insertedAt: insertedAt,
  );

  static DriveFileModel fromEntity(DriveFile entity) => DriveFileModel(
    id: entity.id,
    fileId: entity.fileId,
    userUid: entity.userUid,
    name: entity.name,
    mimeType: entity.mimeType,
    size: entity.size,
    createdTime: entity.createdTime,
    modifiedTime: entity.modifiedTime,
    shared: entity.shared,
    webViewLink: entity.webViewLink,
    thumbnailLink: entity.thumbnailLink,
    trashed: entity.trashed,
    insertedAt: entity.insertedAt,
  );
}
