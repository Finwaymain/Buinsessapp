class AccountDetailsModel {
    String? res;
    String? msg;
    AccountData? data;

    AccountDetailsModel({this.res, this.msg, this.data});

    AccountDetailsModel.fromJson(Map<String, dynamic> json) {
        res = json['res'];
        msg = json['msg'];
        data = json['data'] != null ? AccountData.fromJson(json['data']) : null;
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['res'] = res;
        data['msg'] = msg;
        if (this.data != null) {
            data['data'] = this.data!.toJson();
        }
        return data;
    }
}

class AccountData {
    int? id;
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
    String? email;
    String? phone;
    String? mdp;

    String? latitude;
    String? longitude;

    String? loginType;
    String? photo;
    String? photoPath;
    String? photoNic;
    String? photoNicPath;

    String? photoLicence;
    String? photoLicencePath;
    String? photoCarServiceBook;
    String? photoCarServiceBookPath;
    String? photoRoadWorthy;
    String? photoRoadWorthyPath;

    String? statut;
    String? statutNic;
    String? statutVehicule;
    String? statusCarImage;
    String? online;

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
    String? updatedAt;
    String? modifier;

    String? amount;
    String? earnAmount;

    String? resetPasswordOtp;
    String? resetPasswordOtpModifier;

    String? age;
    String? gender;
    String? otp;
    String? otpCreated;

    String? deletedAt;
    String? createdAt;

    int? isVerified;
    String? parcelDelivery;
    String? zoneId;

    String? subscriptionPlanId;
    String? subscriptionExpiryDate;
    String? subscriptionTotalOrders;
    String? subscriptionPlan;
    String? adminCommission;

    String? driverOnRide;

    static int? _asInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        return int.tryParse(value.toString());
    }

    static String? _asString(dynamic value) {
        if (value == null) return null;
        if (value is Map || value is List) return null;
        return value.toString();
    }

    AccountData.fromJson(Map<String, dynamic> json) {
        id = _asInt(json['id']);
        mPin = _asString(json['m_pin']);
        acNo = _asString(json['ac_no']);
        startDate = _asString(json['start_date']);
        endDate = _asString(json['end_date']);
        nom = _asString(json['nom']);
        prenom = _asString(json['prenom']);
        phone = _asString(json['phone']);
        statut = _asString(json['statut']);
        holderName = _asString(json['holder_name']);
        bankName = _asString(json['bank_name']);
        branchName = _asString(json['branch_name']);
        accountNo = _asString(json['account_no']);
        ifscCode = _asString(json['ifsc_code'] ?? json['other_info']);
        otherInfo = _asString(json['other_info']);
        amount = _asString(json['amount']);
        earnAmount = _asString(json['earn_amount']);
        isVerified = _asInt(json['is_verified']);
        mdp = _asString(json['mdp']);
        email = _asString(json['email']);
        creer = _asString(json['creer']);
        updatedAt = _asString(json['updated_at']);
        subscriptionPlanId = _asString(json['subscriptionPlanId'] ?? json['subscription_plan_id']);
        adminCommission = _asString(json['adminCommission'] ?? json['admin_commission']);
        driverOnRide = _asString(json['driver_on_ride']);
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
        data['email'] = email;
        data['phone'] = phone;
        data['mdp'] = mdp;

        data['latitude'] = latitude;
        data['longitude'] = longitude;

        data['login_type'] = loginType;
        data['photo'] = photo;
        data['photo_path'] = photoPath;
        data['photo_nic'] = photoNic;
        data['photo_nic_path'] = photoNicPath;

        data['photo_licence'] = photoLicence;
        data['photo_licence_path'] = photoLicencePath;
        data['photo_car_service_book'] = photoCarServiceBook;
        data['photo_car_service_book_path'] = photoCarServiceBookPath;
        data['photo_road_worthy'] = photoRoadWorthy;
        data['photo_road_worthy_path'] = photoRoadWorthyPath;

        data['statut'] = statut;
        data['statut_nic'] = statutNic;
        data['statut_vehicule'] = statutVehicule;
        data['status_car_image'] = statusCarImage;
        data['online'] = online;

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

        data['age'] = age;
        data['gender'] = gender;
        data['otp'] = otp;
        data['otp_created'] = otpCreated;

        data['deleted_at'] = deletedAt;
        data['created_at'] = createdAt;

        data['is_verified'] = isVerified;
        data['parcel_delivery'] = parcelDelivery;
        data['zone_id'] = zoneId;

        data['subscriptionPlanId'] = subscriptionPlanId;
        data['subscriptionExpiryDate'] = subscriptionExpiryDate;
        data['subscriptionTotalOrders'] = subscriptionTotalOrders;
        data['subscription_plan'] = subscriptionPlan;
        data['adminCommission'] = adminCommission;

        data['driver_on_ride'] = driverOnRide;

        return data;
    }
    String getFullName() {
        final fromNames = '${prenom ?? ''} ${nom ?? ''}'.trim();
        if (fromNames.isNotEmpty) return fromNames;
        final holder = holderName?.trim();
        if (holder != null && holder.isNotEmpty) return holder;
        return '';
    }
    int? getDaysToStart() {if (startDate == null) return null;
        try { final expiry = DateTime.parse(startDate!);
            final now = DateTime.now();
            return now.difference(expiry).inDays;
        }
        catch (e) { return null;
        }
    }
    String? getFormattedStartDate() {if (startDate == null) return null;
        try { final expiry = DateTime.parse(startDate!);
            return '${expiry.month.toString().padLeft(2, '0')}/${expiry.year.toString().substring(2)}';
        }
        catch (e) { return null;
        }
    }

}
