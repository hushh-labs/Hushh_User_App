import 'package:flutter/material.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// ChatGPT-style colors matching PDA design
class VaultTheme {
  static const Color darkBackground = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF); // White sidebar
  static const Color userBubbleColor = Color(0xFF000000); // Black for user
  static const Color assistantBubbleColor = Color(
    0xFFF8F8F8,
  ); // Very light gray
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF000000); // Pure black text
  static const Color hintColor = Color(0xFF666666); // Dark gray for hints
  static const Color sidebarTextColor = Color(
    0xFF000000,
  ); // Black text for sidebar
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color successGreen = Color(0xFF4CAF50);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 12.0;
}

class DocumentPreviewWidget extends StatelessWidget {
  final VaultDocument document;

  const DocumentPreviewWidget({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: VaultTheme.lightBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with black background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: VaultTheme.userBubbleColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: VaultTheme.assistantBubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultTheme.borderColor),
                    ),
                    child: _getFileIcon(document.fileType),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.metadata.title.isNotEmpty
                              ? document.metadata.title
                              : document.originalName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${document.fileType.toUpperCase()} • ${_formatBytes(document.fileSize)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document info section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VaultTheme.assistantBubbleColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: VaultTheme.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Document Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VaultTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Uploaded',
                            DateFormat(
                              'MMM d, yyyy • h:mm a',
                            ).format(document.uploadDate),
                          ),
                          _buildInfoRow(
                            'File Size',
                            _formatBytes(document.fileSize),
                          ),
                          _buildInfoRow(
                            'File Type',
                            document.fileType.toUpperCase(),
                          ),
                          if (document.metadata.category.isNotEmpty)
                            _buildInfoRow(
                              'Category',
                              document.metadata.category,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Content preview section
                    const Text(
                      'Content Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VaultTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: VaultTheme.assistantBubbleColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: VaultTheme.borderColor,
                            width: 1,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            document.content.extractedText.isNotEmpty
                                ? document.content.extractedText
                                : 'No preview available or text not extracted yet.\n\nThis document has been uploaded to your vault and will be accessible to your AI assistant for context-aware responses.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: VaultTheme.textColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: VaultTheme.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // TODO: Implement download functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Download functionality coming soon!',
                                ),
                                backgroundColor: VaultTheme.userBubbleColor,
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download,
                                  color: VaultTheme.textColor,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Download',
                                  style: TextStyle(
                                    color: VaultTheme.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: VaultTheme.userBubbleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileType) {
    IconData iconData;
    Color iconColor;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'txt':
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.white;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: VaultTheme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: VaultTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Helper for log and pow, usually from 'dart:math'
  double log(num x, [num? base]) {
    if (base == null) return math.log(x);
    return math.log(x) / math.log(base);
  }

  num pow(num x, num exponent) {
    return math.pow(x, exponent);
  }
}
