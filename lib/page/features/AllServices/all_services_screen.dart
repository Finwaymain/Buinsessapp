import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:cabme_driver/controller/all_services_controller.dart';
import 'package:cabme_driver/model/service_category_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'service_category_detail_screen.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

/// "All Services" hub — the destination for the home page's "More" tile.
class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final _controller = Get.put(AllServicesController(), tag: UniqueKey().toString());
  bool _isLoading = true;
  List<ServiceCategoryData> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Remove emojis from service name
  String _cleanServiceName(String? name) {
    if (name == null) return '';
    // Remove emoji characters (Unicode ranges for emojis)
    return name.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '').trim();
  }

  Future<void> _load() async {
    final data = await _controller.fetchCategories();
    if (mounted) setState(() { _categories = data; _isLoading = false; });
  }

  void _onTapCategory(ServiceCategoryData category) {
    if (category.hasChildren) {
      Get.to(() => ServiceCategoryDetailScreen(categoryId: category.id!, categoryName: category.libelle ?? ''));
    } else {
      Get.to(() => ServiceRequestScreen(serviceName: category.libelle ?? '', categoryName: category.libelle ?? ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "All Services".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(child: Text("No services available".tr, style: TextStyle(color: AppThemeData.grey500)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final style = categoryStyleFor(category.libelle);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _onTapCategory(category),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(14)),
                            child: Icon(style.icon, color: style.color, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cleanServiceName(category.libelle).tr,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              fontSize: 11.5,
                              color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
