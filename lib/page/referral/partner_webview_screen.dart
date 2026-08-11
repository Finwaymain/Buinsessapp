import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';

/// Generic WebView screen for Partner Dashboard & Referral History.
/// Pass [title] and [urlPath] (e.g. 'partner-dashboard' or 'referral-history').
class PartnerWebViewScreen extends StatefulWidget {
  final String title;
  final String urlPath; // 'partner-dashboard' | 'referral-history'
  final String userType; // 'user' | 'driver'

  const PartnerWebViewScreen({
    super.key,
    required this.title,
    required this.urlPath,
    this.userType = 'driver',
  });

  @override
  State<PartnerWebViewScreen> createState() => _PartnerWebViewScreenState();
}

class _PartnerWebViewScreenState extends State<PartnerWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    String userId = Preferences.getString(Preferences.userId);
    if (userId.isEmpty) {
      final intId = Preferences.getInt(Preferences.userId);
      if (intId > 0) userId = intId.toString();
    }
    final accesstoken = Preferences.getString(Preferences.accesstoken);

    final uri = Uri.https(
      'fiinway.online',
      '/partner/${widget.urlPath}',
      {
        'user_id': userId,
        'token': accesstoken,
        'app': widget.userType,
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _isLoading = true; _hasError = false; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _isLoading = false; _hasError = true; });
        },
        onNavigationRequest: (req) {
          if (req.url.contains('fiinway.online')) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : AppThemeData.grey900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: titleColor,
            fontFamily: AppThemeData.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: titleColor),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() { _isLoading = true; _hasError = false; });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError)
            WebViewWidget(controller: _controller),

          if (_isLoading)
            Container(
              color: bgColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppThemeData.primary200,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${widget.title}...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppThemeData.grey800,
                        fontSize: 14,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 56, color: AppThemeData.grey400),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load ${widget.title}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.white : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppThemeData.grey500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() { _isLoading = true; _hasError = false; });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
