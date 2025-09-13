import 'package:flutter/material.dart';
import '../components/pda_loading_animation.dart';

/// Dialog that shows PDA loading animation during sync operations
class SyncProgressDialog extends StatefulWidget {
  final String title;
  final String description;
  final Stream<SyncProgressStatus>? progressStream;
  final VoidCallback? onCompleted;

  const SyncProgressDialog({
    super.key,
    required this.title,
    required this.description,
    this.progressStream,
    this.onCompleted,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  SyncProgressStatus? _currentStatus;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Listen to progress stream if provided
    widget.progressStream?.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
          _isCompleted = status.isCompleted;
        });

        if (status.isCompleted) {
          // Auto-close dialog after completion
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
              widget.onCompleted?.call();
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isCompleted, // Only allow back when completed
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PDA Animation - with proper constraints and overflow handling
              Container(
                height: 180,
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PdaLoadingAnimation(
                  isLoading: true, // Keep animation running until dialog closes
                  onAnimationComplete: () {},
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                _isCompleted ? 'Sync Complete!' : widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                _isCompleted
                    ? 'Data has been synced successfully'
                    : _currentStatus?.currentStep ?? widget.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Progress bar (if progress stream is provided)
              if (_currentStatus != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${(_currentStatus!.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _currentStatus!.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isCompleted ? Colors.green : const Color(0xFFA342FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Completion message
              if (_isCompleted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sync completed successfully!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status class for sync progress
class SyncProgressStatus {
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final bool isCompleted;
  final String? errorMessage;

  const SyncProgressStatus({
    required this.progress,
    required this.currentStep,
    required this.isCompleted,
    this.errorMessage,
  });
}

/// Convenience function to show sync progress dialog
Future<void> showSyncProgressDialog(
  BuildContext context, {
  required String title,
  required String description,
  Stream<SyncProgressStatus>? progressStream,
  VoidCallback? onCompleted,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncProgressDialog(
      title: title,
      description: description,
      progressStream: progressStream,
      onCompleted: onCompleted,
    ),
  );
}
