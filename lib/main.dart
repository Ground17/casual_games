import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kartridersearch/detail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kartridersearch/point.dart';
import 'package:kartridersearch/ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kartridersearch/question.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:kartridersearch/key.dart';

import 'package:kartridersearch/purchase.dart';
/// import 'package:in_app_purchase/store_kit_wrappers.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Ads.initialize();
  /// InAppPurchaseConnection.enablePendingPurchases();
  runApp(MyApp());
}

const bool kAutoConsume = true;

const String _kConsumableId = 'pin_money';

const List<String> _kProductIds = <String>['ad_free', _kConsumableId];

class Get {
  final String accessId;
  final String name;
  final int level;

  Get({this.accessId, this.name, this.level});

  factory Get.fromJson(Map<String, dynamic> json) {
    return Get(
      accessId: json['accessId'],
      name: json['name'],
      level: json['level'] ?? 0
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: key,
      title: '카트라이더 전적 검색 17%',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[900],
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(title: '카트라이더 전적 검색 17%'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyHomePageState>().restartApp();
  }

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

void _unzip(String messages) async {
  final bytes2 = File('$messages/metadata.zip').readAsBytesSync();
  // Decode the Zip file
  final archive = ZipDecoder().decodeBytes(bytes2);
  // Extract the contents of the Zip archive to disk.
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$messages/out/' + filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('$messages/out/' + filename)..create(recursive: true);
    }
  }
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _formKey = new GlobalKey<FormState>();
  Key key = UniqueKey();
  String _email = "";
  bool _isLoading = false;
  String dir = "";

  Directory character;
  Directory kart;

  int characterRandom;
  int kartRandom;

  int current;
  int total;

  File recent;
  File file; // metadata.zip
  File revised; // counter.txt
  http.Response r; // last-modified 체크용
  List<dynamic> players;
  List<dynamic> test;

  /// final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  /// StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool showAd = false;
  bool availableMeta = false;

  bool owner = false; // 구매한 사람에게 주어지는 특전
  File purchase;

  List<String> matchIds;

  BannerAd bannerAd;

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  void initState() {
    /// 인앱 결재 구현
    AppTrackingTransparency.requestTrackingAuthorization();
    bannerAd = Ads.createBannerAd();
    // showAd = false;
    matchIds = <String>["", "", "", "", "", ""];

    showAd = true;

    /// temp code
    Ads.showBannerAd(bannerAd);

    /// temp code

    _purchasePending = true;
    current = 0;
    total = 1;

    /// 인앱 결재 구현
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
    _isLoading = false;
    _initFile();
    super.initState();
  }

  @override
  void dispose() {
    /// _subscription.cancel();
    Ads.hideBannerAd(bannerAd);
    super.dispose();
  }

//   Future<void> initStoreInfo() async {
//     final bool isAvailable = await _connection.isAvailable();
//     if (!isAvailable) {
//       setState(() {
//         _isAvailable = isAvailable;
//         _products = [];
//         _purchases = [];
//         _purchasePending = false;
//         showAd = true;
//       });
//       if (showAd) {
//         Ads.showBannerAd(bannerAd);
//       }
//       await alert("구매 정보 확인에 실패했습니다.");
//       return;
//     }
//
// //    if (Platform.isIOS) {
// //      var paymentWrapper = SKPaymentQueueWrapper();
// //      var transactions = await paymentWrapper.transactions();
// //      transactions.forEach((transaction) async {
// //        await paymentWrapper.finishTransaction(transaction);
// //      });
// //    }
//
//     ProductDetailsResponse productDetailResponse =
//         await _connection.queryProductDetails(_kProductIds.toSet());
//     if (productDetailResponse.error != null) {
//       setState(() {
//         _isAvailable = isAvailable;
//         _products = productDetailResponse.productDetails;
//         _purchases = [];
//         _purchasePending = false;
//         showAd = true;
//       });
//       if (showAd) {
//         Ads.showBannerAd(bannerAd);
//       }
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
//         showAd = true;
//       });
//       if (showAd) {
//         Ads.showBannerAd(bannerAd);
//       }
//       await alert("구매 정보 확인에 실패했습니다.");
//       return;
//     }
//
//     showAd = true;
//
//     // final QueryPurchaseDetailsResponse purchaseResponse =
//     //     await _connection.queryPastPurchases();
//     // if (purchaseResponse.error != null) {
//     //   await alert(purchaseResponse.error.toString());
//     // }
//     // final List<PurchaseDetails> verifiedPurchases = [];
//     // for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
//     //   if (await _verifyPurchase(purchase) &&
//     //       purchase.status == PurchaseStatus.purchased) {
//     //     verifiedPurchases.add(purchase);
//     //     setState(() {
//     //       showAd = false;
//     //       Ads.hideBannerAd(bannerAd);
//     //     });
//     //   }
//     //   if (Platform.isIOS || purchase.pendingCompletePurchase) {
//     //     _connection.completePurchase(purchase);
//     //     print("completed!");
//     //   }
//     // }
//     setState(() {
//       _isAvailable = isAvailable;
//       _products = productDetailResponse.productDetails;
//       _purchases = verifiedPurchases;
//       _purchasePending = false;
//     });
//     if (showAd) {
//       Ads.showBannerAd(bannerAd);
//     }
//   }

  Future<Get> nickname(String nickname) async {
    final response = await http.get(
      "https://api.nexon.co.kr/kart/v1.0/users/nickname/" + nickname,
      headers: {
        "content-type": "application/json",
        "accept": "application/json",
        "Authorization": getAuthorization(),
      },
    );

    return Get.fromJson(json.decode(response.body));
  }

  void _initFile() async {
    r = await http
        .head("https://static.api.nexon.co.kr/kart/latest/metadata.zip");
    dir = (await getApplicationDocumentsDirectory()).path;
    revised = File('$dir/counter.txt');
    file = File('$dir/metadata.zip');

    character = Directory('$dir/out/character');
    kart = Directory('$dir/out/kart');

    recent = File('$dir/recent.txt');

    purchase = File('$dir/purchase.txt');

    total = int.parse(r.headers['content-length']);

    if (!await recent.exists()) {
      players = [];
      recent.writeAsStringSync(jsonEncode(players));
    }

    if (await purchase.exists()) {
      setState(() {
        owner = true;
      });
    }

    players = jsonDecode(recent.readAsStringSync());

    if (!await revised.exists()) {
      /// 다운로드 중이니 잠시만 기다리라는 화면 추가
      setState(() {
        _isLoading = true;
      });
      checkMetaInit(
          "더 나은 어플리케이션 사용을 위해 메타데이터를 다운로드하겠습니다. 크기는 약 ${(total / 1048576).toStringAsFixed(2)}MB이며, "
          "다운로드하지 않을 시 어플을 이용할 수 없습니다.");
    } else if (r.headers['last-modified'] != await revised.readAsString()) {
      setState(() {
        availableMeta = true;
      });
    } else {
      setState(() {
        characterRandom = Random().nextInt(character.listSync().length);
        kartRandom = Random().nextInt(kart.listSync().length);
      });
      test = jsonDecode(File('$dir/out/gameType.json').readAsStringSync());
      for (int i = 0; i < test.length; i++) {
        switch (test[i]["name"].toString()) {
          case "아이템 개인전":
            matchIds[0] = test[i]["id"];
            break;
          case "아이템 팀전":
            matchIds[1] = test[i]["id"];
            break;
          case "스피드 개인전":
            matchIds[2] = test[i]["id"];
            break;
          case "스피드 팀전":
            matchIds[3] = test[i]["id"];
            break;
          case "클럽 아이템 팀전":
            matchIds[4] = test[i]["id"];
            break;
          case "클럽 스피드 팀전":
            matchIds[5] = test[i]["id"];
            break;
        }
      }
    }
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: true,
        decoration: new InputDecoration(
            hintText: '닉네임',
            icon: new Icon(
              Icons.account_box,
              color: Colors.blue[700],
            )),
        validator: (value) => value.isEmpty ? '닉네임을 입력해주세요.' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _submit() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
      child: ElevatedButton(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                MediaQuery.of(context).platformBrightness == Brightness.dark
                    ? Colors.blue[900]
                    : Colors.blue[700])),
        onPressed: _validateAndSubmit,
        child: new Text('검색',
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
      ),
    );
  }

  void _validateAndSubmit() async {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      await nickname(_email).then((get) async {
        if (get.name != null) {
          for (int i = 0; i < players.length; i++) {
            if (players[i][0] == get.accessId) {
              players.remove(players[i]);
            }
          }
          players.insert(0, [get.accessId, get.name]);
          if (players.length > 10) {
            players.removeRange(10, players.length);
          }
          recent.writeAsStringSync(jsonEncode(players));
          if (showAd) {
            Ads.showBannerAd(bannerAd);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DetailApp(
                      id: get.accessId,
                      nickname: get.name,
                      level: get.level.toString(),
                      showAd: showAd,
                      matchIds: matchIds,
                    )),
          );

          /// 인앱 결제 구현
//          if (!_purchasePending) {
//            Navigator.push(
//              context,
//              MaterialPageRoute(builder: (context) => DetailApp(id: get.accessId, nickname: get.name, showAd: showAd, matchIds: matchIds,)),
//            );
//          }
        } else {
          alert("라이더 정보가 없습니다. 닉네임을 다시 확인해주세요.");
        }
      }).catchError((e) {
        alert("아이디나 비밀번호를 다시 확인해주세요.");
      });
    }
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  "서버에서 새 메타데이터를 다운로드 받는 중입니다. 이 과정은 서버의 메타데이터가 업데이트 있을 시에 시행되며, 몇 분 정도 소요될 수 있습니다. "
                  "더 나은 어플 사용을 위해 반드시 필요한 작업이므로 양해 부탁드립니다.\n"
                  "다운로드가 너무 오래 걸리는 경우엔 네트워크 환경이 안정적인지 확인해주신 후, 어플을 재부팅해주시면 감사하겠습니다.\n"
                  "(기존에 다운받은 메타데이터는 삭제됩니다)\n"),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(current / total > 0.99
                  ? "압축 해제 중..."
                  : "${(current / 1048576).toStringAsFixed(2)}MB / ${(total / 1048576).toStringAsFixed(2)}MB (${current * 100 ~/ total}%)"),
            ),
            mailDeveloper(),
            Divider(),
            explanation(),
          ]);
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget mailDeveloper() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("버그 발생 시 문의 메일 주소"),
        TextButton(
          child: Text('ground171717@gmail.com (클릭 시 메일주소 복사)'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: "ground171717@gmail.com"));
          },
        ),
      ],
    );
  }

  Widget explanation() {
    return TextButton(
      child: Text('잘 되던 어플이 안 되는 유력한 이유 (영상)'),
      onPressed: () async {
        const url = 'https://www.youtube.com/watch?v=_xQmV0X9X_g';
        if (await canLaunch(url)) {
        await launch(url);
        }
      },
    );
  }

  Future<Widget> loadImage() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    if (character != null &&
        kart != null &&
        await character.exists() &&
        await kart.exists()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.file(
            File(character.listSync().elementAt(characterRandom ?? 0).path),
            scale: 4,
          ),
          Image.file(
            File(kart.listSync().elementAt(kartRandom ?? 0).path),
            scale: 5,
          ),
        ],
      );
    }
    return new Container(width: 0.0, height: 0.0);
  }

  Widget _image() {
    return FutureBuilder(
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        return snapshot.data;
      },
      future: loadImage(),
      initialData: Container(width: 0.0, height: 0.0),
    );
  }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
//      decoration: BoxDecoration(
//        backgroundBlendMode: BlendMode.softLight,
//        color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.black12 : Colors.white,
//      ),
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            owner
                ? Row(
                    children: <Widget>[
                      Icon(
                        Icons.stars,
                        color: Colors.amberAccent,
                      ),
                      !showAd
                          ? Icon(
                              Icons.not_interested,
                              color: Colors.red,
                            )
                          : Container(),
                    ],
                  )
                : Container(),
            availableMeta
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                        Text("메타데이터 업데이트"),
                        IconButton(
                          onPressed: () async {
                            checkMetaInit(
                                "메타데이터 업데이트가 있습니다. 크기는 약 ${(total / 1048576).toStringAsFixed(2)}MB입니다.",
                                option: true);
                          },
                          icon: Icon(
                            Icons.download,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.blue[900]
                                : Colors.blue[700],
                          ),
                        )
                      ])
                : Container(),
            _showEmailInput(),
            _submit(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: "개인정보처리방침",
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                'https://ground171717.blogspot.com/2021/10/privacy.html';
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          }),
                  ),
                ),
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: "도움말",
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => QuestionApp()),
                            );
                          }),
                  ),
                )
              ],
            ),
            Divider(),
            _image(),
            Text(
              "\nData based on NEXON DEVELOPERS\n\n"
              "이 어플은 NEXON 공식이 아닌 제3자가 개발/배포한 어플입니다.",
              textAlign: TextAlign.center,
            ),
            Divider(),
            mailDeveloper(),
            Divider(),
            explanation(),
            Divider(),
            Container(
              alignment: Alignment.center,
              child: AdWidget(ad: bannerAd),
              width: bannerAd.size.width.toDouble(),
              height: bannerAd.size.height.toDouble(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: key,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(widget.title),
          actions: <Widget>[
            /// 인앱 결제 구현
//          !_isLoading ? IconButton(
//            icon: Icon(Icons.payment, color: Colors.white,),
//            tooltip: "상품 구매",
//            onPressed: () async {
//              /// 인앱 결재 구현
////              if (showAd) {
////                Ads.showBannerAd();
////              }
////              if (!_purchasePending) {
////                Navigator.push(
////                  context,
////                  MaterialPageRoute(builder: (context) => PurchaseApp(/*context: this.context,*/)),
////                );
////              }
//            },
//          ) : Container(),
            !_isLoading
                ? IconButton(
                    icon: Icon(
                      Icons.recent_actors,
                      color: Colors.white,
                    ),
                    tooltip: "최근 검색 라이더",
                    onPressed: () async {
                      setState(() {
                        players = jsonDecode(recent.readAsStringSync());
                      });
                      await showRecent();
                    },
                  )
                : Container(),
            !_isLoading
                ? IconButton(
                    icon: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                    tooltip: "점수 계산",
                    onPressed: () async {
//              Ads.hideBannerAd(bannerAd);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PointApp(
                                  showAd: showAd,
                                )),
                      );

                      /// 인앱 결제 구현
//              if (!_purchasePending) {
//                Navigator.push(
//                  context,
//                  MaterialPageRoute(builder: (context) => PointApp(showAd: showAd,)),
//                );
//              }
                    },
                  )
                : Container(),
          ],
        ),
        body:
            _isLoading ? Center(child: _showCircularProgress()) : _showBody());
  }

  Future<void> showRecent() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (_context, setState) {
            return AlertDialog(
              title: Text("최근 검색 라이더"),
              actions: <Widget>[
                TextButton(
                  child: Text('닫기'),
                  onPressed: () {
                    Navigator.of(_context).pop();
                  },
                ),
              ],
              content: Container(
                width: MediaQuery.of(_context).size.width * 0.9,
                height: MediaQuery.of(_context).size.height * 0.3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: players.length,
                        itemBuilder: (BuildContext _context2, int i) {
                          return _buildRow(players[i], _context, setState);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(List<dynamic> cells, _context, _setState) {
    return ListTile(
      dense: true,
      title: Text(cells[1].toString()),
      trailing: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _setState(() {
              players.remove(cells);
              recent.writeAsStringSync(jsonEncode(players));
            });
          }),
      onTap: () async {
        await getAccessId(cells[0].toString()).then((get) async {
          if (get.name != null) {
            for (int i = 0; i < players.length; i++) {
              if (players[i][0] == get.accessId) {
                players.remove(players[i]);
              }
            }
            players.insert(0, [get.accessId, get.name]);
            if (players.length > 10) {
              players.removeRange(10, players.length);
            }
            recent.writeAsStringSync(jsonEncode(players));
            Navigator.of(_context).pop();
            if (showAd) {
              Ads.showBannerAd(bannerAd);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailApp(
                        id: cells[0].toString(),
                        nickname: get.name,
                        level: get.level.toString(),
                        showAd: showAd,
                        matchIds: matchIds,
                      )),
            );

            /// 인앱 결제 구현
//            if (!_purchasePending) {
//              Navigator.push(
//                context,
//                MaterialPageRoute(builder: (context) => DetailApp(id: cells[0].toString(), nickname: get.name, showAd: showAd, matchIds: matchIds,)),
//              );
//            }
          }
        });
      },
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

  void downloadMeta() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Directory('$dir/out').delete(recursive: true);
    } catch (e) {
      print(e);
    } finally {
      HttpClient _client = new HttpClient();
      await _client
          .getUrl(Uri.parse(
              "https://static.api.nexon.co.kr/kart/latest/metadata.zip"))
          .then((HttpClientRequest request) {
        return request.close();
      }).then((HttpClientResponse response) async {
        current = 0;
        if (await file.exists()) {
          await file.delete(recursive: true);
        }
        response.listen((d) {
          file.writeAsBytesSync(d, mode: FileMode.append);
          setState(() {
            current += d.length;
          });
        }, onDone: () async {
          await compute(_unzip, dir).then((value) async {
            try {
              await file.delete(recursive: true);
            } finally {
              character = Directory('$dir/out/character');
              kart = Directory('$dir/out/kart');
              setState(() {
                _isLoading = false;
                availableMeta = false;
                characterRandom = Random().nextInt(character.listSync().length);
                kartRandom = Random().nextInt(kart.listSync().length);
                revised.writeAsStringSync(r.headers['last-modified']);
              });
              test =
                  jsonDecode(File('$dir/out/gameType.json').readAsStringSync());
              for (int i = 0; i < test.length; i++) {
                switch (test[i]["name"].toString()) {
                  case "아이템 개인전":
                    matchIds[0] = test[i]["id"];
                    break;
                  case "아이템 팀전":
                    matchIds[1] = test[i]["id"];
                    break;
                  case "스피드 개인전":
                    matchIds[2] = test[i]["id"];
                    break;
                  case "스피드 팀전":
                    matchIds[3] = test[i]["id"];
                    break;
                  case "클럽 아이템 팀전":
                    matchIds[4] = test[i]["id"];
                    break;
                  case "클럽 스피드 팀전":
                    matchIds[5] = test[i]["id"];
                    break;
                }
              }
            }
          });
        }, onError: (e) async {
          print(e);
        });
      });
    }
  }

  Future<void> checkMetaInit(String message, {bool option = false}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: option, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            option
                ? TextButton(
                    child: Text('취소'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                : Container(),
            TextButton(
              child: Text('다운로드'),
              onPressed: () {
                Navigator.of(context).pop();
                downloadMeta();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Get> getAccessId(String aceess_id) async {
    final response = await http.get(
      "https://api.nexon.co.kr/kart/v1.0/users/" + aceess_id,
      headers: {
        "content-type": "application/json",
        "accept": "application/json",
        "Authorization": getAuthorization(),
      },
    );

    return Get.fromJson(json.decode(response.body));
  }

//   Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
//     // IMPORTANT!! Always verify a purchase before delivering the product.
//     // For the purpose of an example, we directly return true.
//     if (purchaseDetails != null &&
//         purchaseDetails.productID == _kProductIds[0]) {
//       return Future<bool>.value(true);
//     }
//
//     return Future<bool>.value(false);
//   }
//
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
//             await _connection.consumePurchase(purchaseDetails);
//           }
//         }
//         if (Platform.isIOS || purchaseDetails.pendingCompletePurchase) {
//           await _connection.completePurchase(purchaseDetails);
//
//           Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
// //          await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(title: '카트라이더 전적 검색 17%')));
// //          Navigator.of(context).pop();
//         }
//         setState(() {
//           _purchasePending = false;
//         });
//       }
//     });
//   }
}
