import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:provider/provider.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:image_picker/image_picker.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool showAppBar;

  const WebViewScreen({super.key, required this.url, required this.title, this.showAppBar = true});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController = controller.platform as AndroidWebViewController;
      androidController.setOnShowFileSelector((FileSelectorParams params) async {
        final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
        final isDark = themeChange.getThem();
        
        final List<String>? result = await showModalBottomSheet<List<String>>(
          context: context,
          backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext bc) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.photo_library, color: isDark ? Colors.white : AppThemeData.grey900),
                    title: Text('Photo Library', style: TextStyle(color: isDark ? Colors.white : AppThemeData.grey900, fontFamily: AppThemeData.medium)),
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        Navigator.of(context).pop([Uri.file(image.path).toString()]);
                      } else {
                        Navigator.of(context).pop(<String>[]);
                      }
                    }
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_camera, color: isDark ? Colors.white : AppThemeData.grey900),
                    title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : AppThemeData.grey900, fontFamily: AppThemeData.medium)),
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (photo != null) {
                        Navigator.of(context).pop([Uri.file(photo.path).toString()]);
                      } else {
                        Navigator.of(context).pop(<String>[]);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
        return result ?? [];
      });
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'AppBridge',
        onMessageReceived: (JavaScriptMessage message) {
          print('WebView :: JavaScript Message :: ${message.message}');
          if (message.message == 'close') {
            Get.back();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('WebView :: Page Started :: $url');
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            print('WebView :: Page Finished :: $url');
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView :: Error :: ${error.description} :: ${error.errorType}');
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('WebView :: Navigation Request :: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    
    final scaffold = Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppThemeData.grey900, size: 20),
                onPressed: () => Get.back(),
              ),
              title: Text(
                widget.title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppThemeData.grey900,
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Stack(
        children: [
          if (!hasError) WebViewWidget(controller: controller),
          if (isLoading && !hasError)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1529927066849-79b791a69825?w=500&auto=format&fit=crop&q=60',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 100, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Try again later'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We couldn\'t load the page.'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'URL: ${widget.url}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          hasError = false;
                          isLoading = true;
                        });
                        controller.reload();
                      },
                      child: Text('Retry'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.showAppBar) return scaffold;

    // Full-bleed mode (used for the post-onboarding web dashboard): this is
    // effectively the app's home screen with nothing beneath it in the stack,
    // so block the system back gesture instead of popping to nothing.
    return PopScope(canPop: false, child: scaffold);
  }
}
