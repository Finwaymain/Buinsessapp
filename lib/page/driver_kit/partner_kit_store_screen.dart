import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/driver_kit_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/service/driver_kit_service.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/mpin_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'kit_tracking_screen.dart';

class PartnerKitStoreScreen extends StatefulWidget {
  final DriverKitItemModel? initialKit;

  const PartnerKitStoreScreen({super.key, this.initialKit});

  @override
  State<PartnerKitStoreScreen> createState() => _PartnerKitStoreScreenState();
}

class _PartnerKitStoreScreenState extends State<PartnerKitStoreScreen> {
  final DriverKitService kitService = Get.find<DriverKitService>();

  bool isLoading = true;
  List<DriverKitItemModel> catalogKits = [];
  int selectedKitIndex = 0;
  String selectedSize = 'L';

  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKitCatalog();
    final user = Constant.getUserData().userData;
    if (user != null) {
      nameController.text = "${user.prenom ?? ''} ${user.nom ?? ''}".trim();
      phoneController.text = user.phone ?? '';
      addressController.text = user.address ?? '';
    }
  }

  Future<void> _loadKitCatalog() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(API.driverKitCatalog), headers: API.header);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] is List) {
          final list = (body['data'] as List).map((e) => DriverKitItemModel.fromJson(e)).toList();
          setState(() {
            catalogKits = list;
            if (widget.initialKit != null) {
              final idx = catalogKits.indexWhere((k) => k.id == widget.initialKit!.id || k.categoryCode == widget.initialKit!.categoryCode);
              if (idx != -1) selectedKitIndex = idx;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading kit catalog: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    pincodeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final DriverKitItemModel? currentKit = catalogKits.isNotEmpty
        ? catalogKits[selectedKitIndex]
        : widget.initialKit ?? kitService.kitData.value?.kit;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              "Fiinway",
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "Drive. Serve. Grow.",
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppThemeData.medium,
                color: AppThemeData.primary200,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_cart_outlined, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "1",
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if (currentKit != null) _openCheckoutSheet(context, currentKit, isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppThemeData.primary200))
          : currentKit == null
              ? _buildEmptyState(isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tabs selector if multiple kits exist
                      if (catalogKits.length > 1) _buildCategorySelector(isDark),
                      const SizedBox(height: 12),

                      // Main Kit Card matching image1 & image2 mockups
                      _buildKitProductCard(currentKit, isDark),
                    ],
                  ),
                ),
      bottomNavigationBar: currentKit == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _openCheckoutSheet(context, currentKit, isDark),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047AB), // Blue theme matching mockup CTA
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Get This Kit (${currentKit.priceFormatted})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: catalogKits.length,
        itemBuilder: (context, index) {
          final isSelected = selectedKitIndex == index;
          final kit = catalogKits[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(kit.title.replaceAll('Partner Kit', '').trim()),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => selectedKitIndex = index);
              },
              selectedColor: AppThemeData.primary200,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                fontSize: 12,
                fontFamily: isSelected ? AppThemeData.bold : AppThemeData.medium,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKitProductCard(DriverKitItemModel kit, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category Icon, Title, and Subtitle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(kit.categoryCode).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(_getCategoryIcon(kit.categoryCode), color: _getCategoryColor(kit.categoryCode), size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kit.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCategorySubtitle(kit.categoryCode),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCategoryTagline(kit.categoryCode),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppThemeData.bold,
                          color: _getCategoryColor(kit.categoryCode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hero Image with value overlay badge
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: kit.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: kit.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildFallbackKitIllustration(kit.categoryCode),
                      )
                    : _buildFallbackKitIllustration(kit.categoryCode),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("Professional Look", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text("More Customers", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text("Higher Income", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // "Kit Includes (All Items Mandatory)" Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  "Kit Includes ",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  kit.isCompulsory ? "(All Items Mandatory)" : "(Recommended Starter Kit)",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppThemeData.bold,
                    color: kit.isCompulsory ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),

          // Items Included Checklist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: kit.itemsIncluded.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: _getCategoryColor(kit.categoryCode)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppThemeData.medium,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Size Selection Row
          if (kit.sizes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Apparel Size:",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.bold,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: kit.sizes.map((s) {
                      final isSel = selectedSize == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => selectedSize = s);
                        },
                        selectedColor: AppThemeData.primary200,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          // Pricing & Value Proposition Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Final Kit Price",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                        if (kit.mrp > kit.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            kit.mrpFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kit.priceFormatted,
                      style: TextStyle(
                        fontSize: 26,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "(All Items Included)",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBenefitChip("Get More Walk-ins", Icons.trending_up_rounded, const Color(0xFF059669)),
                    const SizedBox(height: 4),
                    _buildBenefitChip("Build Your Brand", Icons.verified_rounded, const Color(0xFF0284C7)),
                    if (kit.cashbackAmount > 0) ...[
                      const SizedBox(height: 4),
                      _buildBenefitChip("₹${kit.cashbackAmount.toInt()} Wallet Cashback", Icons.wallet_rounded, const Color(0xFFD97706)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackKitIllustration(String categoryCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getCategoryIcon(categoryCode), size: 64, color: _getCategoryColor(categoryCode).withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            "Official Fiinway Partner Gear",
            style: TextStyle(fontSize: 13, color: const Color(0xFF64748B), fontFamily: AppThemeData.medium),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'male_salon':
        return const Color(0xFF0047AB);
      case 'female_salon':
        return const Color(0xFFBE185D);
      case 'cook_made':
        return const Color(0xFFB45309);
      case 'tutor':
        return const Color(0xFF1D4ED8);
      case 'bike':
        return const Color(0xFFEA580C);
      case 'car':
        return const Color(0xFF0284C7);
      case 'auto':
        return const Color(0xFFD97706);
      case 'cleaner':
        return const Color(0xFF059669);
      default:
        return AppThemeData.primary200;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'male_salon':
        return Icons.content_cut_rounded;
      case 'female_salon':
        return Icons.face_retouching_natural_rounded;
      case 'cook_made':
        return Icons.restaurant_rounded;
      case 'tutor':
        return Icons.school_rounded;
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'auto':
        return Icons.electric_rickshaw_rounded;
      case 'cleaner':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  String _getCategorySubtitle(String cat) {
    switch (cat) {
      case 'male_salon':
        return "Haircut | Styling | Grooming | Beard Care";
      case 'female_salon':
        return "Hair | Skin | Makeup | Nails | Beauty";
      case 'cook_made':
        return "Home Cook | Tiffin | Cloud Kitchen";
      case 'tutor':
        return "Home Tuition | Online | Academic Coaching";
      case 'bike':
        return "Two-Wheeler | Bike Taxi | Parcel Express";
      case 'car':
        return "Four-Wheeler | Cab & Taxi Services";
      case 'auto':
        return "3-Wheeler Auto & E-Rickshaw Partner";
      default:
        return "Verified On-Demand Specialist Services";
    }
  }

  String _getCategoryTagline(String cat) {
    switch (cat) {
      case 'male_salon':
        return "Look Good. Grow with Fiinway.";
      case 'female_salon':
        return "Beauty for a Better Tomorrow.";
      case 'cook_made':
        return "Good Food. Healthy Lives.";
      case 'tutor':
        return "Teach Today. Build Tomorrow.";
      case 'bike':
        return "Ride Safe. Earn Daily.";
      case 'car':
        return "Drive with Trust & Dignity.";
      default:
        return "Serve with Pride & Excellence.";
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white38 : Colors.black26),
          const SizedBox(height: 16),
          Text(
            "No Kits Available",
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _openCheckoutSheet(BuildContext context, DriverKitItemModel kit, bool isDark) {
    String selectedPaymentMethod = 'wallet';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Confirm Kit Order",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppThemeData.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          kit.priceFormatted,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppThemeData.bold,
                            color: AppThemeData.primary200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${kit.title} (Size: $selectedSize)",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shipping Details Form
                    Text("Delivery Address", style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Enter complete street address, landmark",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pincode", style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              TextField(
                                controller: pincodeController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "e.g. 110001",
                                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Contact Phone", style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Phone number",
                                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text("Payment Option", style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 8),

                    // Payment Method Options
                    _buildPaymentOptionTile(
                      title: "Fiinway Wallet Balance",
                      subtitle: "Fast 1-tap deduction with secure MPIN",
                      icon: Icons.account_balance_wallet_outlined,
                      value: 'wallet',
                      groupValue: selectedPaymentMethod,
                      isDark: isDark,
                      onChanged: (val) => setSheetState(() => selectedPaymentMethod = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOptionTile(
                      title: "Online Payment (UPI, Cards)",
                      subtitle: "Pay via Google Pay, PhonePe, Cards",
                      icon: Icons.credit_card_outlined,
                      value: 'online',
                      groupValue: selectedPaymentMethod,
                      isDark: isDark,
                      onChanged: (val) => setSheetState(() => selectedPaymentMethod = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOptionTile(
                      title: "Deduct from Ride Earnings",
                      subtitle: "Pay later as you complete bookings",
                      icon: Icons.trending_up_rounded,
                      value: 'deduct_earnings',
                      groupValue: selectedPaymentMethod,
                      isDark: isDark,
                      onChanged: (val) => setSheetState(() => selectedPaymentMethod = val!),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _handlePlaceOrder(context, kit, selectedPaymentMethod),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Confirm Order & Pay ${kit.priceFormatted}",
                          style: const TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeData.primary200.withOpacity(0.08) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppThemeData.primary200 : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppThemeData.primary200 : (isDark ? Colors.white70 : const Color(0xFF64748B)), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppThemeData.primary200,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(BuildContext sheetContext, DriverKitItemModel kit, String paymentMethod) async {
    final address = addressController.text.trim();
    if (address.isEmpty) {
      ShowToastDialog.showToast("Please enter delivery address");
      return;
    }

    final driverId = Constant.getUserData().userData?.id?.toString() ?? '';
    if (driverId.isEmpty) {
      ShowToastDialog.showToast("Driver session not found");
      return;
    }

    String mpin = '';
    if (paymentMethod === 'wallet') {
      final verifiedPin = await showMpinVerificationBottomSheet(
        context,
        amount: kit.price,
        title: "Verify MPIN to Pay for ${kit.title}",
      );
      if (verifiedPin == null) return;
      mpin = verifiedPin;
    }

    Navigator.pop(sheetContext);
    ShowToastDialog.showLoader("Placing your kit order...");

    try {
      final response = await http.post(
        Uri.parse(API.driverKitRecordPurchase),
        headers: API.header,
        body: jsonEncode({
          'driver_id': driverId,
          'kit_id': kit.id,
          'amount': kit.price,
          'tshirt_size': selectedSize,
          'selected_size': selectedSize,
          'receiver_name': nameController.text.trim(),
          'receiver_phone': phoneController.text.trim(),
          'shipping_address': address,
          'pincode': pincodeController.text.trim(),
          'payment_method': paymentMethod,
          'mpin': mpin,
        }),
      );

      ShowToastDialog.closeLoader();

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success') {
          ShowToastDialog.showToast("Partner kit ordered successfully!");
          await kitService.fetchKitStatus();
          Get.off(() => const KitTrackingScreen());
        } else {
          ShowToastDialog.showToast(body['error'] ?? body['message'] ?? "Order failed");
        }
      } else {
        ShowToastDialog.showToast("Server error while placing order");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Network error: $e");
    }
  }
}
