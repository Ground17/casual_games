import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
/// import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:kartridersearch/ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kartridersearch/main.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

const bool kAutoConsume = true;

const String _kConsumableId = 'pin_money';

const List<String> _kProductIds = <String>[
  'ad_free',
  _kConsumableId
];

class PurchaseApp extends StatefulWidget {
  PurchaseApp({Key key, /*this.context*/}) : super(key: key);

//  final BuildContext context;
  @override
  _MyHomePageStates createState() => _MyHomePageStates(/*buildContext: context*/);
}

class _MyHomePageStates extends State<PurchaseApp> {
//  _MyHomePageStates({this.buildContext});
//  BuildContext buildContext;
//  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
//  StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = true;
  bool _loading = false;
  String dir = "";
  // bool showAd = true;

  @override
  void initState() {
//    showAd = true;
//    Stream purchaseUpdated =
//        _connection.purchaseUpdatedStream;
//    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
//      _listenToPurchaseUpdated(purchaseDetailsList);
//    }, onDone: () {
//      _subscription.cancel();
//    }, onError: (error) {
//      alert(error.toString());
//    });
//    initStoreInfo();
    super.initState();
  }

  @override
  void dispose() {
//    _subscription.cancel();
    super.dispose();
  }

//   Future<void> initStoreInfo() async {
//     dir = (await getApplicationDocumentsDirectory()).path;
//     setState(() {
//       _loading = true;
//     });
//
// //    if (Platform.isIOS) {
// //      var paymentWrapper = SKPaymentQueueWrapper();
// //      var transactions = await paymentWrapper.transactions();
// //      transactions.forEach((transaction) async {
// //        await paymentWrapper.finishTransaction(transaction);
// //      });
// //    }
//
//     final bool isAvailable = await _connection.isAvailable();
//     if (!isAvailable) {
//       setState(() {
//         _isAvailable = isAvailable;
//         _products = [];
//         _purchases = [];
//         _purchasePending = false;
//         _loading = false;
//       });
//       await alert("구매 정보 확인에 실패했습니다.");
//       return;
//     }
//
//     ProductDetailsResponse productDetailResponse =
//     await _connection.queryProductDetails(_kProductIds.toSet());
//     if (productDetailResponse.error != null) {
//       setState(() {
//         _isAvailable = isAvailable;
//         _products = productDetailResponse.productDetails;
//         _purchases = [];
//         _purchasePending = false;
//         _loading = false;
//       });
//       await alert(productDetailResponse.error.toString());
//       return;
//     }
//
//     if (productDetailResponse.productDetails.isEmpty) {
//       setState(() {
//         _isAvailable = isAvailable;
//         _products = productDetailResponse.productDetails;
//         _purchases = [];
//         _purchasePending = false;
//         _loading = false;
//       });
//       await alert("구매 정보 확인에 실패했습니다.");
//       return;
//     }
//
//     final QueryPurchaseDetailsResponse purchaseResponse =
//     await _connection.queryPastPurchases();
//     if (purchaseResponse.error != null) {
//       await alert(purchaseResponse.error.toString());
//     }
//     final List<PurchaseDetails> verifiedPurchases = [];
//     for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
// //      if (await _verifyPurchase(purchase) && purchase.status == PurchaseStatus.purchased) {
//         verifiedPurchases.add(purchase);
// //        setState(() {
// //          showAd = false;
// //        });
// //      }
//       if (Platform.isIOS || purchase.pendingCompletePurchase) {
//         _connection.completePurchase(purchase);
//         print("completed! (Purchased)");
//       }
//     }
//     setState(() {
//       _isAvailable = isAvailable;
//       _products = productDetailResponse.productDetails;
//       _purchases = verifiedPurchases;
//       _purchasePending = false;
//       _loading = false;
//     });
//   }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        backgroundBlendMode: BlendMode.softLight,
        color: Colors.white,
      ),
      child: new ListView(
        shrinkWrap: true,
        children: <Widget>[
          if (_loading)
            ...[
              Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
              ),
              Text('스토어와 통신하는 중입니다...'),
            ]
          ,
          for (var prod in _products)
          // UI if already purchased
            if (_hasPurchased(prod.id) == null)
              ...[
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                        child: ElevatedButton(
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.blue[900] : Colors.blue[700])),
                          onPressed: () => _buyProduct(prod),
                          child: new Text('${prod.title} (${prod.price})',
                              style: new TextStyle(fontSize: 20.0, color: Colors.white)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                        child: Text(prod.description),
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent
                  ),
                ),
              ]
          ,
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
            child: Text("※ 단순 변심의 경우 환불이 어렵기 때문에 신중히 구매해주시기 바랍니다. ※", textAlign: TextAlign.center,),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("상품 구매"),
      ),
      body: Center(
        child: _showBody(),
      ),
    );
  }

  Future<void> alert(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _buyProduct(ProductDetails prod) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    bool success = false;
    try {
      // if (prod.id == _kProductIds[0]) {
      //   success = await _connection.buyNonConsumable(purchaseParam: purchaseParam);
      // } else {
      //   success = await _connection.buyConsumable(purchaseParam: purchaseParam, autoConsume: kAutoConsume);
      // }
    } catch (e) {
      print(e);
    } finally {
      if (success) {
        var purchase = File('$dir/purchase.txt');
        if (!await purchase.exists()) {
          purchase.writeAsStringSync("구매해주셔서 감사합니다!");
        }
      }
    }

  }

  PurchaseDetails _hasPurchased(String productID) {
    print(productID);
    print(_purchases);
    return _purchases.firstWhere( (purchase) => purchase.productID == productID, orElse: () => null);
  }

//   void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
//     purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//       if (purchaseDetails.status == PurchaseStatus.pending) {
//         setState(() {
//           _purchasePending = true;
//         });
//       } else {
//         if (purchaseDetails.status == PurchaseStatus.error) {
//           alert(purchaseDetails.error.toString());
//         } else if (purchaseDetails.status == PurchaseStatus.purchased) {
// //          bool valid = await _verifyPurchase(purchaseDetails);
// //          if (valid) {
// //            setState(() {
// //              // showAd = false;
// //            });
// //          } else {
// //            return;
// //          }
//         }
//         if (Platform.isAndroid) {
//           if (!kAutoConsume && purchaseDetails.productID == _kConsumableId) {
//             await _connection
//                 .consumePurchase(purchaseDetails);
//           }
//         }
//         if (Platform.isIOS || purchaseDetails.pendingCompletePurchase) {
//           await _connection
//               .completePurchase(purchaseDetails);
//
//           Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
// //          await Navigator.pushReplacement(buildContext, MaterialPageRoute(builder: (context) => MyHomePage(title: '카트라이더 전적 검색 17%')));
// //          Navigator.of(context).pop();
//         }
//         setState(() {
//           _purchasePending = false;
//         });
//       }
//     });
//   }
}