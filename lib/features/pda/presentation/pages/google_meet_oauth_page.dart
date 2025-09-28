import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class GoogleMeetOAuthPage extends StatefulWidget {
  final String oauthUrl;
  final String redirectUri;
  final String providerName;

  const GoogleMeetOAuthPage({
    super.key,
    required this.oauthUrl,
    required this.redirectUri,
    this.providerName = 'Google Meet',
  });

  @override
  State<GoogleMeetOAuthPage> createState() => _GoogleMeetOAuthPageState();
}

class _GoogleMeetOAuthPageState extends State<GoogleMeetOAuthPage> {
  bool _isLoading = true;
  String? _error;
  html.WindowBase? _popupWindow;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkForOAuthReturn();
    } else {
      _initiateMobileOAuth();
    }
  }

  void _checkForOAuthReturn() {
    // Check if we're returning from OAuth (has code or error in URL)
    final currentUrl = html.window.location.href;
    final uri = Uri.parse(currentUrl);

    if (uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('error')) {
      debugPrint('🔄 [WEB OAUTH] Detected OAuth return in URL: $currentUrl');
      _handleOAuthCallback(currentUrl);
    } else {
      // Check localStorage for OAuth result from redirect flow
      final oauthSuccess = html.window.localStorage['oauth_success'];
      final oauthAuthCode = html.window.localStorage['oauth_auth_code'];
      final oauthError = html.window.localStorage['oauth_error'];

      if (oauthSuccess != null) {
        debugPrint('🔄 [WEB OAUTH] Found OAuth result in localStorage');

        // Clean up localStorage
        html.window.localStorage.remove('oauth_success');
        html.window.localStorage.remove('oauth_auth_code');
        html.window.localStorage.remove('oauth_error');

        if (oauthSuccess == 'true' && oauthAuthCode != null) {
          debugPrint('✅ [WEB OAUTH] OAuth was successful, returning auth code');
          if (mounted) {
            context.pop({'success': true, 'authCode': oauthAuthCode});
          }
        } else {
          debugPrint('❌ [WEB OAUTH] OAuth failed, returning error');
          if (mounted) {
            context.pop({
              'success': false,
              'error': oauthError ?? 'OAuth failed',
            });
          }
        }
        return;
      }

      // Check localStorage for redirect return (legacy)
      final oauthReturnUrl = html.window.localStorage['oauth_return_url'];
      if (oauthReturnUrl != null) {
        debugPrint('🔄 [WEB OAUTH] Detected redirect return from localStorage');
        html.window.localStorage.remove('oauth_return_url');
        html.window.localStorage.remove('oauth_provider');
        // This means we returned from redirect but no OAuth params, try normal flow
        _initiateWebOAuth();
      } else {
        _initiateWebOAuth();
      }
    }
  }

  void _initiateWebOAuth() async {
    try {
      debugPrint(
        '🌐 [WEB OAUTH] Starting OAuth flow for ${widget.providerName}',
      );

      // Try to open popup window for OAuth
      _popupWindow = html.window.open(
        widget.oauthUrl,
        'oauth_popup',
        'width=500,height=600,scrollbars=yes,resizable=yes,location=yes,toolbar=no,menubar=no',
      );

      // Check if popup was blocked
      await Future.delayed(const Duration(milliseconds: 100));

      if (_popupWindow == null || _popupWindow!.closed == true) {
        debugPrint('🚫 [WEB OAUTH] Popup was blocked, using redirect approach');
        _useRedirectApproach();
        return;
      }

      debugPrint('✅ [WEB OAUTH] Popup opened successfully');

      // Set up message listener for OAuth callback
      _setupWebOAuthListener();

      // Monitor popup window
      _monitorPopupWindow();
    } catch (e) {
      debugPrint('❌ [WEB OAUTH] Error initiating OAuth: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _useRedirectApproach() {
    debugPrint('🔄 [WEB OAUTH] Using redirect approach for OAuth');

    // Store current URL to return to after OAuth
    final currentUrl = html.window.location.href;
    html.window.localStorage['oauth_return_url'] = currentUrl;
    html.window.localStorage['oauth_provider'] = widget.providerName;

    debugPrint('🔄 [WEB OAUTH] Redirecting to OAuth URL: ${widget.oauthUrl}');

    // Redirect to OAuth URL (Supabase callback will handle redirecting back)
    html.window.location.href = widget.oauthUrl;
  }

  void _setupWebOAuthListener() {
    debugPrint('🔧 [WEB OAUTH] Setting up postMessage listener...');

    // Listen for messages from the popup window
    html.window.addEventListener('message', (html.Event event) {
      final messageEvent = event as html.MessageEvent;

      debugPrint(
        '🌐 [WEB OAUTH] Received postMessage from: ${messageEvent.origin}',
      );
      debugPrint('🌐 [WEB OAUTH] Message data: ${messageEvent.data}');

      // Allow messages from the Supabase domain
      final allowedOrigins = [
        Uri.parse(widget.redirectUri).origin,
        'https://biiqwforuvzgubrrkfgq.supabase.co', // Supabase function domain
      ];

      if (!allowedOrigins.contains(messageEvent.origin)) {
        debugPrint(
          '🚫 [WEB OAUTH] Ignoring message from unauthorized origin: ${messageEvent.origin}',
        );
        return; // Ignore messages from other origins
      }

      final data = messageEvent.data;
      debugPrint('🔍 [WEB OAUTH] Processing message data: $data');

      if (data is Map && data.containsKey('oauth_result')) {
        debugPrint('✅ [WEB OAUTH] Found oauth_result in message');
        final oauthResult = data['oauth_result'];
        if (oauthResult is Map) {
          _handleWebOAuthResult(oauthResult);
        } else {
          debugPrint(
            '⚠️ [WEB OAUTH] oauth_result is not a Map: ${oauthResult.runtimeType}',
          );
          _showErrorAndClose('Invalid OAuth response structure');
        }
      } else if (data is Map) {
        debugPrint(
          '⚠️ [WEB OAUTH] Message is a Map but no oauth_result key found. Keys: ${data.keys}',
        );
        // Try to handle direct success/error format as fallback
        if (data.containsKey('success') && data.containsKey('authCode')) {
          debugPrint('🔄 [WEB OAUTH] Handling direct success format');
          _handleWebOAuthResult(data);
        } else {
          _showErrorAndClose('Invalid OAuth message format');
        }
      } else {
        debugPrint(
          '⚠️ [WEB OAUTH] Message data is not a Map: ${data.runtimeType}',
        );
        _showErrorAndClose('Invalid OAuth message type');
      }
    });

    // Also set up a global callback function for fallback
    js.context['handleOAuthCallback'] = js.allowInterop((String url) {
      debugPrint('🔄 [WEB OAUTH] Global callback invoked with URL: $url');
      _handleOAuthCallback(url);
    });
  }

  void _monitorPopupWindow() {
    debugPrint('👀 [WEB OAUTH] Starting popup window monitoring...');

    // Check if popup is still open
    const Duration checkInterval = Duration(milliseconds: 1000);
    const Duration timeout = Duration(minutes: 5); // 5 minute timeout
    final startTime = DateTime.now();

    void checkPopup() {
      // Check for timeout
      if (DateTime.now().difference(startTime) > timeout) {
        debugPrint('⏰ [WEB OAUTH] OAuth timed out after 5 minutes');
        if (mounted && _isLoading) {
          _showErrorAndClose('OAuth timed out. Please try again.');
        }
        return;
      }

      if (_popupWindow?.closed == true) {
        debugPrint('🚪 [WEB OAUTH] Popup window was closed');
        // Popup was closed without completing OAuth
        if (mounted && _isLoading) {
          _showErrorAndClose('OAuth was cancelled or failed');
        }
        return;
      }

      // Note: Cannot check popup URL due to CORS restrictions
      // We rely on postMessage communication instead

      // Continue monitoring
      if (mounted && _isLoading) {
        Future.delayed(checkInterval, checkPopup);
      }
    }

    Future.delayed(checkInterval, checkPopup);
  }

  void _handleWebOAuthResult(Map data) {
    debugPrint('✅ [WEB OAUTH] Processing OAuth result: $data');

    if (data['success'] == true) {
      final authCode = data['authCode'];
      debugPrint(
        '🔑 [WEB OAUTH] Auth code received: ${authCode?.toString().substring(0, 10)}...',
      );

      if (authCode != null) {
        debugPrint(
          '✅ [WEB OAUTH] OAuth successful, closing popup and returning result',
        );
        _showSuccessAndClose(authCode);
      } else {
        debugPrint('❌ [WEB OAUTH] No auth code in successful response');
        _showErrorAndClose('No authorization code received');
      }
    } else {
      final error = data['error'] ?? 'Unknown OAuth error';
      debugPrint('❌ [WEB OAUTH] OAuth failed with error: $error');
      _showErrorAndClose(error);
    }
  }

  void _initiateMobileOAuth() async {
    try {
      debugPrint(
        '📱 [MOBILE OAUTH] Starting OAuth flow for ${widget.providerName}',
      );

      final canLaunch = await canLaunchUrl(Uri.parse(widget.oauthUrl));
      if (!canLaunch) {
        throw Exception('Cannot launch OAuth URL');
      }

      final launched = await launchUrl(
        Uri.parse(widget.oauthUrl),
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );

      if (!launched) {
        throw Exception('Failed to launch OAuth URL');
      }

      setState(() {
        _isLoading = false;
      });

      // For mobile, we'll need to handle the callback differently
      // This is a simplified approach - in production, you might want to use
      // a custom URL scheme or deep linking
    } catch (e) {
      debugPrint('❌ [MOBILE OAUTH] Error initiating OAuth: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleOAuthCallback(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        debugPrint('❌ [OAUTH] OAuth error: $error - $errorDescription');
        _showErrorAndClose('OAuth Error: $errorDescription');
        return;
      }

      if (code != null) {
        debugPrint(
          '✅ [OAUTH] OAuth success with code: ${code.substring(0, 10)}...',
        );
        _showSuccessAndClose(code);
        return;
      }

      debugPrint('⚠️ [OAUTH] No code or error in callback URL');
      _showErrorAndClose('Invalid OAuth response');
    } catch (e) {
      debugPrint('❌ [OAUTH] Error parsing callback URL: $e');
      _showErrorAndClose('Failed to process OAuth response');
    }
  }

  void _showSuccessAndClose(String authCode) {
    if (_popupWindow != null && (_popupWindow!.closed != true)) {
      // Popup mode - close popup and return result
      _popupWindow!.close();
      if (mounted) {
        context.pop({'success': true, 'authCode': authCode});
      }
    } else {
      // Redirect mode - check if we have a return URL
      final oauthReturnUrl = html.window.localStorage['oauth_return_url'];
      if (oauthReturnUrl != null) {
        debugPrint(
          '🔄 [WEB OAUTH] Redirecting back to return URL: $oauthReturnUrl',
        );

        // Clean up localStorage
        html.window.localStorage.remove('oauth_return_url');
        html.window.localStorage.remove('oauth_provider');

        // Store the auth code in localStorage temporarily so the parent page can access it
        html.window.localStorage['oauth_auth_code'] = authCode;
        html.window.localStorage['oauth_success'] = 'true';

        // Redirect back to original URL
        html.window.location.href = oauthReturnUrl;
      } else {
        // Fallback - try context.pop
        if (mounted) {
          context.pop({'success': true, 'authCode': authCode});
        }
      }
    }
  }

  void _showErrorAndClose(String errorMessage) {
    if (_popupWindow != null && (_popupWindow!.closed != true)) {
      // Popup mode - close popup and return error
      _popupWindow!.close();
      if (mounted) {
        context.pop({'success': false, 'error': errorMessage});
      }
    } else {
      // Redirect mode - check if we have a return URL
      final oauthReturnUrl = html.window.localStorage['oauth_return_url'];
      if (oauthReturnUrl != null) {
        debugPrint(
          '🔄 [WEB OAUTH] Redirecting back to return URL with error: $oauthReturnUrl',
        );

        // Clean up localStorage
        html.window.localStorage.remove('oauth_return_url');
        html.window.localStorage.remove('oauth_provider');

        // Store the error in localStorage temporarily so the parent page can access it
        html.window.localStorage['oauth_error'] = errorMessage;
        html.window.localStorage['oauth_success'] = 'false';

        // Redirect back to original URL
        html.window.location.href = oauthReturnUrl;
      } else {
        // Fallback - try context.pop
        if (mounted) {
          context.pop({'success': false, 'error': errorMessage});
        }
      }
    }
  }

  void _retryOAuth() {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    if (kIsWeb) {
      _initiateWebOAuth();
    } else {
      _initiateMobileOAuth();
    }
  }

  @override
  void dispose() {
    if (kIsWeb && _popupWindow != null && (_popupWindow!.closed != true)) {
      _popupWindow!.close();
    }
    super.dispose();
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: _error != null
            ? _buildErrorWidget()
            : kIsWeb
            ? _buildWebOAuthWidget()
            : _buildMobileOAuthWidget(),
      ),
    );
  }

  Widget _buildWebOAuthWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.language, size: 64, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          'OAuth Window Opened',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please complete the authentication in the popup window.\nThis window will automatically close when done.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 32),
        if (_isLoading) const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildMobileOAuthWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.phone_android, size: 64, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          'OAuth Launched',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please complete the authentication in the browser.\nReturn to this app when done.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            context.pop({'success': false, 'error': 'User cancelled'});
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
        const SizedBox(height: 24),
        Text(
          'Authentication Failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                context.pop({'success': false, 'error': _error});
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _retryOAuth,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
    );
  }
}
