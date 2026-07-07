import 'package:cabme_driver/model/settings_model.dart';
import 'package:cabme_driver/model/subscription_plan_model.dart';

class UserModel {
  String? success;
  String? error;
  String? message;
  UserData? userData;

  UserModel({this.success, this.error, this.message, this.userData});

  UserModel.fromJson(Map<String, dynamic> json) {
    success = json['success'].toString();
    error = json['error'].toString();
    message = json['message'].toString();
    userData = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (userData != null) {
      data['data'] = userData!.toJson();
    }
    return data;
  }
}

class UserData {
  String? id;
  String? mPin;
  String? acNo;
  String? startDate;
  String? endDate;
  String? startDate2;
  String? endDate2;
  String? startDate3;
  String? endDate3;
  String? startDate4;
  String? endDate4;
  String? perSender;
  String? perReceiver;
  String? percentage;
  String? senderDesc;
  String? receiverDesc;
  String? description2nd;
  String? description3rd;
  String? per3rd;
  String? amount3rd;
  String? amount4th;
  String? description4th;
  String? kycStatus;
  String? nom;
  String? prenom;
  String? cnib;
  String? phone;
  String? latitude;
  String? longitude;
  String? email;
  String? statut;
  String? statutLicence;
  String? statutNic;
  String? statutVehicule;
  String? isVerified;
  String? statutCarServiceBook;
  String? statutRoadWorthy;
  String? statusCarImage;
  String? online;
  String? loginType;
  String? photo;
  String? photoPath;
  String? photoLicence;
  String? photoLicencePath;
  String? photoNic;
  String? photoNicPath;
  String? photoCarServiceBook;
  String? photoCarServiceBookPath;
  String? photoRoadWorthy;
  String? photoRoadWorthyPath;
  String? tonotify;
  String? deviceId;
  String? fcmId;
  String? address;
  String? bankName;
  String? branchName;
  String? holderName;
  String? accountNo;
  String? otherInfo;
  String? ifscCode;
  String? creer;
  String? modifier;
  String? updatedAt;
  String? amount;
  String? earnAmount;
  String? resetPasswordOtp;
  String? resetPasswordOtpModifier;
  String? deletedAt;
  String? userCat;
  String? country;
  String? adminCommissionValue;
  String? commisionType;
  String? brand;
  String? model;
  String? color;
  String? numberplate;
  String? accesstoken;
  String? parcelDelivery;
  String? zoneId;
  String? driverOnRide;
  String? subscriptionPlanId;
  String? subscriptionExpiryDate;
  String? subscriptionTotalOrders;
  String? categoryId;
  SubscriptionPlanData? subscriptionPlan;
  AdminCommission? adminCommission;
  List<String>? selectedCategories;
  String? onboardingCompleted; // 'yes' or 'no' — set by backend based on tj_conducteur_categories
  String? alternatePhone;
  String? marketplaceEnabled;

  UserData({
    this.id,
    this.mPin,
    this.acNo,
    this.startDate,
    this.endDate,
    this.startDate2,
    this.endDate2,
    this.startDate3,
    this.endDate3,
    this.startDate4,
    this.endDate4,
    this.perSender,
    this.perReceiver,
    this.percentage,
    this.senderDesc,
    this.receiverDesc,
    this.description2nd,
    this.description3rd,
    this.per3rd,
    this.amount3rd,
    this.amount4th,
    this.description4th,
    this.kycStatus,
    this.nom,
    this.prenom,
    this.cnib,
    this.phone,
    this.latitude,
    this.longitude,
    this.email,
    this.statut,
    this.statutLicence,
    this.statutNic,
    this.statutVehicule,
    this.isVerified,
    this.statutCarServiceBook,
    this.statutRoadWorthy,
    this.statusCarImage,
    this.online,
    this.loginType,
    this.photo,
    this.photoPath,
    this.photoLicence,
    this.photoLicencePath,
    this.photoNic,
    this.photoNicPath,
    this.photoCarServiceBook,
    this.photoCarServiceBookPath,
    this.photoRoadWorthy,
    this.photoRoadWorthyPath,
    this.tonotify,
    this.deviceId,
    this.fcmId,
    this.address,
    this.bankName,
    this.branchName,
    this.holderName,
    this.accountNo,
    this.otherInfo,
    this.ifscCode,
    this.creer,
    this.modifier,
    this.updatedAt,
    this.amount,
    this.earnAmount,
    this.resetPasswordOtp,
    this.resetPasswordOtpModifier,
    this.deletedAt,
    this.userCat,
    this.country,
    this.adminCommissionValue,
    this.commisionType,
    this.brand,
    this.model,
    this.color,
    this.numberplate,
    this.accesstoken,
    this.parcelDelivery,
    this.zoneId,
    this.driverOnRide,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionTotalOrders,
    this.categoryId,
    this.subscriptionPlan,
    this.adminCommission,
    this.selectedCategories,
    this.onboardingCompleted,
    this.alternatePhone,
    this.marketplaceEnabled,
  });

  UserData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    mPin = json['m_pin']?.toString();
    acNo = json['ac_no']?.toString();
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    startDate2 = json['start_date2']?.toString();
    endDate2 = json['end_date2']?.toString();
    startDate3 = json['start_date3']?.toString();
    endDate3 = json['end_date3']?.toString();
    startDate4 = json['start_date4']?.toString();
    endDate4 = json['end_date4']?.toString();
    perSender = json['per_sender']?.toString();
    perReceiver = json['per_receiver']?.toString();
    percentage = json['percentage']?.toString();
    senderDesc = json['sender_desc']?.toString();
    receiverDesc = json['receiver_desc']?.toString();
    description2nd = json['description_2nd']?.toString();
    description3rd = json['description_3rd']?.toString();
    per3rd = json['per_3rd']?.toString();
    amount3rd = json['amount_3rd']?.toString();
    amount4th = json['amount_4th']?.toString();
    description4th = json['description_4th']?.toString();
    kycStatus = json['kyc_status']?.toString();
    nom = json['nom']?.toString();
    prenom = json['prenom']?.toString();
    cnib = json['cnib']?.toString();
    phone = json['phone']?.toString();
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    email = json['email']?.toString();
    statut = json['statut']?.toString();
    statutLicence = json['statut_licence']?.toString();
    statutNic = json['statut_nic']?.toString();
    statutVehicule = json['statut_vehicule']?.toString();
    isVerified = json['is_verified']?.toString();
    statutCarServiceBook = json['statut_car_service_book']?.toString();
    statutRoadWorthy = json['statut_road_worthy']?.toString();
    statusCarImage = json['status_car_image']?.toString();
    online = json['online']?.toString();
    loginType = json['login_type']?.toString();
    photo = json['photo']?.toString();
    photoPath = json['photo_path']?.toString();
    photoLicence = json['photo_licence']?.toString();
    photoLicencePath = json['photo_licence_path']?.toString();
    photoNic = json['photo_nic']?.toString();
    photoNicPath = json['photo_nic_path']?.toString();
    photoCarServiceBook = json['photo_car_service_book']?.toString();
    photoCarServiceBookPath = json['photo_car_service_book_path']?.toString();
    photoRoadWorthy = json['photo_road_worthy']?.toString();
    photoRoadWorthyPath = json['photo_road_worthy_path']?.toString();
    tonotify = json['tonotify']?.toString();
    deviceId = json['device_id']?.toString();
    fcmId = json['fcm_id']?.toString();
    address = json['address']?.toString();
    bankName = json['bank_name']?.toString();
    branchName = json['branch_name']?.toString();
    holderName = json['holder_name']?.toString();
    accountNo = json['account_no']?.toString();
    otherInfo = json['other_info']?.toString();
    ifscCode = json['ifsc_code']?.toString();
    creer = json['creer']?.toString();
    modifier = json['modifier']?.toString();
    updatedAt = json['updated_at']?.toString();
    amount = json['amount']?.toString();
    earnAmount = json['earn_amount']?.toString();
    resetPasswordOtp = json['reset_password_otp']?.toString();
    resetPasswordOtpModifier = json['reset_password_otp_modifier']?.toString();
    deletedAt = json['deleted_at']?.toString();
    userCat = json['user_cat']?.toString();
    country = json['country']?.toString();
    adminCommissionValue = json['admin_commission']?.toString();
    commisionType = json['commision_type']?.toString();
    brand = json['brand']?.toString();
    model = json['model']?.toString();
    color = json['color']?.toString();
    numberplate = json['numberplate']?.toString();
    accesstoken = json['accesstoken']?.toString();
    parcelDelivery = json['parcel_delivery']?.toString();
    zoneId = json['zone_id']?.toString();
    driverOnRide = json['driver_on_ride']?.toString();
    categoryId = json['category_id']?.toString();
    subscriptionPlanId = json['subscriptionPlanId']?.toString();
    subscriptionExpiryDate = json['subscriptionExpiryDate']?.toString();
    subscriptionTotalOrders = json['subscriptionTotalOrders']?.toString();
    subscriptionPlan = json['subscription_plan'] != null
        ? SubscriptionPlanData.fromJson(json['subscription_plan'])
        : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    if (json['selected_categories'] != null) {
      selectedCategories = List<String>.from(json['selected_categories'].map((x) => x.toString()));
    }
    onboardingCompleted = json['onboarding_completed']?.toString();
    alternatePhone = json['alternate_phone']?.toString();
    marketplaceEnabled = json['marketplace_enabled']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['m_pin'] = mPin;
    data['ac_no'] = acNo;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['start_date2'] = startDate2;
    data['end_date2'] = endDate2;
    data['start_date3'] = startDate3;
    data['end_date3'] = endDate3;
    data['start_date4'] = startDate4;
    data['end_date4'] = endDate4;
    data['per_sender'] = perSender;
    data['per_receiver'] = perReceiver;
    data['percentage'] = percentage;
    data['sender_desc'] = senderDesc;
    data['receiver_desc'] = receiverDesc;
    data['description_2nd'] = description2nd;
    data['description_3rd'] = description3rd;
    data['per_3rd'] = per3rd;
    data['amount_3rd'] = amount3rd;
    data['amount_4th'] = amount4th;
    data['description_4th'] = description4th;
    data['kyc_status'] = kycStatus;
    data['nom'] = nom;
    data['prenom'] = prenom;
    data['cnib'] = cnib;
    data['phone'] = phone;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['email'] = email;
    data['statut'] = statut;
    data['statut_licence'] = statutLicence;
    data['statut_nic'] = statutNic;
    data['statut_vehicule'] = statutVehicule;
    data['is_verified'] = isVerified;
    data['statut_car_service_book'] = statutCarServiceBook;
    data['statut_road_worthy'] = statutRoadWorthy;
    data['status_car_image'] = statusCarImage;
    data['online'] = online;
    data['login_type'] = loginType;
    data['photo'] = photo;
    data['photo_path'] = photoPath;
    data['photo_licence'] = photoLicence;
    data['photo_licence_path'] = photoLicencePath;
    data['photo_nic'] = photoNic;
    data['photo_nic_path'] = photoNicPath;
    data['photo_car_service_book'] = photoCarServiceBook;
    data['photo_car_service_book_path'] = photoCarServiceBookPath;
    data['photo_road_worthy'] = photoRoadWorthy;
    data['photo_road_worthy_path'] = photoRoadWorthyPath;
    data['tonotify'] = tonotify;
    data['device_id'] = deviceId;
    data['fcm_id'] = fcmId;
    data['address'] = address;
    data['bank_name'] = bankName;
    data['branch_name'] = branchName;
    data['holder_name'] = holderName;
    data['account_no'] = accountNo;
    data['other_info'] = otherInfo;
    data['ifsc_code'] = ifscCode;
    data['creer'] = creer;
    data['modifier'] = modifier;
    data['updated_at'] = updatedAt;
    data['amount'] = amount;
    data['earn_amount'] = earnAmount;
    data['reset_password_otp'] = resetPasswordOtp;
    data['reset_password_otp_modifier'] = resetPasswordOtpModifier;
    data['deleted_at'] = deletedAt;
    data['user_cat'] = userCat;
    data['country'] = country;
    data['admin_commission'] = adminCommissionValue;
    data['commision_type'] = commisionType;
    data['brand'] = brand;
    data['model'] = model;
    data['color'] = color;
    data['numberplate'] = numberplate;
    data['accesstoken'] = accesstoken;
    data['parcel_delivery'] = parcelDelivery;
    data['zone_id'] = zoneId;
    data['driver_on_ride'] = driverOnRide;
    data['category_id'] = categoryId;
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscriptionTotalOrders'] = subscriptionTotalOrders;
    if (subscriptionPlan != null) {
      data['subscription_plan'] = subscriptionPlan!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (selectedCategories != null) {
      data['selected_categories'] = selectedCategories;
    }
    data['onboarding_completed'] = onboardingCompleted;
    data['alternate_phone'] = alternatePhone;
    data['marketplace_enabled'] = marketplaceEnabled;
    return data;
  }
}

// import 'package:cabme_driver/model/settings_model.dart';
// import 'package:cabme_driver/model/subscription_plan_model.dart';
//
// class UserModel {
//   String? success;
//   String? error;
//   String? message;
//   UserData? userData;
//
//   UserModel({this.success, this.error, this.message, this.userData});
//
//   UserModel.fromJson(Map<String, dynamic> json) {
//     success = json['success'].toString();
//     error = json['error'].toString();
//     message = json['message'].toString();
//     userData = json['data'] != null ? UserData.fromJson(json['data']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['success'] = success;
//     data['error'] = error;
//     data['message'] = message;
//     if (userData != null) {
//       data['data'] = userData!.toJson();
//     }
//     return data;
//   }
// }
//
// class UserData {
//   String? id;
//   String? nom;
//   String? prenom;
//   String? cnib;
//   String? phone;
//   String? latitude;
//   String? longitude;
//   String? email;
//   String? statut;
//   String? statutLicence;
//   String? statutNic;
//   String? statutVehicule;
//   String? isVerified;
//   String? statutCarServiceBook;
//   String? statutRoadWorthy;
//   String? statusCarImage;
//   String? online;
//   String? loginType;
//   String? photo;
//   String? photoPath;
//   String? photoLicence;
//   String? photoLicencePath;
//   String? photoNic;
//   String? photoNicPath;
//   String? photoCarServiceBook;
//   String? photoCarServiceBookPath;
//   String? photoRoadWorthy;
//   String? photoRoadWorthyPath;
//   String? tonotify;
//   String? deviceId;
//   String? fcmId;
//
//   String? creer;
//   String? modifier;
//   String? updatedAt;
//   String? amount;
//   String? resetPasswordOtp;
//   String? resetPasswordOtpModifier;
//   String? deletedAt;
//   String? userCat;
//   String? country;
//   String? brand;
//   String? model;
//   String? color;
//   String? numberplate;
//   String? accesstoken;
//   String? parcelDelivery;
//
//   String? subscriptionPlanId;
//   String? subscriptionExpiryDate;
//   String? subscriptionTotalOrders;
//   SubscriptionPlanData? subscriptionPlan;
//   AdminCommission? adminCommission;
//
//
//   UserData({
//     this.id,
//     this.nom,
//     this.prenom,
//     this.cnib,
//     this.phone,
//     this.latitude,
//     this.longitude,
//     this.email,
//     this.statut,
//     this.statutLicence,
//     this.statutNic,
//     this.statutVehicule,
//     this.isVerified,
//     this.statutCarServiceBook,
//     this.statutRoadWorthy,
//     this.statusCarImage,
//     this.online,
//     this.loginType,
//     this.photo,
//     this.photoPath,
//     this.photoLicence,
//     this.photoLicencePath,
//     this.photoNic,
//     this.photoNicPath,
//     this.photoCarServiceBook,
//     this.photoCarServiceBookPath,
//     this.photoRoadWorthy,
//     this.photoRoadWorthyPath,
//     this.tonotify,
//     this.deviceId,
//     this.fcmId,
//     this.creer,
//     this.modifier,
//     this.updatedAt,
//     this.amount,
//     this.resetPasswordOtp,
//     this.resetPasswordOtpModifier,
//     this.deletedAt,
//     this.userCat,
//     this.country,
//     this.brand,
//     this.model,
//     this.color,
//     this.numberplate,
//     this.accesstoken,
//     this.parcelDelivery,
//
//     this.subscriptionPlanId,
//     this.subscriptionExpiryDate,
//     this.subscriptionTotalOrders,
//     this.subscriptionPlan,
//     this.adminCommission,
//   });
//
//   UserData.fromJson(Map<String, dynamic> json) {
//     id = json['id'].toString();
//     nom = json['nom'].toString();
//     prenom = json['prenom'].toString();
//     cnib = json['cnib'].toString();
//     phone = json['phone'].toString();
//     latitude = json['latitude'].toString();
//     longitude = json['longitude'].toString();
//     email = json['email'].toString();
//     statut = json['statut'].toString();
//     statutLicence = json['statut_licence'].toString();
//     statutNic = json['statut_nic'].toString();
//     statutVehicule = json['statut_vehicule'].toString();
//     isVerified = json['is_verified'].toString();
//     statutCarServiceBook = json['statut_car_service_book'].toString();
//     statutRoadWorthy = json['statut_road_worthy'].toString();
//     statusCarImage = json['status_car_image'].toString();
//     online = json['online'].toString();
//     loginType = json['login_type'].toString();
//     photo = json['photo'].toString();
//     photoPath = json['photo_path'].toString();
//     photoLicence = json['photo_licence'].toString();
//     photoLicencePath = json['photo_licence_path'].toString();
//     photoNic = json['photo_nic'].toString();
//     photoNicPath = json['photo_nic_path'].toString();
//     photoCarServiceBook = json['photo_car_service_book'].toString();
//     photoCarServiceBookPath = json['photo_car_service_book_path'].toString();
//     photoRoadWorthy = json['photo_road_worthy'].toString();
//     photoRoadWorthyPath = json['photo_road_worthy_path'].toString();
//     tonotify = json['tonotify'].toString();
//     deviceId = json['device_id'].toString();
//     fcmId = json['fcm_id'].toString();
//     creer = json['creer'].toString();
//     modifier = json['modifier'].toString();
//     updatedAt = json['updated_at'].toString();
//     amount = json['amount'].toString();
//     resetPasswordOtp = json['reset_password_otp'].toString();
//     resetPasswordOtpModifier = json['reset_password_otp_modifier'].toString();
//     deletedAt = json['deleted_at'].toString();
//     userCat = json['user_cat'].toString();
//     country = json['country'].toString();
//     brand = json['brand'].toString();
//     model = json['model'].toString();
//     color = json['color'].toString();
//     numberplate = json['numberplate'].toString();
//     accesstoken = json['accesstoken'].toString();
//     parcelDelivery = json['parcel_delivery'].toString();
//     adminCommission = json['adminCommission'] != null
//         ? AdminCommission.fromJson(json['adminCommission'])
//         : null;
//     subscriptionPlanId = json['subscriptionPlanId'];
//     subscriptionExpiryDate = json['subscriptionExpiryDate'];
//     subscriptionTotalOrders = json['subscriptionTotalOrders'];
//     subscriptionPlan = json['subscription_plan'] != null
//         ? SubscriptionPlanData.fromJson(json['subscription_plan'])
//         : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['nom'] = nom;
//     data['prenom'] = prenom;
//     data['cnib'] = cnib;
//     data['phone'] = phone;
//     data['latitude'] = latitude;
//     data['longitude'] = longitude;
//     data['email'] = email;
//     data['statut'] = statut;
//     data['statut_licence'] = statutLicence;
//     data['statut_nic'] = statutNic;
//     data['statut_vehicule'] = statutVehicule;
//     data['is_verified'] = isVerified;
//     data['statut_car_service_book'] = statutCarServiceBook;
//     data['statut_road_worthy'] = statutRoadWorthy;
//     data['status_car_image'] = statusCarImage;
//     data['online'] = online;
//     data['login_type'] = loginType;
//     data['photo'] = photo;
//     data['photo_path'] = photoPath;
//     data['photo_licence'] = photoLicence;
//     data['photo_licence_path'] = photoLicencePath;
//     data['photo_nic'] = photoNic;
//     data['photo_nic_path'] = photoNicPath;
//     data['photo_car_service_book'] = photoCarServiceBook;
//     data['photo_car_service_book_path'] = photoCarServiceBookPath;
//     data['photo_road_worthy'] = photoRoadWorthy;
//     data['photo_road_worthy_path'] = photoRoadWorthyPath;
//     data['tonotify'] = tonotify;
//     data['device_id'] = deviceId;
//     data['fcm_id'] = fcmId;
//     data['creer'] = creer;
//     data['modifier'] = modifier;
//     data['updated_at'] = updatedAt;
//     data['amount'] = amount;
//     data['reset_password_otp'] = resetPasswordOtp;
//     data['reset_password_otp_modifier'] = resetPasswordOtpModifier;
//     data['deleted_at'] = deletedAt;
//     data['user_cat'] = userCat;
//     data['country'] = country;
//     data['brand'] = brand;
//     data['model'] = model;
//     data['color'] = color;
//     data['numberplate'] = numberplate;
//     data['accesstoken'] = accesstoken;
//     data['parcel_delivery'] = parcelDelivery;
//     data['subscriptionPlanId'] = subscriptionPlanId;
//     data['subscriptionExpiryDate'] = subscriptionExpiryDate;
//     data['subscriptionTotalOrders'] = subscriptionTotalOrders;
//     if (subscriptionPlan != null) {
//       data['subscription_plan'] = subscriptionPlan!.toJson();
//     }
//     if (adminCommission != null) {
//       data['adminCommission'] = adminCommission!.toJson();
//     }
//     return data;
//   }
// }
