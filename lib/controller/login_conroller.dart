import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  Future<UserModel?> loginAPI(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.userLogin), headers: API.authheader, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.userLogin}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'].toString() == 'success') {
        ShowToastDialog.closeLoader();

        Preferences.setString(Preferences.accesstoken, responseBody['data']['accesstoken'].toString());
        Preferences.setString(Preferences.admincommissiontype, responseBody['data']['commision_type'].toString());

        Preferences.setString(Preferences.admincommission, responseBody['data']['admin_commission'].toString());
        Preferences.setString(Preferences.walletBalance, responseBody['data']['amount'].toString());
        Preferences.setBoolean(Preferences.documentVerified, responseBody['data']['is_verified'].toString() == "1" ? true : false);
        log("--${responseBody['data']}");
        API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
        return UserModel.fromJson(responseBody);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'].toString());
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }

  Future<bool?> phoneNumberIsExit(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.getExistingUserOrNot), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.getExistingUserOrNot} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        if (responseBody['data'] == true) {
          return true;
        } else {
          return false;
        }
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<UserModel?> getDataByPhoneNumber(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.getProfileByPhone), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.getProfileByPhone} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        return UserModel.fromJson(responseBody);
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<void> loginWithGoogle() async {
    ShowToastDialog.showLoader("please wait...".tr);
    await signInWithGoogle().then((googleUser) async {
      ShowToastDialog.closeLoader();
      if (googleUser != null) {
        Map<String, String> bodyParams = {
          'user_cat': "driver",
          'email': googleUser.user!.email.toString(),
          'login_type': "google",
        };
        await phoneNumberIsExit(bodyParams).then((value) async {
          if (value == true) {
            Map<String, String> bodyParams = {
              'email': googleUser.user!.email.toString(),
              'user_cat': "driver",
              'login_type': "google",
            };
            await getDataByPhoneNumber(bodyParams).then((value) {
              if (value != null) {
                if (value.success == "success") {
                  ShowToastDialog.closeLoader();

                  Preferences.setInt(Preferences.userId, int.parse(value.userData!.id.toString()));
                  Preferences.setString(Preferences.user, jsonEncode(value));
                  Preferences.setString(Preferences.accesstoken, value.userData!.accesstoken.toString());
                  API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
                  Preferences.setBoolean(Preferences.isLogin, true);

                  bool isPlanExpire = false;
                  if (value.userData!.subscriptionPlan?.id != null) {
                    if (value.userData!.subscriptionExpiryDate == null) {
                      if (value.userData!.subscriptionPlan?.expiryDay == '-1') {
                        isPlanExpire = false;
                      } else {
                        isPlanExpire = true;
                      }
                    } else {
                      DateTime expiryDate = DateTime.parse(value.userData!.subscriptionExpiryDate!);
                      isPlanExpire = expiryDate.isBefore(DateTime.now());
                    }
                  } else {
                    isPlanExpire = true;
                  }
                  if (value.userData!.subscriptionPlanId == null || isPlanExpire == true) {
                    Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                  } else {
                    Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                  }
                } else {
                  ShowToastDialog.showToast(value.error);
                }
              }
            });
          } else if (value == false) {
            ShowToastDialog.closeLoader();
            Get.off(PhoneEntryScreen(mode: 'signup'), arguments: {
              'email': googleUser.user!.email,
              'firstName': googleUser.user!.displayName,
              'login_type': "google",
            });
          }
        });
      }
    });
  }

  Future<void> loginWithApple() async {
    ShowToastDialog.showLoader("please wait...".tr);
    await signInWithApple().then((value) async {
      ShowToastDialog.closeLoader();
      if (value != null) {
        Map<String, dynamic> map = value;
        AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
        UserCredential userCredential = map['userCredential'];
        Map<String, String> bodyParams = {
          'user_cat': "driver",
          'email': userCredential.user!.email.toString(),
          'login_type': "apple",
        };
        await phoneNumberIsExit(bodyParams).then((value) async {
          if (value == true) {
            Map<String, String> bodyParams = {
              'email': userCredential.user!.email.toString(),
              'user_cat': "driver",
              'login_type': "apple",
            };
            await getDataByPhoneNumber(bodyParams).then((value) {
              if (value != null) {
                if (value.success == "success") {
                  ShowToastDialog.closeLoader();

                  Preferences.setInt(Preferences.userId, int.parse(value.userData!.id.toString()));
                  Preferences.setString(Preferences.user, jsonEncode(value));
                  Preferences.setString(Preferences.accesstoken, value.userData!.accesstoken.toString());
                  API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
                  Preferences.setBoolean(Preferences.isLogin, true);
                  bool isPlanExpire = false;
                  if (value.userData!.subscriptionPlan?.id != null) {
                    if (value.userData!.subscriptionExpiryDate == null) {
                      if (value.userData!.subscriptionPlan?.expiryDay == '-1') {
                        isPlanExpire = false;
                      } else {
                        isPlanExpire = true;
                      }
                    } else {
                      DateTime expiryDate = DateTime.parse(value.userData!.subscriptionExpiryDate!);
                      isPlanExpire = expiryDate.isBefore(DateTime.now());
                    }
                  } else {
                    isPlanExpire = true;
                  }
                  if (value.userData!.subscriptionPlanId == null || isPlanExpire == true) {
                    Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                  } else {
                    Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                  }
                } else {
                  ShowToastDialog.showToast(value.error);
                }
              }
            });
          } else if (value == false) {
            ShowToastDialog.closeLoader();
            Get.off(PhoneEntryScreen(mode: 'signup'), arguments: {
              'email': userCredential.user!.email,
              'firstName': appleCredential.givenName,
              'lastname': appleCredential.familyName,
              'login_type': "apple",
            });
          }
        });
      }
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Use the singleton instance
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Check if authentication is supported on this platform
      if (googleSignIn.supportsAuthenticate()) {
        // Use the new authenticate method
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate().catchError((error) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("something_went_wrong".tr);
          return null;
        });

        // Return null if user cancelled the sign-in
        if (googleUser == null) {
          return null;
        }

        // Request authorization for the scopes needed for Firebase
        final GoogleSignInClientAuthorization authorization =
        await googleUser.authorizationClient.authorizeScopes([
          'openid',
          'email',
          'profile'
        ]);

        if (authorization == null) {
          ShowToastDialog.showToast("Failed to get authorization");
          return null;
        }

        // For Firebase, we might need to get the ID token differently
        // Let's try using server authorization which should provide both tokens
        final GoogleSignInServerAuthorization? serverAuth =
        await googleUser.authorizationClient.authorizeServer([
          'openid',
          'email',
          'profile'
        ]);

        if (serverAuth == null) {
          ShowToastDialog.showToast("Failed to get server authorization");
          return null;
        }

        // Create credential using the authorization code (this might work for Firebase)
        final credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          // For ID token, we might need to extract it from serverAuth or use a different approach
        );

        // Alternative: Try using OAuthProvider directly
        final oauthCredential = OAuthProvider('google.com').credential(
          accessToken: authorization.accessToken,
        );

        // Once signed in, return the UserCredential
        return await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      } else {
        // Fallback for platforms that don't support authenticate()
        ShowToastDialog.showToast("Google Sign-In not supported on this platform");
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("something_went_wrong".tr);
    }
    return null;
  }

  // Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn().catchError((error) {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast("something_went_wrong".tr);
  //       return null;
  //     });
  //
  //     // Obtain the auth details from the request
  //     final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
  //
  //     // Create a new credential
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth?.accessToken,
  //       idToken: googleAuth?.idToken,
  //     );
  //
  //     // Once signed in, return the UserCredential
  //     return await FirebaseAuth.instance.signInWithCredential(credential);
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  //   return null;
  //   // Trigger the authentication flow
  // }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account.
      AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // webAuthenticationOptions: WebAuthenticationOptions(clientId: clientID, redirectUri: Uri.parse(redirectURL)),
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return {"appleCredential": appleCredential, "userCredential": userCredential};
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }
}
