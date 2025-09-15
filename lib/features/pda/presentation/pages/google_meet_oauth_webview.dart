import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

class GoogleMeetOAuthWebView extends StatefulWidget {
  final String oauthUrl;
  final String redirectUri;
  final String providerName; // e.g., 'Google Meet' or 'Google Drive'

  const GoogleMeetOAuthWebView({
    super.key,
    required this.oauthUrl,
    required this.redirectUri,
    this.providerName = 'Google Meet',
  });

  @override
  State<GoogleMeetOAuthWebView> createState() => _GoogleMeetOAuthWebViewState();
}

class _GoogleMeetOAuthWebViewState extends State<GoogleMeetOAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('🌐 [OAUTH WEBVIEW] Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('🌐 [OAUTH WEBVIEW] Page started loading: $url');
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            debugPrint('🌐 [OAUTH WEBVIEW] Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '🌐 [OAUTH WEBVIEW] Page resource error: ${error.description}',
            );
            setState(() {
              _error = 'Failed to load page: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🌐 [OAUTH WEBVIEW] Navigation request: ${request.url}');

            // Check if this is the callback URL
            if (request.url.startsWith(widget.redirectUri)) {
              debugPrint(
                '✅ [OAUTH WEBVIEW] OAuth callback detected: ${request.url}',
              );
              _handleOAuthCallback(request.url);
              return NavigationDecision.prevent;
            }

            // Allow all other navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.oauthUrl));
  }

  void _handleOAuthCallback(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        debugPrint('❌ [OAUTH WEBVIEW] OAuth error: $error - $errorDescription');
        _showErrorAndClose('OAuth Error: $errorDescription');
        return;
      }

      if (code != null) {
        debugPrint(
          '✅ [OAUTH WEBVIEW] OAuth success with code: ${code.substring(0, 10)}...',
        );
        _showSuccessAndClose(code);
        return;
      }

      debugPrint('⚠️ [OAUTH WEBVIEW] No code or error in callback URL');
      _showErrorAndClose('Invalid OAuth response');
    } catch (e) {
      debugPrint('❌ [OAUTH WEBVIEW] Error parsing callback URL: $e');
      _showErrorAndClose('Failed to process OAuth response');
    }
  }

  void _showSuccessAndClose(String authCode) {
    // No interim snackbar; return success to previous screen
    context.pop({'success': true, 'authCode': authCode});
  }

  void _showErrorAndClose(String errorMessage) {
    // No noisy snackbar; just return error
    context.pop({'success': false, 'error': errorMessage});
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
      body: Column(
        children: [
          // Progress indicator
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

          // Error display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                      _controller.reload();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // WebView
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load authentication page',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _error = null;
                            });
                            _controller.reload();
                          },
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
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
