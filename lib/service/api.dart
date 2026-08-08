import 'dart:io';

import 'package:cabme_driver/utils/Preferences.dart';

class API {
  static const baseUrl = "https://fiinway.online/api/v1/"; // Live VPS
  static const apiKey = "base64:nTfofcBByTDenJQYlsRbH0JjeVFW5lWsIIyXtq8/9sU=";

  static Map<String, String> get authheader => {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    'apikey': apiKey,
  };
  static Map<String, String> get header => {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    'apikey': apiKey,
    'accesstoken': Preferences.getString(Preferences.accesstoken)
  };

  static const userSignUP = "${baseUrl}user";
  static const userLogin = "${baseUrl}user-login";
  
  // MPIN Auth Endpoints
  static const authSendOtp = "${baseUrl}auth/send-otp";
  static const authVerifyOtp = "${baseUrl}auth/verify-otp";
  static const authLoginMpin = "${baseUrl}auth/login-by-mpin";
  static const authResetMpin = "${baseUrl}auth/reset-mpin";
  static const authRegisterSimple = "${baseUrl}auth/register-simple";
  static const authLoginByPhone = "${baseUrl}auth/login-by-phone";
  static const authVerifyLoginEmailOtp = "${baseUrl}auth/verify-login-email-otp";
  static const authCheckUser = "${baseUrl}auth/check-user";
  static const authLoginByMpin = "${baseUrl}auth/login-by-mpin";
  static const authSendPhoneOtp = "${baseUrl}auth/send-phone-otp";
  static const authVerifyPhoneOtp = "${baseUrl}auth/verify-phone-otp";
  static const authSendEmailOtp = "${baseUrl}auth/send-email-otp";
  static const authVerifyEmailRegister = "${baseUrl}auth/verify-email-otp-register";
  static const authUpdateDriverCategory = "${baseUrl}auth/update-driver-category";
  static const getDriverServices = "${baseUrl}driver/services";
  static const toggleDriverService = "${baseUrl}driver/services/toggle";

  static const getProfileByPhone = "${baseUrl}profilebyphone";
  static const getExistingUserOrNot = "${baseUrl}existing-user";
  static const sendResetPasswordOtp = "${baseUrl}reset-password-otp";
  static const getCustomer = "${baseUrl}users";

  static const resetPasswordOtp = "${baseUrl}resert-password";

  static const updatePreName = "${baseUrl}user-pre-name";
  static const updateLastName = "${baseUrl}user-name";

  static const onBoarding = "${baseUrl}on-boarding?type=Driver";

  static const updateLocation = "${baseUrl}update-position";
  static const contactUs = "${baseUrl}contact-us";
  static const changeStatus = "${baseUrl}change-status";
  static const driverDashboardStats = "${baseUrl}driver-dashboard-stats";
  static const updateToken = "${baseUrl}update-fcm";
  static const feelSafeAtDestination = "${baseUrl}feel-safe";
  static const conformPaymentByCash = "${baseUrl}payment-by-cash";
  static const getFcmToken = "${baseUrl}fcm-token";
  static const getRideReview = "${baseUrl}get-ride-review";

  static const userUpdateProfile = "${baseUrl}update-user-photo";
  static const documentList = "${baseUrl}documents";
  static const getDriverUploadedDocument = "${baseUrl}driver-documents";
  static const driverDocumentAdd = "${baseUrl}driver-documents-add";
  static const driverDocumentUpdate = "${baseUrl}driver-documents-update";

  static const conformRide = "${baseUrl}confirm-requete";
  static const rejectRide = "${baseUrl}set-rejected-requete";

  static const updateUserName = "${baseUrl}user-name";
  static const updateUserPhone = "${baseUrl}user-phone";
  static const updateUserEmail = "${baseUrl}update-user-email";
  static const updateUserAlternatePhone = "${baseUrl}user-alternate-phone";
  static const userToggleMarketplace = "${baseUrl}user-toggle-marketplace";
  static const changePassword = "${baseUrl}update-user-mdp";
  static const walletHistory = "${baseUrl}wallet-history";

  static const userLicence = "${baseUrl}update-user-licence";
  static const userRoadWorthyDoc = "${baseUrl}update-user-roadworthy";
  static const userCarServiceBook = "${baseUrl}update-user-carservice";
  static const getCarServiceBook = "${baseUrl}car-service-book?id_driver=";

  static const bookRides = "${baseUrl}requete-register";
  static const onRideRequest = "${baseUrl}onride-requete";
  static const getConformRide = "${baseUrl}requete-confirm";
  static const getOnRide = "${baseUrl}requete-onride";
  static const getCompletedRide = "${baseUrl}requete-complete";
  static const setCompleteRequest = "${baseUrl}complete-requete";
  static const getRejectRequest = "${baseUrl}requete-reject";

  static const getVehicleData = "${baseUrl}vehicle-driver?id_driver=";

  static const uploadCarServiceBook = "${baseUrl}car-service";

  static const updateVBrand = "${baseUrl}update-vehicle-brand";

  static const updateVColors = "${baseUrl}update-vehicle-color";
  static const updateVNoPlate = "${baseUrl}update-vehicle-numberplate";
  static const updateVModel = "${baseUrl}update-vehicle-model";
  static const categoryVModel = "${baseUrl}update-Vehicle-category";
  static const zoneUpdate = "${baseUrl}zone-update";

  static const vehicleRegister = "${baseUrl}vehicle";
  static const vehicleCategory = "${baseUrl}Vehicle-category";
  static const userCategories = "${baseUrl}user-categories";

  static const driverAllRides = "${baseUrl}driver-all-rides";
  static const newRide = "${baseUrl}requete";
  static const brand = "${baseUrl}brand";
  static const model = "${baseUrl}model";
  static const getZone = "${baseUrl}zone";
  static const bankDetails = "${baseUrl}bank-details";
  static const addBankDetails = "${baseUrl}add-bank-details";
  static const withdrawalsRequest = "${baseUrl}withdrawals";
  static const withdrawalsList = "${baseUrl}withdrawals-list";

  static const addReview = "${baseUrl}user-note";
  static const addComplaint = "${baseUrl}complaints";
  static const getComplaint = "${baseUrl}complaintsList";

  static const getLanguage = "${baseUrl}language";
  static const deleteUser = "${baseUrl}user-delete?user_id=";
  static const settings = "${baseUrl}settings";
  static const privacyPolicy = "${baseUrl}privacy-policy";
  static const termsOfCondition = "${baseUrl}terms-of-condition";
  static const rideOtpVerify = "${baseUrl}otp_verify";
  static const reGenerateOtp = "${baseUrl}otp";

  static const rideDetails = "${baseUrl}ridedetails";

  static const getPaymentMethod = "${baseUrl}payment-method";
  static const amount = "${baseUrl}amount";
  static const paymentSetting = "${baseUrl}payment-settings";
  static const payRequestCash = "${baseUrl}payment-by-cash";

  static const driverDetails = "${baseUrl}driver";

  //Parcel Service
  static const parcelContirm = "${baseUrl}parcel-confirm";
  static const parcelOnride = "${baseUrl}parcel-onride";
  static const parcelComplete = "${baseUrl}parcel-complete";
  static const parcelRejected = "${baseUrl}parcel-rejected";
  static const parcelSearch = "${baseUrl}search-driver-parcel-order";
  static const getDriverParcel = "${baseUrl}get-driver-parcel-orders";
  static const getParcelDetails = "${baseUrl}get-parcel-detail";

  //SubscriptionAPI
  static const getSubscriptionPlans = "${baseUrl}get-subscription-plans";
  static const getSubscriptionHistory = "${baseUrl}get-subscription-history";
  static const setSubscription = "${baseUrl}set-subscription";

  // referral Amount
  static const referralAmount = "${baseUrl}get-referral";
  static const wallet = "${baseUrl}wallet";

  // Smart Value
  static const accountDetails = "${baseUrl}get_profile/smart-value";
  static const showWalletAmount = "${baseUrl}show_wallet_amount/smart-value";
  static const getAddUser = "${baseUrl}showadduser/smart-value";
  static const addUser = "${baseUrl}adduser/smart-value";
  static const transferToWallet = "${baseUrl}transfer_to_wallet/smart-value";
  static const userSetMPin = "${baseUrl}user_changepasswordset/smart-value";
  static const withdrawWallet = "${baseUrl}withdrawWallet/smart-value";

  // Marketplace API Endpoints
  static const getMarketplaceProducts = "${baseUrl}marketplace/products";
  static const getMarketplaceProductDetails = "${baseUrl}marketplace/products/"; // + id
  static const getMarketplaceCategories = "${baseUrl}marketplace/categories";
  static const getMyMarketplaceProducts = "${baseUrl}marketplace/my-products";
  static const getMarketplaceProductProgress = "${baseUrl}marketplace/products/"; // + id + /progress
  static const createMarketplaceProduct = "${baseUrl}marketplace/products";
  static const uploadMarketplaceImage = "${baseUrl}marketplace/upload-image";
  static const updateMarketplaceProduct = "${baseUrl}marketplace/products/"; // + id + /update
  static const deleteMarketplaceProduct = "${baseUrl}marketplace/products/"; // + id + /delete

  // Marketplace Order APIs
  static const createMarketplaceOrder = "${baseUrl}marketplace/orders";
  static const getMarketplaceBuyerOrders = "${baseUrl}marketplace/orders/buyer";
  static const getMarketplaceSellerOrders = "${baseUrl}marketplace/orders/seller";
  static const getMarketplaceOrderDetails = "${baseUrl}marketplace/orders/"; // + id
  static const updateMarketplaceOrderStatus = "${baseUrl}marketplace/orders/"; // + id + /status

  // New Live Features API Endpoints
  static const unifiedTimelineHistory = "${baseUrl}history/timeline-full";
  static const referralStats = "${baseUrl}referral/stats";
  static const referralHistory = "${baseUrl}referral/history";
  static const businessPlansActive = "${baseUrl}business-plans/active";

  // All Services catalog ("More" section)
  static const getServiceCategories = "${baseUrl}service-categories";
  static const bookService = "${baseUrl}book-service";

  // My Booking console
  static const driverBookings = "${baseUrl}driver/bookings";
  static const driverServiceBookingStatus = "${baseUrl}driver/bookings/service-status";
}
