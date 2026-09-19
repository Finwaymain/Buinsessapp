import 'dart:convert';
import 'package:cabme_driver/model/tax_model.dart';

class ParcelModel {
  String? success;
  dynamic error;
  String? message;
  List<ParcelData>? data;

  ParcelModel({this.success, this.error, this.message, this.data});

  ParcelModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ParcelData>[];
      json['data'].forEach((v) {
        data!.add(ParcelData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ParcelData {
  String? id;
  String? idUserApp;
  String? idConducteur;
  String? source;
  String? destination;
  String? latSource;
  String? lngSource;
  String? latDestination;
  String? lngDestination;
  String? sourceCity;
  String? destinationCity;
  String? senderName;
  String? senderPhone;
  String? receiverName;
  String? receiverPhone;
  String? parcelWeight;
  List<String>? parcelImage;
  String? parcelType;
  String? parcelDate;
  String? parcelTime;
  String? receiveDate;
  String? receiveTime;
  String? status;
  String? note;
  String? paymentStatus;
  String? idPaymentMethod;
  String? duration;
  String? distance;
  String? distanceUnit;
  String? amount;
  String? discount;
  List<TaxModel>? taxModel;
  String? adminCommission;
  String? otp;
  String? rejectedDriverId;
  String? createdAt;
  String? updatedAt;
  String? libelle;
  String? paymentImage;
  String? title;
  String? phone;
  String? nomConducteur;
  String? prenomConducteur;
  String? driverPhone;
  String? photoPath;
  String? moyenne;
  String? moyenneDriver;
  String? userPhone;
  String? userPhoto;
  String? userName;
  String? driverName;
  String? driverId;
  String? driverPhoto;
  String? tip;
  String? parcelDimension;

  ParcelData({
    this.id,
    this.idUserApp,
    this.idConducteur,
    this.source,
    this.destination,
    this.latSource,
    this.lngSource,
    this.latDestination,
    this.lngDestination,
    this.sourceCity,
    this.destinationCity,
    this.senderName,
    this.senderPhone,
    this.receiverName,
    this.receiverPhone,
    this.parcelWeight,
    this.parcelImage,
    this.parcelType,
    this.parcelDate,
    this.parcelTime,
    this.receiveDate,
    this.receiveTime,
    this.status,
    this.note,
    this.paymentStatus,
    this.idPaymentMethod,
    this.duration,
    this.distance,
    this.distanceUnit,
    this.amount,
    this.discount,
    this.taxModel,
    this.adminCommission,
    this.otp,
    this.rejectedDriverId,
    this.createdAt,
    this.updatedAt,
    this.libelle,
    this.paymentImage,
    this.title,
    this.phone,
    this.nomConducteur,
    this.prenomConducteur,
    this.driverPhone,
    this.photoPath,
    this.moyenne,
    this.moyenneDriver,
    this.userPhone,
    this.userPhoto,
    this.userName,
    this.driverName,
    this.driverId,
    this.driverPhoto,
    this.tip,
    this.parcelDimension,
  });

  ParcelData.fromJson(Map<String, dynamic> json) {
    List<TaxModel>? taxList = [];
    if (json['tax'] != null) {
      taxList = <TaxModel>[];
      json['tax'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
    id = json['id'].toString();
    idUserApp = json['id_user_app'];
    idConducteur = json['id_conducteur'];
    source = json['source'];
    destination = json['destination'];
    latSource = json['lat_source'];
    lngSource = json['lng_source'];
    latDestination = json['lat_destination'];
    lngDestination = json['lng_destination'];
    sourceCity = json['source_city'];
    destinationCity = json['destination_city'];
    senderName = json['sender_name'];
    senderPhone = json['sender_phone'];
    receiverName = json['receiver_name']?.toString();
    receiverPhone = json['receiver_phone']?.toString();
    parcelWeight = json['parcel_weight']?.toString();
    if (json['parcel_image'] != null) {
      if (json['parcel_image'] is List) {
        parcelImage = (json['parcel_image'] as List).map((e) => e.toString()).toList();
      } else if (json['parcel_image'] is String) {
        try {
          final decoded = jsonDecode(json['parcel_image']);
          if (decoded is List) {
            parcelImage = decoded.map((e) => e.toString()).toList();
          } else {
            parcelImage = [json['parcel_image'].toString()];
          }
        } catch (_) {
          parcelImage = [json['parcel_image'].toString()];
        }
      }
    } else {
      parcelImage = [];
    }
    parcelType = json['parcel_type']?.toString();
    parcelDate = json['parcel_date']?.toString();
    parcelTime = json['parcel_time']?.toString();
    receiveDate = json['receive_date']?.toString();
    receiveTime = json['receive_time']?.toString();
    status = json['status']?.toString();
    note = json['note']?.toString();
    paymentStatus = json['payment_status']?.toString();
    idPaymentMethod = json['id_payment_method']?.toString();

    duration = json['duration']?.toString();
    distance = json['distance']?.toString();
    distanceUnit = json['distance_unit']?.toString();
    amount = json['amount']?.toString();
    discount = json['discount']?.toString();
    taxModel = taxList;
    adminCommission = json['admin_commission']?.toString();
    otp = json['otp']?.toString();
    rejectedDriverId = json['rejected_driver_id']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    libelle = json['libelle']?.toString();
    paymentImage = json['payment_image']?.toString();
    title = json['title']?.toString();
    phone = json['phone']?.toString();
    nomConducteur = json['nomConducteur']?.toString();
    prenomConducteur = json['prenomConducteur']?.toString();
    driverPhone = json['driver_phone']?.toString();
    photoPath = json['photo_path']?.toString();
    moyenne = json['moyenne']?.toString();
    moyenneDriver = json['moyenne_driver']?.toString();
    userPhone = json['user_phone']?.toString();
    userPhoto = json['user_photo']?.toString();
    userName = json['user_name']?.toString();
    driverId = json['driver_id']?.toString();
    driverName = json['driver_name']?.toString();
    driverPhoto = json['driver_photo']?.toString();
    tip = json['tip']?.toString();
    parcelDimension = json['parcel_dimension']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['id_user_app'] = idUserApp;
    data['id_conducteur'] = idConducteur;
    data['source'] = source;
    data['destination'] = destination;
    data['lat_source'] = latSource;
    data['lng_source'] = lngSource;
    data['lat_destination'] = latDestination;
    data['lng_destination'] = lngDestination;
    data['source_city'] = sourceCity;
    data['destination_city'] = destinationCity;
    data['sender_name'] = senderName;
    data['sender_phone'] = senderPhone;
    data['receiver_name'] = receiverName;
    data['receiver_phone'] = receiverPhone;
    data['parcel_weight'] = parcelWeight;
    data['parcel_image'] = parcelImage;
    data['parcel_type'] = parcelType;
    data['parcel_date'] = parcelDate;
    data['parcel_time'] = parcelTime;
    data['receive_date'] = receiveDate;
    data['receive_time'] = receiveTime;
    data['status'] = status;
    data['note'] = note;
    data['payment_status'] = paymentStatus;
    data['id_payment_method'] = idPaymentMethod;
    data['duration'] = duration;
    data['distance'] = distance;
    data['distance_unit'] = distanceUnit;
    data['amount'] = amount;
    data['discount'] = discount;
    data['tax'] = taxModel?.map((v) => v.toJson()).toList();
    data['admin_commission'] = adminCommission;
    data['otp'] = otp;
    data['rejected_driver_id'] = rejectedDriverId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['libelle'] = libelle;
    data['payment_image'] = paymentImage;
    data['title'] = title;
    data['phone'] = phone;
    data['nomConducteur'] = nomConducteur;
    data['prenomConducteur'] = prenomConducteur;
    data['photo_path'] = photoPath;
    data['moyenne'] = moyenne;
    data['moyenne_driver'] = moyenneDriver;
    data['user_phone'] = userPhone;
    data['user_photo'] = userPhoto;
    data['user_name'] = userName;
    data['driver_id'] = driverId;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
    data['driver_photo'] = driverPhoto;
    data['tip'] = tip;
    data['parcel_dimension'] = parcelDimension;
    return data;
  }
}
