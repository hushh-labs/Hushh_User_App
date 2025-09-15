import 'dart:async';
import 'package:flutter/material.dart';
import '../services/google_meet_sync_status_service.dart';

class GoogleMeetSyncToastOverlay extends StatefulWidget {
  final Widget child;

  const GoogleMeetSyncToastOverlay({super.key, required this.child});

  @override
  State<GoogleMeetSyncToastOverlay> createState() =>
      _GoogleMeetSyncToastOverlayState();
}

class _GoogleMeetSyncToastOverlayState extends State<GoogleMeetSyncToastOverlay>
    with TickerProviderStateMixin {
  final GoogleMeetSyncStatusService _syncStatusService =
      GoogleMeetSyncStatusService();
  StreamSubscription<GoogleMeetSyncStatus>? _statusSubscription;

  OverlayEntry? _toastOverlay;
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;
  Timer? _hideTimer;

  bool _isToastVisible = false;
  GoogleMeetSyncStatus? _currentStatus;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToSyncStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
        );
  }

  void _listenToSyncStatus() {
    _statusSubscription = _syncStatusService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });

      if (status.isActive) {
        _showToast(status);
      } else if (status.isCompleted || status.isFailed) {
        _showCompletionToast(status);
      }
    });
  }

  void _showToast(GoogleMeetSyncStatus status) {
    if (_isToastVisible) {
      // Update existing toast
      _updateToast();
      return;
    }

    _isToastVisible = true;
    _hideTimer?.cancel();

    _toastOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: _slideAnimation!,
          child: Material(
            color: Colors.transparent,
            child: _buildToastContent(status),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_toastOverlay!);
    _animationController!.forward();
  }

  void _showCompletionToast(GoogleMeetSyncStatus status) {
    // Hide active toast first if showing
    if (_isToastVisible) {
      _hideToast();
    }

    // Show completion message briefly
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _isToastVisible = true;

        _toastOverlay = OverlayEntry(
          builder: (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation!,
              child: Material(
                color: Colors.transparent,
                child: _buildCompletionToastContent(status),
              ),
            ),
          ),
        );

        Overlay.of(context).insert(_toastOverlay!);
        _animationController!.forward();

        // Auto-hide completion toast after 4 seconds
        _hideTimer = Timer(const Duration(seconds: 4), () {
          _hideToast();
        });
      }
    });
  }

  void _updateToast() {
    if (_toastOverlay != null) {
      _toastOverlay!.markNeedsBuild();
    }
  }

  void _hideToast() {
    if (!_isToastVisible) return;

    _hideTimer?.cancel();
    _animationController!.reverse().then((_) {
      if (_toastOverlay != null) {
        _toastOverlay!.remove();
        _toastOverlay = null;
      }
      _isToastVisible = false;
    });
  }

  Widget _buildToastContent(GoogleMeetSyncStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.video_call_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Meet Sync Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status.totalMeetings > 0)
                      Text(
                        'Processing ${status.processedMeetings}/${status.totalMeetings} meetings',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),

          // Progress bar
          if (status.totalMeetings > 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: LinearProgressIndicator(
                value: status.totalMeetings > 0
                    ? status.processedMeetings / status.totalMeetings
                    : null,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],

          // Latest logs
          if (status.logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Logs:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...status.logs
                      .take(3)
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _getLogLevelColor(log.level),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (status.logs.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '... and ${status.logs.length - 3} more',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionToastContent(GoogleMeetSyncStatus status) {
    final isSuccess = status.isCompleted && !status.isFailed;
    final color = isSuccess ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSuccess
                      ? 'Google Meet Sync Complete!'
                      : 'Google Meet Sync Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSuccess && status.totalMeetings > 0)
                  Text(
                    'Successfully processed ${status.totalMeetings} meetings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  )
                else if (!isSuccess && status.error != null)
                  Text(
                    status.error!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red.shade300;
      case 'warning':
        return Colors.orange.shade300;
      case 'success':
        return Colors.green.shade300;
      default:
        return Colors.white;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _statusSubscription?.cancel();
    _animationController?.dispose();
    if (_toastOverlay != null) {
      _toastOverlay!.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
