import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controller/edit_categories_controller.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';

class EditCategoriesScreen extends StatelessWidget {
  const EditCategoriesScreen({super.key});

  IconData _getCategoryIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('cab') || t.contains('taxi') || t.contains('car')) {
      return Icons.local_taxi_rounded;
    } else if (t.contains('bike') || t.contains('moto')) {
      return Icons.two_wheeler_rounded;
    } else if (t.contains('auto') || t.contains('rickshaw')) {
      return Icons.electric_rickshaw_rounded;
    } else if (t.contains('truck') || t.contains('lorry')) {
      return Icons.local_shipping_rounded;
    } else if (t.contains('parcel') || t.contains('courier') || t.contains('delivery')) {
      return Icons.inventory_2_rounded;
    } else if (t.contains('food') || t.contains('restaurant')) {
      return Icons.restaurant_rounded;
    } else if (t.contains('clean') || t.contains('maid')) {
      return Icons.cleaning_services_rounded;
    } else if (t.contains('plumb')) {
      return Icons.plumbing_rounded;
    } else if (t.contains('electr')) {
      return Icons.electrical_services_rounded;
    } else if (t.contains('ac') || t.contains('appliance')) {
      return Icons.ac_unit_rounded;
    } else if (t.contains('paint')) {
      return Icons.format_paint_rounded;
    } else if (t.contains('pest')) {
      return Icons.pest_control_rounded;
    } else if (t.contains('seller') || t.contains('market') || t.contains('store')) {
      return Icons.storefront_rounded;
    } else if (t.contains('doctor') || t.contains('health') || t.contains('medical')) {
      return Icons.medical_services_rounded;
    } else if (t.contains('salon') || t.contains('beauty') || t.contains('groom')) {
      return Icons.content_cut_rounded;
    }
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final controller = Get.put(EditCategoriesController());

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryColor = AppThemeData.primary200;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          "Edit My Services & Categories".tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        actions: [
          Obx(() {
            final count = controller.selectedSubcategoryIds.length;
            return Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count Selected".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(() {
            final isSaving = controller.isSaving.value;
            final count = controller.selectedSubcategoryIds.length;

            return SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final success = await controller.saveCategories();
                        if (success) {
                          Get.back(result: true);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            count > 0 ? "Save $count Categories".tr : "Save Categories".tr,
                            style: const TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  "Loading categories...".tr,
                  style: TextStyle(color: textSecondary, fontFamily: AppThemeData.medium),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 1. Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: cardBg,
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                style: TextStyle(fontFamily: AppThemeData.medium, color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search services (e.g. Cab, Plumber, Delivery)...".tr,
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                  suffixIcon: controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => controller.searchQuery.value = '',
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 2. Horizontal Parent Category Tabs (Only when not searching)
            if (controller.searchQuery.value.isEmpty && controller.parentCategories.isNotEmpty)
              Container(
                height: 48,
                color: cardBg,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: controller.parentCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final parent = controller.parentCategories[index];
                    final isSelected = controller.selectedParentIndex.value == index;

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => controller.selectedParentIndex.value = index,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            parent.title,
                            style: TextStyle(
                              fontFamily: isSelected ? AppThemeData.bold : AppThemeData.medium,
                              fontSize: 12.5,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 1, thickness: 0.5),

            // 3. Subcategories Multi-Selection Grid
            Expanded(
              child: Builder(builder: (context) {
                final subs = controller.filteredSubcategories;

                if (subs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            "No services found".tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try searching with another keyword.".tr,
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final item = subs[index];
                    final isChecked = controller.isCategorySelected(item.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => controller.toggleCategory(item.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? (isDark ? primaryColor.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.08))
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isChecked ? primaryColor : borderColor,
                            width: isChecked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isChecked
                                  ? primaryColor.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Icon and Checkbox row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? primaryColor.withValues(alpha: 0.2)
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: item.image != null && item.image!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: item.image!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Icon(
                                              _getCategoryIcon(item.title),
                                              color: isChecked ? primaryColor : textSecondary,
                                              size: 22,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          _getCategoryIcon(item.title),
                                          color: isChecked ? primaryColor : textSecondary,
                                          size: 22,
                                        ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isChecked ? primaryColor : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isChecked ? primaryColor : textSecondary.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),

                            // Title
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: isChecked ? AppThemeData.bold : AppThemeData.medium,
                                fontSize: 13.5,
                                color: isChecked ? primaryColor : textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}
