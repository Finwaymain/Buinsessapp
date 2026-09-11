/// Business app Food tile — order food like the customer app (not delivery partner).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodOrderingScreen extends StatefulWidget {
  const FoodOrderingScreen({super.key});

  @override
  State<FoodOrderingScreen> createState() => _FoodOrderingScreenState();
}

class _FoodOrderingScreenState extends State<FoodOrderingScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food Order'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search restaurants or dishes'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nearby restaurants'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.restaurant)),
            title: Text('Browse nearby restaurants'.tr),
            subtitle: Text('Same customer food APIs: /api/v1/food/customer/*'.tr),
            onTap: () => Get.snackbar('Food Order'.tr, 'Connect nearby restaurants list next'.tr),
          ),
          const Divider(),
          Text('Order flow'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '1. Nearby restaurants → Menu\n'
            '2. Cart → Address → Wallet / UPI / COD\n'
            '3. Track order → Rate → Reorder',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.snackbar('Food Order'.tr, 'Customer food booking flow for business users'.tr),
            icon: const Icon(Icons.fastfood),
            label: Text('Start ordering'.tr),
          ),
        ],
      ),
    );
  }
}
