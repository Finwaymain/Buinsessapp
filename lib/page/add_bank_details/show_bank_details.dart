import 'package:cabme_driver/controller/bank_details_controller.dart';
import 'package:cabme_driver/page/add_bank_details/add_bank_account.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ShowBankDetails extends StatelessWidget {
  const ShowBankDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<BankDetailsController>(
      init: BankDetailsController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppbarCustom(title: 'Add Bank Details'.tr),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: controller.isLoading.value
                ? SizedBox()
                : controller.bankDetails.value.bankName == null &&
                        controller.bankDetails.value.branchName == null &&
                        controller.bankDetails.value.holderName == null &&
                        controller.bankDetails.value.accountNo == null &&
                        controller.bankDetails.value.otherInfo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Image.asset('assets/images/add_bank_placeholder.png'),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 100),
                            child: Text(
                              'You have not  added bank account \n please add bank account'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey400, fontFamily: AppThemeData.regular),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 40, left: 25, right: 25),
                            child: ButtonThem.buildButton(
                              context,
                              btnHeight: 44,
                              title: "Add Bank".tr,
                              btnColor: AppThemeData.primary200,
                              txtColor: Colors.white,
                              onPress: () {
                                showModalBottomSheet(
                                    isDismissible: true,
                                    isScrollControlled: true,
                                    context: context,
                                    backgroundColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                                    builder: (context) {
                                      return const AddBankAccount();
                                    });
                              },
                            ),
                          )
                        ],
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_bank_2.svg',
                                          width: 25,
                                          height: 25,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'Bank Name'.tr,
                                            style: TextStyle(
                                              color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                              fontFamily: AppThemeData.regular,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.bankName.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_bank_2.svg',
                                          width: 23,
                                          height: 23,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'Branch Name'.tr,
                                            style: TextStyle(
                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark, fontFamily: AppThemeData.regular, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.branchName.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_user.svg',
                                          width: 23,
                                          height: 23,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'Holder Name'.tr,
                                            style: TextStyle(
                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark, fontFamily: AppThemeData.regular, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.holderName.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_number.svg',
                                          width: 23,
                                          height: 23,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'Account Number'.tr,
                                            style: TextStyle(
                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark, fontFamily: AppThemeData.regular, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.accountNo.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_barcode.svg',
                                          width: 23,
                                          height: 23,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'IFSC Code'.tr,
                                            style: TextStyle(
                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark, fontFamily: AppThemeData.regular, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.ifscCode.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/ic_list.svg',
                                          width: 23,
                                          height: 23,
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            'Other Information'.tr,
                                            style: TextStyle(
                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark, fontFamily: AppThemeData.medium, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, left: 38),
                                      child: Text(
                                        controller.bankDetails.value.otherInfo.toString(),
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(top: 30, left: 12, right: 12),
                                  child: ButtonThem.buildButton(
                                    context,
                                    btnHeight: 50,
                                    title: "Edit bank".tr,
                                    btnColor: AppThemeData.primary200,
                                    txtColor: Colors.black,
                                    onPress: () {
                                      showModalBottomSheet(
                                          isDismissible: true,
                                          isScrollControlled: true,
                                          context: context,
                                          backgroundColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                                          builder: (context) {
                                            return const AddBankAccount();
                                          });
                                    },
                                  ))

                              //  if (value != null) {
                              //       if (value == true) {
                              //         controller.getBankDetails();
                              //       }
                              //     }
                            ],
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }
}
