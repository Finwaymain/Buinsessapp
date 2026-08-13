import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'service_booking_flow.dart';

class ServiceActiveJobScreen extends StatefulWidget {
  final String tag;

  const ServiceActiveJobScreen({super.key, required this.tag});

  @override
  State<ServiceActiveJobScreen> createState() => _ServiceActiveJobScreenState();
}

class _ServiceActiveJobScreenState extends State<ServiceActiveJobScreen> {
  final _extraNameController = TextEditingController();
  final _extraPriceController = TextEditingController();
  final _materialController = TextEditingController();

  @override
  void dispose() {
    _extraNameController.dispose();
    _extraPriceController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  void _addExtra(ServiceBookingFlowController flow) {
    final name = _extraNameController.text.trim();
    final price = double.tryParse(_extraPriceController.text.trim()) ?? 0;
    if (name.isEmpty) {
      Get.snackbar('Required'.tr, 'Please enter extra service name.'.tr);
      return;
    }
    if (price <= 0) {
      Get.snackbar('Required'.tr, 'Please enter a valid price for the extra service.'.tr);
      return;
    }
    flow.addExtraService(name, price: price);
    _extraNameController.clear();
    _extraPriceController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(widget.tag);

    return Obx(() {
      final booking = flow.currentBooking.value;
      final items = flow.serviceItems.toList();
      final extras = flow.extraAddedItems;
      final isPaused = flow.isPaused.value;
      final visit = flow.visitingCharge.value;
      final material = flow.materialCost.value;
      final platform = flow.platformFeeStored.value;

      return ServiceFlowScaffold(
        title: 'Service In Progress'.tr,
        subtitle: flow.startedAt.value != null ? _formatTime(flow.startedAt.value!) : booking.scheduleLabel,
        headerColor: AppThemeData.primary200,
        showBack: false,
        body: RefreshIndicator(
          color: AppThemeData.primary200,
          onRefresh: () => flow.refreshCurrent(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                    ServiceFlowCard(child: CustomerHeaderCard(booking: booking, onCall: flow.callCustomer)),
                    ServiceFlowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.checklist_rounded, size: 18, color: AppThemeData.primary200),
                              const SizedBox(width: 8),
                              Text('Service Checklist'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 15)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppThemeData.success300.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${flow.completedServiceCount}/${items.length}',
                                  style: TextStyle(fontSize: 12, color: AppThemeData.success300, fontFamily: AppThemeData.semiBold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (items.isEmpty)
                            Text('No services listed'.tr, style: TextStyle(color: AppThemeData.grey500, fontSize: 13))
                          else
                            ServiceItemsList(
                              items: items,
                              showPrices: true,
                              showCheckmarks: true,
                              onToggle: flow.toggleServiceDone,
                              isExtraCheck: flow.isExtraService,
                            ),
                        ],
                      ),
                    ),
                    ServiceFlowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_box_outlined, size: 18, color: AppThemeData.primary200),
                              const SizedBox(width: 8),
                              Text('Add Extra Service'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add any additional work done at customer location.'.tr,
                            style: TextStyle(fontSize: 12, color: AppThemeData.grey500, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _extraNameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _fieldDecoration('Service name (e.g. Extra pipe fitting)'.tr, Icons.home_repair_service_outlined),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _extraPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _fieldDecoration('Price'.tr, Icons.currency_rupee_rounded),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _addExtra(flow),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text('Add to Bill'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          if (extras.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text('Added Extras'.tr, style: TextStyle(fontSize: 12, color: AppThemeData.grey500, fontFamily: AppThemeData.semiBold)),
                            const SizedBox(height: 8),
                            ...extras.map((e) => _extraItemTile(flow, e)),
                          ],
                        ],
                      ),
                    ),
                    
                    _billPreviewCard(
                      labour: flow.labourTotal,
                      visit: visit,
                      material: material,
                      platform: platform,
                      total: flow.billTotal,
                      serviceItems: flow.itemizedBillItems,
                    ),
                  ],
                ),
              ),
            ),
        bottomBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FlowPrimaryButton(
              label: 'Finish Service'.tr,
              color: AppThemeData.success300,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => resumeServiceFlowAfterComplete(widget.tag),
            ),
          ),
        ),
      );
    });
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppThemeData.grey400),
      filled: true,
      fillColor: AppThemeData.grey50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _extraItemTile(ServiceBookingFlowController flow, ServiceLineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemeData.primary200.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13)),
                Text(Constant().amountShow(amount: item.price.toStringAsFixed(0)), style: TextStyle(fontSize: 12, color: AppThemeData.grey500)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => flow.removeExtraService(item.name),
            icon: Icon(Icons.delete_outline_rounded, color: AppThemeData.error200, size: 20),
            tooltip: 'Remove'.tr,
          ),
        ],
      ),
    );
  }

  Widget _billPreviewCard({
    required double labour,
    required double visit,
    required double material,
    required double platform,
    required double total,
    required List<ServiceLineItem> serviceItems,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: AppThemeData.primary200, size: 20),
              const SizedBox(width: 8),
              Text('Bill Preview'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          if (serviceItems.isNotEmpty)
            ...serviceItems.map((item) => _billRow(item.name, item.price))
          else
            _billRow('Service Charges'.tr, labour),
          if (visit > 0) _billRow('Visiting Charge'.tr, visit, highlight: true),
          if (material > 0) _billRow('Material Cost'.tr, material),
          if (platform > 0) _billRow('Platform Fee'.tr, platform),
          const Divider(height: 22),
          _billRow('Estimated Total'.tr, total, bold: true),
          const SizedBox(height: 6),
          Text(
            'Visiting charge is always included in the final bill.'.tr,
            style: TextStyle(fontSize: 11, color: AppThemeData.grey500, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: bold ? AppThemeData.bold : AppThemeData.regular,
                color: highlight ? AppThemeData.primary200 : null,
              ),
            ),
          ),
          Text(
            Constant().amountShow(amount: amount.toStringAsFixed(0)),
            style: TextStyle(
              fontSize: 13,
              fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold,
              color: bold ? AppThemeData.success300 : (highlight ? AppThemeData.primary200 : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
