import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:cabme_driver/controller/all_services_controller.dart';
import 'package:cabme_driver/model/service_category_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'lab_sample_selection_screen.dart';
import 'service_category_tile.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

const Map<String, String> _kSubtitles = {
  'Home Services': 'Everyday help for your home',
  'Repair & Maintenance': 'Expert professionals for your home repairs',
  'AC & Appliances': 'We repair & service all major appliances',
  'Cleaning Services': 'Professional cleaning for a spotless home',
  'Interior & Renovation': 'Transform your space beautifully',
  'Outdoor Services': 'Keep your outdoors beautiful & healthy',
  'Security & Safety': 'Your safety, our priority',
  'Smart Home Services': 'Make your home smarter & safer',
  'Water Services': 'Complete water solution for your home',
  'Construction Services': 'Building your dreams with quality',
  'Furniture Services': 'Expert furniture solutions for your home & office',
  'Pest Control': 'Safe, effective & long lasting pest control',
  'Shifting Services': 'Safe & hassle-free shifting services',
  'Personal Home Assistance': 'Helping you with your daily home needs',
  'Pet Services': 'Care & love for your furry friends',
  'Laundry & Textile': 'Fresh, clean & professionally cared',
  'Technology Services': 'Smart solutions for your digital life',
  'Personal Services': 'Pamper yourself with our personal care services',
  'Education Services': 'Learn, grow & achieve your goals',
  'Healthcare Services': 'Quality care at your home',
  'Miscellaneous': 'All your other important needs, covered',
};

class ServiceCategoryDetailScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ServiceCategoryDetailScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<ServiceCategoryDetailScreen> createState() => _ServiceCategoryDetailScreenState();
}

class _ServiceCategoryDetailScreenState extends State<ServiceCategoryDetailScreen> {
  final _controller = Get.put(AllServicesController(), tag: UniqueKey().toString());
  bool _isLoading = true;
  List<ServiceCategoryData> _children = [];

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    mainAxisSpacing: 12,
    crossAxisSpacing: 10,
    childAspectRatio: 0.78,
  );

  @override
  void initState() {
    super.initState();
    _children = _controller.fallbackSubCategories(widget.categoryName);
    _isLoading = _children.isEmpty;
    _load();
  }

  Future<void> _load() async {
    final data = await _controller.fetchCategories(parentId: widget.categoryId, categoryName: widget.categoryName);
    if (mounted) setState(() { _children = data; _isLoading = false; });
  }

  void _onTapChild(ServiceCategoryData child) {
    final rawName = child.libelle ?? '';
    final cleanName = cleanServiceName(rawName);
    final lower = cleanName.toLowerCase();

    if (lower.contains('lab sample') || lower.contains('lab collection')) {
      Get.to(() => LabSampleSelectionScreen(categoryName: cleanServiceName(widget.categoryName)));
      return;
    }

    if (isParentServiceCategory(rawName)) {
      Get.to(() => ServiceCategoryDetailScreen(categoryId: child.id ?? 0, categoryName: rawName));
      return;
    }

    Get.to(() => ServiceRequestScreen(
          serviceName: rawName,
          categoryName: cleanServiceName(widget.categoryName),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();
    final cleanName = cleanServiceName(widget.categoryName);
    final style = categoryStyleFor(cleanName);

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          cleanName.tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_kSubtitles[cleanName] ?? "Available Services").tr,
                    style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                  ),
                  const SizedBox(height: 12),
                  _children.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text("No sub-services found".tr, style: TextStyle(color: AppThemeData.grey500))),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _children.length,
                          gridDelegate: _gridDelegate,
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            return ServiceCategoryTile(
                              label: child.libelle,
                              imageUrl: child.image,
                              isDarkMode: isDarkMode,
                              parentStyle: style,
                              onTap: () => _onTapChild(child),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
