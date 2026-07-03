
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/add_user_controller.dart';


class ContactPickerBottomSheet extends StatelessWidget {
  const ContactPickerBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddUserController>();
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    controller.contactSearchController.clear();
    controller.filteredContacts.assignAll(controller.contacts);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Contact",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppThemeData.primary200,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                )
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller.contactSearchController,
              decoration: InputDecoration(
                hintText: "Search contacts...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              onChanged: (value) {
                controller.filterContacts();
              },
            ),
          ),

          // Contact List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingContacts.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.filteredContacts.isEmpty) {
                return Center(
                  child: Text(
                    controller.contacts.isEmpty
                        ? "No contacts available"
                        : "No contacts found",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = controller.filteredContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppThemeData.primary200,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : "?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      contact.number,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: Icon(Icons.add, color: AppThemeData.primary200),
                    onTap: () {
                      Get.back();
                      controller.addContactAsUser(contact.name, contact.number);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
