import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:kartridersearch/chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:kartridersearch/main.dart';
import 'package:flutter/foundation.dart';
import 'package:kartridersearch/ads.dart';
import 'package:kartridersearch/point.dart';
import 'package:kartridersearch/key.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class User {
  final List<dynamic> matches;

  User({this.matches});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      matches: json['matches'],
    );
  }
}

class Match {
  final Map<String, dynamic> match;

  Match({this.match});

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      match: json,
    );
  }
}

class Cells {
  String accountNo;
  String pet;
  String flyingPet;
  String matchId; // kart
  String trackId; // character
  String trackName; // characterName == nickname
  bool clicked = false;
  DateTime startTime;
  DateTime endTime;
  int matchTime;
  int playerCount; // rankinggrade2
  int rank;
  int win;
  Cells(
      {this.matchId,
      this.trackId,
      this.clicked,
      this.startTime,
      this.endTime,
      this.matchTime,
      this.playerCount,
      this.rank,
      this.trackName,
      this.accountNo,
      this.win,
      this.pet,
      this.flyingPet});
}

class DetailApp extends StatefulWidget {
  DetailApp(
      {Key key, this.id, this.nickname, this.level = "0", this.showAd = true, this.matchIds})
      : super(key: key);

  String id;
  String nickname;
  String level;

  bool showAd;

  List<String> matchIds;

  @override
  _MyChangeState createState() => new _MyChangeState(
      id: id, nickname: nickname, level: level, showAd: showAd, matchIds: matchIds);
}

class _MyChangeState extends State<DetailApp>
    with SingleTickerProviderStateMixin {
  _MyChangeState(
      {String id, String nickname, String level = "0", bool showAd = true, List<String> matchIds}) {
    this.id = id;
    this.nickname = nickname;
    this.showAd = showAd;
    this.matchIds = matchIds;
    this.level = level;
  }

  String dir;

  String id;
  String nickname;
  String level;
  String licence = "0";

  bool loading = true;

  bool speed = true;
  int index = 1;

  List<dynamic> test;
  List<dynamic> track;
  List<dynamic> pets;
  List<dynamic> flyingPets;
  List<dynamic> karts;
  List<dynamic> characters;

  DateTime now = DateTime.now();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  bool isNow = true;

  List<String> matchIds;

  String dropdownValue = '팀전';
  List<String> dropdownValues = ["개인전", "팀전", "클럽전"];

//  TabController _tabController;
//  List<ScrollController> controllers = [ScrollController(), ScrollController(), ScrollController()];

  String exMatchIds;

  List<Cells> cells = [];
//  List<int> cellsLengthSet = [0, 0, 0];
  int win = 0;
  int unRetire = 0;

  File recent;
  List<dynamic> players;

  bool showAd;

  BannerAd bannerAd;

  void _init() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    test = jsonDecode(File('$dir/out/gameType.json').readAsStringSync());
    _user(id, limit: 1).then((onValue) async {
      track = jsonDecode(File('$dir/out/track.json').readAsStringSync());
      pets = jsonDecode(File('$dir/out/pet.json').readAsStringSync());
      flyingPets =
          jsonDecode(File('$dir/out/flyingPet.json').readAsStringSync());
      karts = jsonDecode(File('$dir/out/kart.json').readAsStringSync());
      characters =
          jsonDecode(File('$dir/out/character.json').readAsStringSync());
      recent = File('$dir/recent.txt');
      players = jsonDecode(recent.readAsStringSync());
      test = jsonDecode(File('$dir/out/gameType.json').readAsStringSync());

      if (onValue.matches.length < 1 || !onValue.matches[0].containsKey("matchType") || !onValue.matches[0].containsKey("matches")) {
        index = 1;
        speed = true;
      } else {
        if (onValue.matches[0]["matches"].length > 0 && onValue.matches[0]["matches"][0].containsKey("player")) {
          licence = onValue.matches[0]["matches"][0]["player"]["rankinggrade2"];
        }
        for (int i = 0; i < test.length; i++) {
          if (test[i]["id"] == onValue.matches[0]["matchType"]) {
            switch (test[i]["name"].toString()) {
              case "아이템 개인전":
                index = 0;
                speed = false;
                break;
              case "아이템 팀전":
                index = 1;
                speed = false;
                break;
              case "스피드 개인전":
                index = 0;
                speed = true;
                break;
              case "스피드 팀전":
                index = 1;
                speed = true;
                break;
              case "클럽 아이템 팀전":
                index = 2;
                speed = false;
                break;
              case "클럽 스피드 팀전":
                index = 2;
                speed = true;
                break;
              default:
                index = 1;
                speed = true;
                break;
            }
            break;
          }
        }
      }

      setState(() {
        /// 데이터 바뀌는 곳
        dropdownValue = dropdownValues[index];
//        _tabController.index = index;
      });
      await update();
    });
  }

  @override
  void initState() {
    bannerAd = Ads.createBannerAd();

    if (showAd) {
      Ads.showBannerAd(bannerAd);
    }

    exMatchIds = "";
    now = DateTime.now();
//    _tabController = TabController(vsync: this, length: 3)..addListener(_handleTabSelection);
    _init();
    super.initState();
  }

  @override
  void dispose() {
//    controller.removeListener(_scrollListener);
    super.dispose();
  }

  void _handleTabSelection() async {
    /// 데이터 바뀌는 곳
    await update();
//    index = _tabController.index;
  }

//  void _scrollListener0() {
//    if (controllers[0].position.pixels >= controllers[0].position.maxScrollExtent - MediaQuery.of(context).size.height * 0.2) {
//      if (cellsSet[0].length - cellsLengthSet[0] > 20) {
//        setState(() {
//          cellsLengthSet[0] += 20;
//        });
//      } else {
//        setState(() {
//          cellsLengthSet[0] = cellsSet[0].length;
//        });
//      }
//    }
//  }
//  void _scrollListener1() {
//    if (controllers[1].position.pixels >= controllers[1].position.maxScrollExtent - MediaQuery.of(context).size.height * 0.2) {
//      if (cellsSet[1].length - cellsLengthSet[1] > 20) {
//        setState(() {
//          cellsLengthSet[1] += 20;
//        });
//      } else {
//        setState(() {
//          cellsLengthSet[1] = cellsSet[1].length;
//        });
//      }
//    }
//  }
//  void _scrollListener2() {
//    if (controllers[2].position.pixels >= controllers[2].position.maxScrollExtent - MediaQuery.of(context).size.height * 0.2) {
//      if (cellsSet[2].length - cellsLengthSet[2] > 20) {
//        setState(() {
//          cellsLengthSet[2] += 20;
//        });
//      } else {
//        setState(() {
//          cellsLengthSet[2] = cellsSet[2].length;
//        });
//      }
//    }
//  }

  Future<User> _user(String access_id,
      {String start_date = "",
      String end_date = "",
      int offset = 0,
      int limit = 10,
      String match_types = ""}) async {
    final response = await http.get(
      "https://api.nexon.co.kr/kart/v1.0/users/$access_id/matches?start_date=$start_date&end_date=$end_date&offset=$offset&limit=$limit&match_types=$match_types",
      headers: {
        "content-type": "application/json",
        "accept": "application/json",
        "Authorization": getAuthorization(),
      },
    );

    return User.fromJson(json.decode(response.body));
  }

  Future<void> update() async {
    setState(() {
      loading = true;
      cells = [];
      win = 0;
      unRetire = 0;
    });
    String trackName = "";
    var shortcut;
    var data;
    switch (index) {
      case 0:
        try {
          data = await _user(id,
              limit: 200, match_types: speed ? matchIds[2] : matchIds[0]);
        } catch (e) {
          print(e);
          data = null;
        }
        break;
      case 1:
        try {
          data = await _user(id,
              limit: 200, match_types: speed ? matchIds[3] : matchIds[1]);
        } catch (e) {
          print(e);
          data = null;
        }
        break;
      default:
        try {
          data = await _user(id,
              limit: 200, match_types: speed ? matchIds[5] : matchIds[4]);
        } catch (e) {
          print(e);
          data = null;
        }
        break;
    }

    if (data != null && data.matches != null && data.matches.length > 0) {
      shortcut = data.matches[0]["matches"];
      for (int i = 0; i < shortcut.length; i++) {
        trackName = "알 수 없는 트랙";
        if (track == null) break;
        for (int j = 0; j < track.length; j++) {
          if (shortcut[i]["trackId"] == "") {
            break;
          } else if (track[j]["id"] == shortcut[i]["trackId"]) {
            trackName = track[j]["name"];
            break;
          }
        }
        cells.add(Cells(
          clicked: false,
          matchId: shortcut[i]["matchId"],
          trackId: shortcut[i]["trackId"],
          trackName: trackName,
          startTime: DateFormat('yyyy-MM-dd HH:mm:ss')
              .parse(shortcut[i]["startTime"].toString().replaceFirst("T", " "))
              .add(Duration(hours: 9)),
          endTime: DateFormat('yyyy-MM-dd HH:mm:ss')
              .parse(shortcut[i]["endTime"].toString().replaceFirst("T", " "))
              .add(Duration(hours: 9)),
          matchTime: shortcut[i]["player"]["matchTime"] != ""
              ? int.parse(shortcut[i]["player"]["matchTime"])
              : 0,
          playerCount: shortcut[i]["playerCount"],
          rank: shortcut[i]["player"]["matchRank"] != "" && shortcut[i]["player"]["matchRank"] != "0"
              ? int.parse(shortcut[i]["player"]["matchRank"])
              : 99,
        ));
        if (shortcut[i]["player"]["matchWin"] != "0") {
          win++;
        }
        if (shortcut[i]["player"]["matchTime"] != "") {
          unRetire++;
        }
      }
    }

    setState(() {
      now = DateTime.now();
      loading = false;
    });
    return null;
  }

  Future<Match> _match(String match_id) async {
    final response = await http.get(
      "https://api.nexon.co.kr/kart/v1.0/matches/$match_id",
      headers: {
        "content-type": "application/json",
        "accept": "application/json",
        "Authorization": getAuthorization(),
      },
    );

    return Match.fromJson(json.decode(response.body));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          leading: new IconButton(
            icon: new Icon(
                Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            nickname,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: <Widget>[
            Row(
              children: <Widget>[
                speed
                    ? IconButton(
                        icon: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        tooltip: "점수 계산",
                        onPressed: () async {
                          await showPoint();
                        },
                      )
                    : Container(),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  tooltip: "새로고침",
                  onPressed: () async {
                    await update();
                  },
                )
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Lv." + level, style: TextStyle(color: Colors.white),),
                Row(
                  children: [
                    Text(
                      speed ? "스피드" : "아이템",
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: speed,
                      onChanged: (value) async {
                        setState(() {
                          speed = value;
                        });
                        await update();
                      },
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: dropdownValue,
                  icon: new Icon(
                    Platform.isAndroid
                        ? Icons.arrow_downward
                        : CupertinoIcons.down_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 24,
                  elevation: 16,
                  onChanged: (String newValue) async {
                    setState(() {
                      dropdownValue = newValue;
                      index = dropdownValues.indexOf(newValue);
                    });
                    await update();
                  },
                  items: <String>['개인전', '팀전', '클럽전']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                licence != "6"
                    ? Text(
                  licence == "1"
                      ? "초보"
                      : (licence == "2"
                      ? "루키"
                      : (licence == "3"
                      ? "L3"
                      : (licence == "4"
                      ? "L2"
                      : (licence == "5"
                      ? "L1"
                      : (" "))))),
                  style: TextStyle(
                    color: licence == "3"
                        ? Colors.blue
                        : (licence == "4"
                        ? Colors.red
                        : (licence == "5"
                        ? Colors.deepPurple
                        : Colors.white)),
                    backgroundColor: licence == "3" || licence == "4" || licence == "5"
                        ? Colors.white
                        : (licence == "1"
                        ? Colors.amber[700]
                        : (licence == "2"
                        ? Colors.green
                        : null)),
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : ShaderMask(
                  shaderCallback: (bounds) => RadialGradient(
                    colors: <Color>[
                      Colors.red,
                      Colors.deepOrange,
                      Colors.orange,
                      Colors.amber,
                      Colors.yellow,
                      Colors.lime,
                      Colors.lightGreen,
                      Colors.green,
                      Colors.teal,
                      Colors.cyan,
                      Colors.lightBlue,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.deepPurple,
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    "Pro",
                    style: TextStyle(
                      // The color must be set to white for this to work
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            loading
                ? ListView(children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        '잠시만 기다려주세요...',
                        textAlign: TextAlign.center,
                      ),
                    )
                  ])
                : RefreshIndicator(
                    child: ListView(
                      children: cells.length > 0
                          ? <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              Text(
                                "최근 ${cells.length}경기 기준",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  CustomPaint(
                                    size: Size(100, 100),
                                    painter: PieChart(
                                        percentage:
                                            (100 * win / cells.length).round(),
                                        title: "승률"),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                  ),
                                  CustomPaint(
                                    size: Size(100, 100),
                                    painter: PieChart(
                                        percentage:
                                            (100 * unRetire / cells.length)
                                                .round(),
                                        title: "완주율"),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              ListView.builder(
                                  physics: ScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: cells.length + 1,
                                  itemBuilder: (BuildContext _context, int i) {
                                    if (i == cells.length) {
                                      return ListTile(
                                        isThreeLine: true,
                                        subtitle: Text(""),
                                      );
                                    }
                                    return _buildRow(cells[i]);
                                  })
                            ]
                          : <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                              ),
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  'Error: 정보가 없습니다.\n새로고침을 눌러 다시 시도해주세요.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                    ),
                    onRefresh: update,
                  ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).backgroundColor,
                ),
                alignment: Alignment.center,
                child: AdWidget(ad: bannerAd),
                width: double.infinity,
                height: bannerAd.size.height.toDouble(),
              ),
            ),
          ],
        ));
  }

  Widget _buildRow(Cells cells) {
    return ExpansionTile(
      /// alert()로 endTime을 알 수 있도록
      key: PageStorageKey<Cells>(cells),
      leading: Container(
        width: 65,
        child: Center(
          child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: now.difference(cells.endTime).inDays != 0
                      ? "${now.difference(cells.endTime).inDays}일 전"
                      : (now.difference(cells.endTime).inHours != 0
                          ? "${now.difference(cells.endTime).inHours}시간 전"
                          : (now.difference(cells.endTime).inMinutes != 0
                              ? "${now.difference(cells.endTime).inMinutes}분 전"
                              : "${now.difference(cells.endTime).inSeconds}초 전")),
                  style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      /// print(cells.matchId);
                      alertEndDate(cells.startTime, cells.endTime);
                    })),
        ),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(cells.trackName),
          ),
          Text(
            cells.matchTime != 0
                ? "${cells.matchTime ~/ 60000}:${((cells.matchTime ~/ 1000) % 60).toString().padLeft(2, "0")}:${(cells.matchTime % 1000).toString().padLeft(3, "0")}"
                : "-:--:---",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      trailing: Text(
        cells.rank > 8 || cells.rank < 1
            ? "리타/${cells.playerCount}"
            : "#${cells.rank}/${cells.playerCount}",
        style: TextStyle(
            color: cells.rank > 8 || cells.rank < 1 ? Colors.redAccent : Colors.blueAccent),
      ),
      children: <Widget>[
        Container(
          margin: EdgeInsets.symmetric(vertical: 5.0),
          height: 120.0,
          child: FutureBuilder<Match>(
            future: _match(cells.matchId),
            builder: (BuildContext context, AsyncSnapshot<Match> snapshot) {
              if (snapshot.hasData) {
                var shortcut = snapshot.data.match;
                List<Cells> rest = [];
                if (shortcut.containsKey("teams")) {
                  for (int i = 0; i < shortcut["teams"].length; i++) {
                    for (int j = 0;
                        j < shortcut["teams"][i]["players"].length;
                        j++) {
                      rest.add(Cells(
                          accountNo: shortcut["teams"][i]["players"][j]
                              ["accountNo"],
                          trackName: shortcut["teams"][i]["players"][j]
                              ["characterName"],
                          trackId: shortcut["teams"][i]["players"][j]
                              ["character"],
                          matchId: shortcut["teams"][i]["players"][j]["kart"],
                          playerCount:
                              shortcut["teams"][i]["players"][j]["rankinggrade2"] != ""
                                  ? int.parse(shortcut["teams"][i]["players"][j]
                                      ["rankinggrade2"])
                                  : 0,
                          rank: shortcut["teams"][i]["players"][j]["matchRank"] != "" && shortcut["teams"][i]["players"][j]["matchRank"] != "0"
                              ? int.parse(shortcut["teams"][i]["players"][j]
                                  ["matchRank"])
                              : 99,
                          win: shortcut["teams"][i]["players"][j]["matchWin"] != ""
                              ? int.parse(shortcut["teams"][i]["players"][j]["matchWin"])
                              : 0,
                          clicked: shortcut["teams"][i]["players"][j]["matchWin"] != "1" ? false : true,
                          matchTime: shortcut["teams"][i]["players"][j]["matchTime"] != "" ? int.parse(shortcut["teams"][i]["players"][j]["matchTime"]) : 0,
                          pet: shortcut["teams"][i]["players"][j]["pet"],
                          flyingPet: shortcut["teams"][i]["players"][j]["flyingPet"]));
                    }
                  }
                } else {
                  for (int j = 0; j < shortcut["players"].length; j++) {
                    rest.add(Cells(
                        accountNo: shortcut["players"][j]["accountNo"],
                        trackName: shortcut["players"][j]["characterName"],
                        trackId: shortcut["players"][j]["character"],
                        matchId: shortcut["players"][j]["kart"],
                        playerCount: shortcut["players"][j]["rankinggrade2"] !=
                                ""
                            ? int.parse(shortcut["players"][j]["rankinggrade2"])
                            : 0,
                        rank: shortcut["players"][j]["matchRank"] != "" && shortcut["players"][j]["matchRank"] != "0"
                            ? int.parse(shortcut["players"][j]["matchRank"])
                            : 99,
                        win: shortcut["players"][j]["matchWin"] != ""
                            ? int.parse(shortcut["players"][j]["matchWin"])
                            : 0,
                        clicked: shortcut["players"][j]["matchWin"] != "1"
                            ? false
                            : true,
                        matchTime: shortcut["players"][j]["matchTime"] != ""
                            ? int.parse(shortcut["players"][j]["matchTime"])
                            : 0,
                        pet: shortcut["players"][j]["pet"],
                        flyingPet: shortcut["players"][j]["flyingPet"]));
                  }
                }
                rest.sort((a, b) => a.rank.compareTo(b.rank));

                return ListView(
                  key: PageStorageKey<Cells>(cells),
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    Container(
                      width: 160.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          File("$dir/out/track/${cells.trackId}.png")
                                  .existsSync()
                              ? Image.file(
                                  File("$dir/out/track/${cells.trackId}.png"))
                              : Container(),
                          Text(
                            "속도: ${shortcut["gameSpeed"] == 0 ? "빠름" : (shortcut["gameSpeed"] == 1 ? "매우빠름" : (shortcut["gameSpeed"] == 2 ? "가장빠름" : (shortcut["gameSpeed"] == 3 ? "보통" : (shortcut["gameSpeed"] == 4 ? "무한부스터" : "통합"))))}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(),
                    Container(
                      child: ListView.separated(
                          key: PageStorageKey<Cells>(cells),
                          shrinkWrap: true,
                          separatorBuilder: (context, index) => VerticalDivider(
                                color: Colors.grey,
                              ),
                          physics: ScrollPhysics(),
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          itemCount: rest.length,
                          itemBuilder: (context, index) {
                            return _buildColumn(rest[index]);
                          }),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  title: Text('Error: ${snapshot.error}'),
                );
              } else {
                return ListTile(
                  title: Align(
                      alignment: Alignment.centerRight,
                      child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(Cells cells) {
    return InkResponse(
      enableFeedback: true,
      child: Container(
        width: 160.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(cells.rank > 8 || cells.rank < 1 ? "- " : cells.rank.toString() + " "),
                cells.win != 0
                    ? Icon(
                        Icons.thumb_up,
                        color: Colors.yellow,
                        size: 10,
                      )
                    : Container(),
                Expanded(
                  child: Text(
                    cells.trackName,
                    style: TextStyle(
                      color: index > 0 || cells.rank == 1 || cells.rank == 3
                          ? Colors.white
                          : Colors.black,
                      backgroundColor: index > 0
                          ? (cells.clicked ? Colors.blueAccent : Colors.red)
                          : (cells.rank == 1
                              ? Colors.amber[800]
                              : (cells.rank == 2
                                  ? Colors.grey
                                  : (cells.rank == 3
                                      ? Colors.brown
                                      : Colors.white))),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                File("$dir/out/character/${cells.trackId}.png").existsSync()
                    ? Image.file(
                        File("$dir/out/character/${cells.trackId}.png"),
                        scale: 6,
                      )
                    : Container(),
                File("$dir/out/kart/${cells.matchId}.png").existsSync()
                    ? Image.file(
                        File("$dir/out/kart/${cells.matchId}.png"),
                        scale: 7,
                      )
                    : Container(),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(cells.matchTime != 0
                      ? "${cells.matchTime ~/ 60000}:${((cells.matchTime ~/ 1000) % 60).toString().padLeft(2, "0")}:${(cells.matchTime % 1000).toString().padLeft(3, "0")}"
                      : "-:--:---"),
                ),
                cells.playerCount != 6
                    ? Text(
                        cells.playerCount == 1
                            ? "초보"
                            : (cells.playerCount == 2
                                ? "루키"
                                : (cells.playerCount == 3
                                    ? "L3"
                                    : (cells.playerCount == 4
                                        ? "L2"
                                        : (cells.playerCount == 5
                                            ? "L1"
                                            : (" "))))),
                        style: TextStyle(
                          color: cells.playerCount == 3
                              ? Colors.blue
                              : (cells.playerCount == 4
                                  ? Colors.red
                                  : (cells.playerCount == 5
                                      ? Colors.deepPurple
                                      : Colors.white)),
                          backgroundColor: cells.playerCount == 3 || cells.playerCount == 4 || cells.playerCount == 5
                              ? Colors.white
                              : (cells.playerCount == 1
                                  ? Colors.amber[700]
                                  : (cells.playerCount == 2
                                      ? Colors.green
                                      : null)),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => RadialGradient(
                          colors: <Color>[
                            Colors.red,
                            Colors.deepOrange,
                            Colors.orange,
                            Colors.amber,
                            Colors.yellow,
                            Colors.lime,
                            Colors.lightGreen,
                            Colors.green,
                            Colors.teal,
                            Colors.cyan,
                            Colors.lightBlue,
                            Colors.blue,
                            Colors.indigo,
                            Colors.purple,
                            Colors.deepPurple,
                            Colors.deepPurple,
                          ],
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: Text(
                          "Pro",
                          style: TextStyle(
                            // The color must be set to white for this to work
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
      onTap: () async {
        if (cells.accountNo != this.id) {
          await getAccessId(cells.accountNo).then((get) async {
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
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailApp(
                            id: get.accessId,
                            nickname: get.name,
                            level: get.level.toString(),
                            showAd: showAd,
                            matchIds: matchIds,
                          )));
            }
          });
        }
      },
      onLongPress: () async {
        await alert(cells);
      },
    );
  }

  Future<void> alert(Cells message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        String kart = "없음";
        String character = "없음";
        String pet = "없음";
        String flyingPet = "없음";
        for (int i = 0; i < karts.length; i++) {
          if (karts[i]["id"] == message.matchId) {
            kart = karts[i]["name"];
            break;
          }
        }
        for (int i = 0; i < characters.length; i++) {
          if (characters[i]["id"] == message.trackId) {
            character = characters[i]["name"];
            break;
          }
        }
        for (int i = 0; i < pets.length; i++) {
          if (pets[i]["id"] == message.pet) {
            pet = pets[i]["name"];
            break;
          }
        }
        for (int i = 0; i < flyingPets.length; i++) {
          if (flyingPets[i]["id"] == message.flyingPet) {
            flyingPet = flyingPets[i]["name"];
            break;
          }
        }
        return AlertDialog(
          title: Text(message.trackName),
          content: Text("라이센스: " +
              (message.playerCount == 1
                  ? "초보"
                  : (message.playerCount == 2
                      ? "루키"
                      : (message.playerCount == 3
                          ? "L3"
                          : (message.playerCount == 4
                              ? "L2"
                              : (message.playerCount == 5
                                  ? "L1"
                                  : (message.playerCount == 6
                                      ? "Pro"
                                      : ("없음"))))))) +
              "\n카트: " +
              kart +
              "\n캐릭터: " +
              character +
              "\n플라잉펫: " +
              flyingPet +
              "\n펫: " +
              pet),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> alertEndDate(DateTime startDate, DateTime endDate) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("이 경기의 시간 정보"),
          content: Text(
              "시작 시간: ${DateFormat.yMMMd().add_jm().format(startDate)}\n끝난 시간: ${DateFormat.yMMMd().add_jm().format(endDate)}"),
          actions: <Widget>[
            TextButton(
              child: Text('시작 시간 임시 저장'),
              onPressed: () {
                this.startDate = startDate;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('끝난 시간 임시 저장'),
              onPressed: () {
                this.endDate = endDate;
                this.isNow = false;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showPoint() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (_context, _setState) {
            return AlertDialog(
                title: Text("점수 계산 화면으로 이동"),
                actions: <Widget>[
                  TextButton(
                    child: Text('끝난 시간을 현재 시간으로 변경'),
                    onPressed: () {
                      _setState(() {
                        isNow = true;
                        endDate = DateTime.now();
                      });
                    },
                  ),
                  TextButton(
                    child: Text('취소'),
                    onPressed: () {
                      Navigator.of(_context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('이동'),
                    onPressed: () {
//                    Ads.hideBannerAd(bannerAd);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PointApp(
                                  startDate: startDate,
                                  endDate: endDate,
                                  nickname: nickname,
                                  isNow: isNow,
                                  speed: index > 0, // true시 팀전
                                  showAd: showAd,
                                )),
                      );
                    },
                  ),
                ],
                content: Text(
                    "시작 시간: ${DateFormat.yMMMd().add_jm().format(startDate)}\n끝난 시간: ${DateFormat.yMMMd().add_jm().format(endDate)}"));
          },
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
}
