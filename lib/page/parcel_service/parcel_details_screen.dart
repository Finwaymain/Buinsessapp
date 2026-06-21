import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/parcel_payment_controller.dart';
import 'package:cabme_driver/model/tax_model.dart';
import 'package:cabme_driver/page/chats_screen/FullScreenImageViewer.dart';
import 'package:cabme_driver/page/parcel_service/all_parcel_screen.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ParcelDetailsScreen extends StatelessWidget {
  const ParcelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ParcelPaymentController>(
        init: ParcelPaymentController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppbarCustom(
              title: 'Parcel Details'.tr,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildHistory(context, controller),
                    // buildAmountWidget(controller),
                    const SizedBox(
                      height: 10,
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text('Admin commission'.tr,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.regular,
                                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      fontSize: 16,
                                    )),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text("(-${Constant().amountShow(amount: controller.adminCommission.value.toString())})",
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      color: AppThemeData.error50,
                                      fontSize: 16,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Note : Admin commission will be debited from your wallet balance. \nAdmin commission will apply on parcel Amount minus Discount(If applicable).".tr,
                            style: TextStyle(color: AppThemeData.error50),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  GestureDetector buildHistory(context, ParcelPaymentController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
          borderRadius: const BorderRadius.all(
            Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_location.svg',
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.success300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                                  )
                                ],
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.data.value.senderName.toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                        color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                    Text(
                                      controller.data.value.source.toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppThemeData.regular,
                                        color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              controller.data.value.status == "new"
                                  ? statusTile(title: 'New', bgColor: AppThemeData.new200.withAlpha(200), txtColor: AppThemeData.primary200)
                                  : controller.data.value.status == "onride"
                                      ? statusTile(title: 'Active', bgColor: AppThemeData.new200.withAlpha(200), txtColor: AppThemeData.primary200)
                                      : controller.data.value.status == "confirmed"
                                          ? statusTile(title: 'Confirmed', bgColor: AppThemeData.new200.withAlpha(200), txtColor: AppThemeData.primary200)
                                          : controller.data.value.status == "completed"
                                              ? statusTile(title: 'Completed', bgColor: AppThemeData.success50.withAlpha(200), txtColor: AppThemeData.success300)
                                              : statusTile(title: 'Rejected', bgColor: AppThemeData.error50.withAlpha(200), txtColor: AppThemeData.error200),
                              const Divider(),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_location.svg',
                                colorFilter: ColorFilter.mode(
                                  AppThemeData.warning200,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.data.value.receiverName.toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                        color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                    Text(
                                      controller.data.value.destination.toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppThemeData.regular,
                                        color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Parcel Details".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontSize: 16,
                )),
            SizedBox(
              height: 100,
              child: ListView.builder(
                  itemCount: controller.data.value.parcelImage!.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Get.to(
                          () => FullScreenImageViewer(
                            imageUrl: controller.data.value.parcelImage![index],
                          ),
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 100.0,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                            width: 1,
                          ),
                          image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(controller.data.value.parcelImage![index])),
                        ),
                      ),
                    );
                  }),
            ),
            const SizedBox(height: 10),
            Text("Sender and Receiver Details".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontSize: 16,
                )),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  border: Border.all(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    width: 1,
                  )),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Sender Name'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${controller.data.value.senderName}",
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Sender Contact'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.senderPhone}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                              const SizedBox(width: 5),
                              InkWell(
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Constant.makePhoneCall(controller.data.value.driverPhone.toString());
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/ic_phone.svg',
                                  colorFilter: ColorFilter.mode(
                                    AppThemeData.secondary200,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Receiver Name'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${controller.data.value.receiverName}",
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Receiver Contact'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.receiverPhone}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                              const SizedBox(
                                width: 5,
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Constant.makePhoneCall(controller.data.value.driverPhone.toString());
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/ic_phone.svg',
                                  colorFilter: ColorFilter.mode(
                                    AppThemeData.secondary200,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Duration'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${controller.data.value.duration}",
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Weight (KG)'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.parcelWeight}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Size (ft)'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${controller.data.value.parcelDimension}",
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Parcel Type'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.title}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('PickUp Date'.tr,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.parcelDate} ${controller.data.value.parcelTime}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Drop Date'.tr,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${controller.data.value.receiveDate} ${controller.data.value.receiveTime}",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("Bill Details".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontSize: 16,
                )),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  border: Border.all(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    width: 1,
                  )),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Parcle Cost'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(Constant().amountShow(amount: controller.subTotalAmount.toString()),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Discount'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("(-${Constant().amountShow(amount: controller.discountAmount.toString())})",
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    height: 1,
                  ),
                  ListView.builder(
                    itemCount: Constant.taxList.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      TaxModel taxModel = Constant.taxList[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text('${taxModel.libelle.toString()} (${taxModel.type == "Fixed" ? Constant().amountShow(amount: taxModel.value) : "${taxModel.value}%"})',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.regular,
                                        color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        fontSize: 16,
                                      )),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(Constant().amountShow(amount: controller.calculateTax(taxModel: taxModel).toString()),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                        fontSize: 16,
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                            height: 1,
                          ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Total Payable Amount'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(Constant().amountShow(amount: controller.getTotalAmount().toString()),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("Order Details".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontSize: 16,
                )),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  border: Border.all(
                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    width: 1,
                  )),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Order ID'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("#${controller.data.value.id}",
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                fontSize: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text('Payment Via'.tr,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    fontSize: 16,
                                  )),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("${"Paid using".tr} ${controller.data.value.libelle ?? ''}",
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.light,
                                        color: AppThemeData.primary200,
                                        fontSize: 16,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector buildOtherDetails({
    required String title,
    required String value,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(title, style: TextStyle(color: ConstantColors.subTitleTextColor, fontWeight: FontWeight.w500)),
          const SizedBox(
            height: 5,
          ),
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ConstantColors.titleTextColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Padding buildUsersDetails(context, ParcelPaymentController controller, {bool isSender = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isSender ? "${"Sender".tr} " : "${"Receiver".tr} ",
                style: TextStyle(fontSize: 16, color: isSender ? AppThemeData.primary200 : const Color(0xffd17e19)),
              ),
              Text(
                isSender ? controller.data.value.senderName.toString() : controller.data.value.receiverName.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            isSender ? controller.data.value.senderPhone.toString() : controller.data.value.receiverPhone.toString(),
            style: TextStyle(fontSize: 16, color: ConstantColors.subTitleTextColor),
          ),
          Text(
            isSender ? controller.data.value.source.toString() : controller.data.value.destination.toString(),
            style: TextStyle(fontSize: 16, color: ConstantColors.subTitleTextColor),
          ),
        ],
      ),
    );
  }

  Column buildLine() {
    return Column(
      children: [
        const SizedBox(
          height: 6,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          child: Image.asset("assets/images/circle.png", height: 20),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2),
          child: SizedBox(
            width: 1.3,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: 15,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Container(
                      color: Colors.black38,
                      height: 2.5,
                    ),
                  );
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset("assets/images/parcel_Image.png", height: 20),
        ),
      ],
    );
  }

  Padding buildAmountWidget(ParcelPaymentController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(
                    "Sub Total".tr,
                    style: TextStyle(letterSpacing: 1.0, color: ConstantColors.subTitleTextColor, fontWeight: FontWeight.w600),
                  )),
                  Text(Constant().amountShow(amount: controller.data.value.amount.toString()),
                      style: TextStyle(letterSpacing: 1.0, color: ConstantColors.titleTextColor, fontWeight: FontWeight.w800)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Divider(
                  color: Colors.black.withValues(alpha: 0.40),
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    "Discount".tr,
                    style: TextStyle(letterSpacing: 1.0, color: ConstantColors.subTitleTextColor, fontWeight: FontWeight.w600),
                  )),
                  Text("(-${Constant().amountShow(amount: controller.data.value.discount.toString())})",
                      style: const TextStyle(letterSpacing: 1.0, color: Colors.red, fontWeight: FontWeight.w800)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Divider(
                  color: Colors.black.withValues(alpha: 0.40),
                ),
              ),
              ListView.builder(
                itemCount: controller.data.value.paymentStatus == "yes" ? controller.data.value.taxModel!.length : Constant.taxList.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  TaxModel taxModel = controller.data.value.paymentStatus == "yes" ? controller.data.value.taxModel![index] : Constant.taxList[index];
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${taxModel.libelle.toString()} (${taxModel.type == "Fixed" ? Constant().amountShow(amount: taxModel.value) : "${taxModel.value}%"})',
                            style: TextStyle(letterSpacing: 1.0, color: ConstantColors.subTitleTextColor, fontWeight: FontWeight.w600),
                          ),
                          Text(Constant().amountShow(amount: controller.calculateTax(taxModel: taxModel).toString()),
                              style: TextStyle(letterSpacing: 1.0, color: ConstantColors.titleTextColor, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Divider(
                          color: Colors.black.withValues(alpha: 0.40),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Visibility(
                visible: controller.tipAmount.value == 0 ? false : true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                          "Driver Tip".tr,
                          style: TextStyle(letterSpacing: 1.0, color: ConstantColors.subTitleTextColor, fontWeight: FontWeight.w600),
                        )),
                        Text(Constant().amountShow(amount: controller.tipAmount.toString()),
                            style: TextStyle(letterSpacing: 1.0, color: ConstantColors.titleTextColor, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Divider(
                        color: Colors.black.withValues(alpha: 0.40),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    "Total".tr,
                    style: TextStyle(letterSpacing: 1.0, color: ConstantColors.titleTextColor, fontWeight: FontWeight.w600),
                  )),
                  Text(Constant().amountShow(amount: controller.getTotalAmount().toString()),
                      style: TextStyle(letterSpacing: 1.0, color: AppThemeData.primary200, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
