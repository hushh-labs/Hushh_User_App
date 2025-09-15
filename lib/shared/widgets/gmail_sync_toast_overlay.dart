import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gmail_sync_status_service.dart';
import '../../features/pda/data/services/supabase_gmail_service.dart';

/// Toast notification widget for Gmail sync status and live logs
class GmailSyncToastOverlay extends StatefulWidget {
  final Widget child;

  const GmailSyncToastOverlay({super.key, required this.child});

  @override
  State<GmailSyncToastOverlay> createState() => _GmailSyncToastOverlayState();
}

class _GmailSyncToastOverlayState extends State<GmailSyncToastOverlay>
    with TickerProviderStateMixin {
  final GmailSyncStatusService _syncStatusService = GmailSyncStatusService();
  final SupabaseGmailService _gmailService = SupabaseGmailService();

  // Stream subscriptions
  StreamSubscription<GmailSyncStatus>? _statusSubscription;
  StreamSubscription<GmailSyncLog>? _logSubscription;

  // Current state
  GmailSyncStatus? _currentStatus;
  GmailSyncLog? _currentLog;
  bool _isGmailConnected = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  // Toast display timer
  Timer? _hideTimer;

  // Constants
  static const Duration _toastDuration = Duration(seconds: 4);
  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    await _syncStatusService.initialize();

    // Check Gmail connection status
    await _checkGmailConnection();

    // Listen to status updates
    _statusSubscription = _syncStatusService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });

        // Only show toasts if Gmail is connected
        if (_isGmailConnected) {
          if (status.isActive) {
            _showToast();
            _updateProgress(status.overallProgress);
          } else if (status.isCompleted || status.isFailed) {
            // Show completion/failure toast briefly, then hide
            _showToast();
            _scheduleHide(const Duration(seconds: 3));
          }
        }
      }
    });

    // Listen to individual log updates
    _logSubscription = _syncStatusService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _currentLog = log;
        });

        // Show new log messages briefly, but only if Gmail is connected
        if (_currentStatus?.isActive == true && _isGmailConnected) {
          HapticFeedback.selectionClick();
          _resetHideTimer();
        }
      }
    });
  }

  /// Check if Gmail is connected before showing any toasts
  Future<void> _checkGmailConnection() async {
    try {
      final isConnected = await _gmailService.isGmailConnected();
      if (mounted) {
        setState(() {
          _isGmailConnected = isConnected;
        });
      }
      debugPrint('🔍 [GMAIL SYNC TOAST] Gmail connected: $isConnected');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC TOAST] Error checking Gmail connection: $e');
      if (mounted) {
        setState(() {
          _isGmailConnected = false;
        });
      }
    }
  }

  void _showToast() {
    _hideTimer?.cancel();
    if (!_slideController.isCompleted) {
      _slideController.forward();
    }
  }

  void _hideToast() {
    _hideTimer?.cancel();
    if (_slideController.isCompleted) {
      _slideController.reverse();
    }
  }

  void _scheduleHide(Duration duration) {
    _hideTimer?.cancel();
    _hideTimer = Timer(duration, _hideToast);
  }

  void _resetHideTimer() {
    if (_currentStatus?.isActive == true) {
      _scheduleHide(_toastDuration);
    }
  }

  void _updateProgress(double progress) {
    _progressController.animateTo(progress.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,

          // Toast overlay - only show if Gmail is connected
          if (_currentStatus != null &&
              _isGmailConnected &&
              (_currentStatus!.isActive ||
                  _currentStatus!.isCompleted ||
                  _currentStatus!.isFailed))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildToastContent(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToastContent() {
    if (_currentStatus == null) return const SizedBox.shrink();

    final status = _currentStatus!;
    final log = _currentLog ?? status.latestLog;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getToastBackgroundColor(status),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: status.isActive ? null : _hideToast,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildStatusIcon(status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusTitle(status),
                              style: TextStyle(
                                color: _getTextColor(status),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (log != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                log.displayMessage,
                                style: TextStyle(
                                  color: _getTextColor(status).withOpacity(0.8),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!status.isActive)
                        GestureDetector(
                          onTap: _hideToast,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: _getTextColor(status).withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Progress bar for active sync
                  if (status.isActive) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getTextColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getTextColor(status),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          status.currentStage.stageDisplayName,
                          style: TextStyle(
                            color: _getTextColor(status).withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(status.overallProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: _getTextColor(status).withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(GmailSyncStatus status) {
    if (status.isFailed) {
      return Icon(Icons.error_outline, color: _getTextColor(status), size: 20);
    } else if (status.isCompleted) {
      return Icon(
        Icons.check_circle_outline,
        color: _getTextColor(status),
        size: 20,
      );
    } else {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(status)),
        ),
      );
    }
  }

  String _getStatusTitle(GmailSyncStatus status) {
    if (status.isFailed) {
      return 'Gmail Sync Failed';
    } else if (status.isCompleted) {
      final total = status.metadata?['totalEmails'] ?? 0;
      final newEmails = status.metadata?['newEmails'] ?? 0;
      if (total > 0) {
        return 'Gmail Sync Complete ($total emails, $newEmails new)';
      }
      return 'Gmail Sync Complete';
    } else {
      return 'Syncing Gmail...';
    }
  }

  Color _getToastBackgroundColor(GmailSyncStatus status) {
    if (status.isFailed) {
      return Colors.red.shade50;
    } else if (status.isCompleted) {
      return Colors.green.shade50;
    } else {
      return Colors.blue.shade50;
    }
  }

  Color _getTextColor(GmailSyncStatus status) {
    if (status.isFailed) {
      return Colors.red.shade700;
    } else if (status.isCompleted) {
      return Colors.green.shade700;
    } else {
      return Colors.blue.shade700;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _statusSubscription?.cancel();
    _logSubscription?.cancel();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

/// Utility extension to easily wrap any widget with Gmail sync toast overlay
extension GmailSyncToastExtension on Widget {
  Widget withGmailSyncToast() {
    return GmailSyncToastOverlay(child: this);
  }
}
