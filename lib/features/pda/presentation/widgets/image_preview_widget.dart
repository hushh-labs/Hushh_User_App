import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hushh_user_app/features/pda/presentation/pages/pda_simple_page.dart'; // For primaryPurple

class ImagePreviewWidget extends StatefulWidget {
  final List<File> selectedImageFiles;
  final VoidCallback onClearAll;
  final Function(int index) onRemoveImage;
  final bool hidePreview;

  const ImagePreviewWidget({
    Key? key,
    required this.selectedImageFiles,
    required this.onClearAll,
    required this.onRemoveImage,
    this.hidePreview = false,
  }) : super(key: key);

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedImageFiles.isEmpty || widget.hidePreview) {
      return const SizedBox.shrink();
    }

    // Access primaryPurple from PdaSimplePage or define it locally if preferred
    const Color primaryPurple = Color(0xFFA342FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.selectedImageFiles.length} image${widget.selectedImageFiles.length > 1 ? 's' : ''} selected',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: widget.onClearAll,
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80, // Fixed height for horizontal scroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedImageFiles.length,
              itemBuilder: (context, index) {
                final file = widget.selectedImageFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => widget.onRemoveImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
