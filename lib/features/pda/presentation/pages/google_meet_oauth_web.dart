import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;

class GoogleMeetOAuthWeb extends StatefulWidget {
  final String oauthUrl;
  final String redirectUri;
  final String providerName;

  const GoogleMeetOAuthWeb({
    super.key,
    required this.oauthUrl,
    required this.redirectUri,
    this.providerName = 'Google Meet',
  });

  @override
  State<GoogleMeetOAuthWeb> createState() => _GoogleMeetOAuthWebState();
}

class _GoogleMeetOAuthWebState extends State<GoogleMeetOAuthWeb> {
  bool _isLoading = false;
  String? _error;
  html.WindowBase? _oauthWindow;

  @override
  void initState() {
    super.initState();
    _startOAuthFlow();
  }

  @override
  void dispose() {
    _closeOAuthWindow();
    html.window.removeEventListener('message', _handlePostMessage);
    super.dispose();
  }

  void _startOAuthFlow() {
    if (!kIsWeb) {
      _showError('This OAuth method is only available on web');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Listen for postMessage from OAuth callback
      html.window.addEventListener('message', _handlePostMessage);

      // Open OAuth URL in new popup window
      _oauthWindow = html.window.open(
        widget.oauthUrl,
        '${widget.providerName}_oauth',
        'width=500,height=600,scrollbars=yes,resizable=yes',
      );

      if (_oauthWindow == null) {
        _showError('Popup blocked. Please allow popups for this site.');
        return;
      }

      // Check if window is closed (user cancelled)
      _checkWindowClosed();
    } catch (e) {
      debugPrint('❌ [WEB OAUTH] Error starting OAuth: $e');
      _showError('Failed to start OAuth flow: $e');
    }
  }

  void _handlePostMessage(html.Event event) {
    if (event is! html.MessageEvent) return;

    try {
      final data = event.data;
      debugPrint('🌐 [WEB OAUTH] Received postMessage: $data');

      if (data is Map && data['oauth_result'] != null) {
        final result = data['oauth_result'];

        if (result['success'] == true) {
          final authCode = result['authCode'];
          debugPrint(
            '✅ [WEB OAUTH] OAuth success with code: ${authCode?.substring(0, 10)}...',
          );
          _closeOAuthWindow();
          _returnResult({'success': true, 'authCode': authCode});
        } else {
          final error = result['error'] ?? 'OAuth failed';
          debugPrint('❌ [WEB OAUTH] OAuth error: $error');
          _closeOAuthWindow();
          _returnResult({'success': false, 'error': error});
        }
      }
    } catch (e) {
      debugPrint('❌ [WEB OAUTH] Error handling postMessage: $e');
      _showError('Failed to process OAuth response');
    }
  }

  void _checkWindowClosed() {
    // Check if window is closed every 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (_oauthWindow?.closed == true) {
        debugPrint('🚪 [WEB OAUTH] OAuth window was closed by user');
        _returnResult({'success': false, 'error': 'User cancelled'});
      } else if (mounted && _oauthWindow != null) {
        _checkWindowClosed(); // Continue checking
      }
    });
  }

  void _closeOAuthWindow() {
    try {
      _oauthWindow?.close();
      _oauthWindow = null;
    } catch (e) {
      debugPrint('⚠️ [WEB OAUTH] Error closing window: $e');
    }
  }

  void _showError(String error) {
    setState(() {
      _error = error;
      _isLoading = false;
    });
  }

  void _returnResult(Map<String, dynamic> result) {
    if (mounted) {
      context.pop(result);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
    });
    _startOAuthFlow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Connect ${widget.providerName}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _closeOAuthWindow();
            context.pop({'success': false, 'error': 'User cancelled'});
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA342FF)),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFA342FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Opening ${widget.providerName} authentication...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete the authentication in the popup window',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ] else if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              _closeOAuthWindow();
                              context.pop({'success': false, 'error': _error});
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA342FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Initial state
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA342FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.video_call,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect ${widget.providerName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We\'ll open a secure authentication window',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startOAuthFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFA342FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start Authentication',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
