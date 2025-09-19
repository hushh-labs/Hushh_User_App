import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class KaiPage extends StatefulWidget {
  const KaiPage({super.key});

  @override
  State<KaiPage> createState() => _KaiPageState();
}

class _KaiPageState extends State<KaiPage> {
  late final WebViewController _controller;
  int _progress = 0;

  static const String _kaiUrl =
      'https://chatgpt.com/g/g-68cae9418b388191a8f8887e71bb65f3-kai-by-hushh';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL is for Google sign-in or other external auth
            if (_shouldOpenExternally(request.url)) {
              _openInExternalBrowser(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_kaiUrl));
  }

  bool _shouldOpenExternally(String url) {
    // Open Google sign-in, OAuth, and other auth URLs externally
    return url.contains('accounts.google.com') ||
        url.contains('oauth') ||
        url.contains('auth') ||
        url.contains('login') ||
        url.contains('signin') ||
        url.contains('microsoft.com') ||
        url.contains('apple.com') ||
        url.contains('facebook.com');
  }

  Future<void> _openInExternalBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator.adaptive(
          onRefresh: () async => _controller.reload(),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  child: WebViewWidget(controller: _controller),
                ),
              ),
              if (_progress < 100)
                LinearProgressIndicator(value: _progress / 100, minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }
}
