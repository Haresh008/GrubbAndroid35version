import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_qr_bar_scanner/qr_bar_scanner_camera.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:mobile_scanner/mobile_scanner.dart' show Barcode, BarcodeCapture, MobileScanner, MobileScannerController;

import '../../model/mail_setting.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({Key? key}) : super(key: key);

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  String? _qrInfo = 'Scan a QR/Bar code'.tr();
  bool _camState = false, isMainCall = false;

  _scanCode() {
    setState(() {
      _camState = true;
    });
  }

  void initializeFlutterFire() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      final FlutterExceptionHandler? originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails errorDetails) async {
        await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
        originalOnError!(errorDetails);
        // Forward to original handler.
      };
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("globalSettings")
          .get()
          .then((dineinresult) {
            if (dineinresult.exists &&
                dineinresult.data() != null &&
                dineinresult.data()!.containsKey("website_color")) {
              COLOR_PRIMARY = int.parse(
                dineinresult.data()!["website_color"].replaceFirst("#", "0xff"),
              );
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("DineinForRestaurant")
          .get()
          .then((dineinresult) {
            if (dineinresult.exists) {
              isDineInEnable = dineinresult.data()!["isEnabledForCustomer"];
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("emailSetting")
          .get()
          .then((value) {
            if (value.exists) {
              mailSettings = MailSettings.fromJson(value.data()!);
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("home_page_theme")
          .get()
          .then((value) {
            if (value.exists) {
              homePageThem = value.data()!["theme"];
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("Version")
          .get()
          .then((value) {
            debugPrint(value.data().toString());
            appVersion = value.data()!['app_version'].toString();
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("googleMapKey")
          .get()
          .then((value) {
            print(value.data());
            GOOGLE_API_KEY = value.data()!['key'].toString();
          });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _scanCode();
    initializeFlutterFire();
  }

  MobileScannerController cameraController = MobileScannerController();
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "QR Code Scanner".tr(),
            style: TextStyle(
              fontFamily: "Poppins",
              letterSpacing: 0.5,
              fontWeight: FontWeight.normal,
              color: isDarkMode(context) ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode(context) ? Colors.white : Colors.black,
              size: 40,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ), //isDarkMode(context) ? Color(COLOR_DARK) : null,
        body: Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          child:
              _camState
                  ? Center(
                    child:
                    SizedBox(
                      height: 1000,
                      width: 500,
                      child:
                      // QRBarScannerCamera(
                      //   onError:
                      //       (context, error) => Text(
                      //         error.toString(),
                      //         style: const TextStyle(color: Colors.red),
                      //       ),
                      //   qrCodeCallback: (code) {
                      //     // _qrCallback(code);
                      //     print("code ius $code");
                      //     if (code != null && code.isNotEmpty) {
                      //       Map codeVal = jsonDecode(code);
                      //       print(
                      //         "codeVal: $codeVal  ${allstoreList.isNotEmpty}",
                      //       );
                      //       if (allstoreList.isNotEmpty) {
                      //         for (VendorModel storeModel in allstoreList) {
                      //           print("store name ${storeModel.id}");
                      //           if (storeModel.id == codeVal["vendorid"]) {
                      //             isMainCall = true;
                      //             _camState = false;
                      //             setState(() {
                      //               Navigator.of(context).pop();
                      //               push(
                      //                 context,
                      //                 NewVendorProductsScreen(
                      //                   vendorModel: storeModel,
                      //                 ),
                      //               );
                      //             });
                      //           }
                      //         }
                      //       } else {
                      //         isMainCall = true;
                      //         _camState = false;
                      //         setState(() {});
                      //         showAlertDialog(
                      //           context,
                      //           "error".tr(),
                      //           "Store not available".tr(),
                      //           true,
                      //         );
                      //       }
                      //     } else {
                      //       isMainCall = true;
                      //       _camState = false;
                      //       setState(() {});
                      //       showAlertDialog(
                      //         context,
                      //         "error".tr(),
                      //         "Store not available".tr(),
                      //         true,
                      //       );
                      //     }
                      //   },
                      // ),
                      MobileScanner(
                        controller: cameraController,
                        onDetect: (BarcodeCapture capture) {
                          final List<Barcode> barcodes = capture.barcodes;

                          for (final barcode in barcodes) {
                            final String? code = barcode.rawValue;
                            if (code != null && code.isNotEmpty && !isMainCall) {
                              isMainCall = true;
                              _camState = false;
                              cameraController.stop();

                              Map codeVal;
                              try {
                                codeVal = jsonDecode(code);
                              } catch (e) {
                                showAlertDialog(
                                  context,
                                  "error".tr(),
                                  "Invalid QR Code".tr(),
                                  true,
                                );
                                return;
                              }

                              if (allstoreList.isNotEmpty) {
                                for (VendorModel storeModel in allstoreList) {
                                  if (storeModel.id == codeVal["vendorid"]) {
                                    Navigator.of(context).pop();
                                    push(
                                      context,
                                      NewVendorProductsScreen(vendorModel: storeModel),
                                    );
                                    return;
                                  }
                                }
                                showAlertDialog(
                                  context,
                                  "error".tr(),
                                  "Store not available".tr(),
                                  true,
                                );
                              } else {
                                showAlertDialog(
                                  context,
                                  "error".tr(),
                                  "Store not available".tr(),
                                  true,
                                );
                              }
                            }
                          }
                        },
                      ),

                    ),
                  )
                  : Center(child: Text(_qrInfo!)),
        ),
      ),
    );
  }
}
