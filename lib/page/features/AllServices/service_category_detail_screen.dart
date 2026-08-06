import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:cabme_driver/controller/all_services_controller.dart';
import 'package:cabme_driver/model/service_category_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
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

const Map<String, List<String>> _kTrustBadge = {
  'Repair & Maintenance': ['Verified Professionals', 'Background verified & experienced professionals at your service'],
  'AC & Appliances': ['Genuine Service', 'Genuine spare parts with warranty on all repairs'],
  'Cleaning Services': ['100% Satisfaction', 'Quality cleaning with satisfaction guaranteed'],
  'Interior & Renovation': ['Expert Designers', 'Professional designers & skilled workmanship'],
  'Outdoor Services': ['Eco-Friendly Service', 'Environment friendly solutions for a green & healthy space'],
  'Personal Home Assistance': ['Verified & Background Checked', 'Trusted professionals for your peace of mind'],
  'Pet Services': ['Loving & Trained Experts', 'Safe, reliable & compassionate pet care'],
  'Laundry & Textile': ['Quality & Hygiene Assured', 'We care for your clothes like you do'],
  'Technology Services': ['Expert Technicians', 'Verified professionals at your service'],
  'Personal Services': ['Hygiene & Safety', 'Your safety is our priority'],
  'Education Services': ['Verified Experts', 'Qualified & experienced trainers'],
  'Healthcare Services': ['Trusted & Reliable', 'Your health, our priority'],
  'Miscellaneous': ['Wide Range of Services', 'One app for all your home and lifestyle needs'],
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
    final data = await _controller.fetchCategories(parentId: widget.categoryId);
    if (mounted) setState(() { _children = data; _isLoading = false; });
  }

  void _onTapChild(ServiceCategoryData child) {
    if (child.hasChildren) {
      Get.to(() => ServiceCategoryDetailScreen(categoryId: child.id!, categoryName: child.libelle ?? ''));
    } else {
      Get.to(() => ServiceRequestScreen(serviceName: child.libelle ?? '', categoryName: widget.categoryName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();
    final cleanName = _cleanServiceName(widget.categoryName);
    final style = categoryStyleFor(cleanName);
    final badge = _kTrustBadge[cleanName];

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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(badge[0].tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: style.color)),
                                const SizedBox(height: 2),
                                Text(badge[1].tr, style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11, color: style.color.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _kSubtitles[widget.categoryName]?.tr ?? "Available Services".tr,
                    style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                  ),
                  const SizedBox(height: 14),
                  _children.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text("No sub-services found".tr, style: TextStyle(color: AppThemeData.grey500))),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _children.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            final icon = leafIconFor(child.libelle ?? '', fallback: style.icon);
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _onTapChild(child),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(12)),
                                      child: Icon(icon, color: style.color, size: 24),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _cleanServiceName(child.libelle).tr,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.bold,
                                        fontSize: 11,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
