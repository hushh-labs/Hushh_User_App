class DriveFile {
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

  DriveFile({
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
}
