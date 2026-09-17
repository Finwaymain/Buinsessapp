import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/driver_kit_model.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/service/driver_kit_service.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class KitTrackingScreen extends StatefulWidget {
  final String? orderId;
  final String? orderNumber;

  const KitTrackingScreen({super.key, this.orderId, this.orderNumber});

  @override
  State<KitTrackingScreen> createState() => _KitTrackingScreenState();
}

class _KitTrackingScreenState extends State<KitTrackingScreen> {
  bool isLoading = true;
  Map<String, dynamic>? trackingData;

  @override
  void initState() {
    super.initState();
    _fetchTrackingDetails();
  }

  Future<void> _fetchTrackingDetails() async {
    setState(() => isLoading = true);
    try {
      final driverId = Constant.getUserData().userData?.id?.toString() ?? '';
      String url = "${API.driverKitOrderTrack}?";
      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        url += "order_id=${widget.orderId}";
      } else if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
        url += "order_number=${widget.orderNumber}";
      } else {
        url += "driver_id=$driverId";
      }

      final res = await http.get(Uri.parse(url), headers: API.header);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] != null) {
          setState(() {
            trackingData = body['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching kit tracking: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final order = trackingData;
    final trackingCode = order?['tracking_code'] ?? 'FWP7823456789';
    final courierPartner = order?['courier_partner'] ?? 'Blue Dart Express';
    final expectedDelivery = order?['expected_delivery'] ?? 'Today by 6:00 PM';
    final deliveryStatus = order?['delivery_status'] ?? 'out_for_delivery';
    final deliveryExecutive = order?['delivery_executive'] ?? {};
    final parcelDetails = order?['parcel_details'] ?? {};
    final List timelineList = order?['timeline'] is List ? order!['timeline'] : [];

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
              style: TextStyle(fontSize: 11, fontFamily: AppThemeData.medium, color: AppThemeData.primary200),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.headset_mic_outlined, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => _callSupport(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppThemeData.primary200))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title Card with status badge matching mockup
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.inventory_2_rounded, color: Color(0xFFEA580C), size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Parcel Tracking",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: AppThemeData.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Track your parcel status in real time",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDeliveryStatusBadge(deliveryStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3-Column Info Card: Tracking Code, Courier Partner, Expected Delivery
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Col 1: Tracking Code
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tracking Code", style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      trackingCode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: AppThemeData.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: trackingCode));
                                      ShowToastDialog.showToast("Tracking code copied!");
                                    },
                                    child: Icon(Icons.copy_rounded, size: 14, color: AppThemeData.primary200),
                                  ),
                                ],
                              ),
                              Text("Powered by BlueDart", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        const SizedBox(width: 12),

                        // Col 2: Courier Partner
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Courier Partner", style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                "BLUE DART",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppThemeData.bold,
                                  color: Color(0xFF0047AB),
                                ),
                              ),
                              Text("Delivery with Trust", style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        const SizedBox(width: 12),

                        // Col 3: Expected Delivery
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Expected Delivery", style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                expectedDelivery,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppThemeData.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Parcel Details & Actions Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.all_inbox_rounded, color: Color(0xFFB45309), size: 36),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Parcel Details",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildParcelDetailRow("Item", parcelDetails['item'] ?? (order?['kit_title'] ?? 'Official Partner Kit'), isDark),
                                  _buildParcelDetailRow("Weight", parcelDetails['weight'] ?? '1.2 kg', isDark),
                                  _buildParcelDetailRow("Type", parcelDetails['type'] ?? 'Standard Delivery', isDark),
                                  _buildParcelDetailRow("Ref No", parcelDetails['ref_no'] ?? ('FW-' + trackingCode.substring(0, 6)), isDark),
                                  _buildParcelDetailRow("Note", parcelDetails['note'] ?? 'Handle with care', isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openInvoice(order?['id']?.toString()),
                                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                label: const Text("View Invoice"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppThemeData.primary200,
                                  side: BorderSide(color: AppThemeData.primary200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openTrackingLink(order?['tracking_url'] ?? "https://www.bluedart.com"),
                                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                                label: const Text("Tracking Link", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0047AB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delivery Status Timeline
                  Text(
                    "Delivery Status",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: AppThemeData.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: List.generate(timelineList.length, (index) {
                        final step = timelineList[index];
                        final isLast = index == timelineList.length - 1;
                        final bool isDone = step['is_completed'] == true;
                        final bool isCur = step['is_current'] == true;

                        return _buildTimelineItem(
                          title: step['title']?.toString() ?? '',
                          date: step['date']?.toString() ?? '',
                          description: step['description']?.toString() ?? '',
                          isCompleted: isDone,
                          isCurrent: isCur,
                          isLast: isLast,
                          isDark: isDark,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delivery Partner Profile Card matching mockup
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF0047AB).withOpacity(0.1),
                              child: const Icon(Icons.person, color: Color(0xFF0047AB), size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your Delivery Partner",
                                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    deliveryExecutive['name']?.toString() ?? "Ravi Kumar",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    deliveryExecutive['role']?.toString() ?? "Delivery Executive",
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    deliveryExecutive['phone']?.toString() ?? "+91 98765 43210",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0047AB)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black26),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  "Vehicle: ${deliveryExecutive['vehicle_no'] ?? 'DL 1L AB 1234'}",
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  "Partner ID: ${deliveryExecutive['partner_id'] ?? 'BD567890'}",
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons (Call, Chat, WhatsApp, Share) matching mockup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.call_rounded,
                        label: "Call",
                        color: const Color(0xFF16A34A),
                        onTap: () => _makePhoneCall(deliveryExecutive['phone'] ?? '+919876543210'),
                        isDark: isDark,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.chat_bubble_rounded,
                        label: "Chat",
                        color: const Color(0xFF0284C7),
                        onTap: () => ShowToastDialog.showToast("Opening chat..."),
                        isDark: isDark,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.whatsapp_rounded,
                        label: "WhatsApp",
                        color: const Color(0xFF25D366),
                        onTap: () => _openWhatsApp(deliveryExecutive['phone'] ?? '+919876543210'),
                        isDark: isDark,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.share_rounded,
                        label: "Share",
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: "Track my Fiinway Kit parcel with code: $trackingCode"));
                          ShowToastDialog.showToast("Tracking info copied to share!");
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildDeliveryStatusBadge(String status) {
    String label = "Out for Delivery";
    Color bgColor = const Color(0xFFECFDF5);
    Color textColor = const Color(0xFF059669);

    if (status == 'delivered') {
      label = "Delivered";
      bgColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF059669);
    } else if (status == 'out_for_delivery') {
      label = "Out for Delivery";
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    } else if (status == 'in_transit') {
      label = "In Transit";
      bgColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0284C7);
    } else {
      label = "Booked";
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_rounded, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              "$label :",
              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppThemeData.medium,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String description,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    required bool isDark,
  }) {
    Color dotColor = const Color(0xFFCBD5E1);
    IconData iconData = Icons.circle;

    if (isCompleted && !isCurrent) {
      dotColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_rounded;
    } else if (isCurrent) {
      dotColor = const Color(0xFF0047AB);
      iconData = Icons.local_shipping_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(iconData, color: dotColor, size: isCurrent ? 14 : 18),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.bold,
                        color: isCurrent
                            ? const Color(0xFF0047AB)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (date.isNotEmpty && date != 'Pending')
                      Text(
                        date,
                        style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppThemeData.medium,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _openInvoice(String? orderId) {
    if (orderId == null || orderId.isEmpty) return;
    final url = "https://api.fiinway.com/driver-kits/invoice/$orderId";
    Get.to(() => WebViewScreen(url: url, title: "Order Tax Invoice"));
  }

  void _openTrackingLink(String url) {
    if (url.isEmpty) return;
    Get.to(() => WebViewScreen(url: url, title: "Courier Partner Tracking"));
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ShowToastDialog.showToast("Could not dial $phone");
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ShowToastDialog.showToast("WhatsApp not installed");
    }
  }

  void _callSupport() {
    _makePhoneCall("+918000000000");
  }
}
