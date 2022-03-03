import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:kartridersearch/main.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:kartridersearch/ads.dart';
import 'package:kartridersearch/key.dart';
import 'package:flutter/foundation.dart';
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

//class Cells {
//  String accountNo;
//  String pet;
//  String flyingPet;
//  String matchId; // kart
//  String trackId; // character
//  String trackName; // characterName == nickname
//  bool clicked = false;
//  DateTime endTime;
//  int matchTime;
//  int playerCount; // rankinggrade2
//  int rank;
//  int win;
//  Cells({this.matchId, this.trackId, this.clicked, this.endTime, this.matchTime, this.playerCount, this.rank, this.trackName, this.accountNo, this.win, this.pet, this.flyingPet});
//}

class Score {
  final List<int> win;
  final String nickname;

  Score({this.win, this.nickname});

  int sum() {
    int temp = 0;
    for (int i = 0; i < win.length; i++) {
      temp += win[i];
    }
    return temp;
  }

  bool validate(int index) {
    return index < win.length;
  }
}

class TeamScore {
  final List<Score> players;
  int win;

  TeamScore({this.players, this.win = 0});

  int total() {
    int temp = 0;
    for (int i = 0; i < players.length; i++) {
      temp += players[i].sum();
    }
    return temp;
  }
}

class PointApp extends StatefulWidget {
  PointApp({Key key, this.startDate, this.endDate, this.nickname = "", this.isNow = true, this.speed = false, this.showAd = true}) : super(key: key);

  DateTime startDate;
  DateTime endDate;
  String nickname;
  bool isNow;
  bool speed; // 팀전 유무 확인
  bool showAd;

  @override
  _MyChangeState createState() => new _MyChangeState(
    startDate: startDate,
    endDate: endDate,
    nickname: nickname,
    isNow: isNow,
    speed: speed,
    showAd: showAd,
  );
}

class _MyChangeState extends State<PointApp> with SingleTickerProviderStateMixin {
  _MyChangeState({DateTime startDate, DateTime endDate, String nickname = "", bool isNow = true, bool speed = false, bool showAd = true}) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.nickname = nickname;
    this.isNow = isNow;
    this.speed = speed;
    this.showAd = showAd;
  }

  final _formKey = new GlobalKey<FormState>();
  bool setting = false;

  String dir;

  String id;
  String nickname;

  bool speed; // 팀전, 개인전

  DateTime startDate;
  DateTime endDate;

  bool isNow = false;

  List<dynamic> test;
  List<dynamic> track;
  List<dynamic> pets;
  List<dynamic> flyingPets;
  List<dynamic> karts;
  List<dynamic> characters;

  Directory character;
  Directory kart;

  int characterRandom;
  int kartRandom;

  List<String> matchTypes; // match

  List<Match> cells;
  Map<String, Score> localPlayers; // 점수 집계용 라이더 정보 모음
  List<TeamScore> localPlayersForTeam; // Score변수들을 팀으로 묶는 변수
  List<String> sortedPlayers;
  List<String> trackIds;
  List<String> matchIds; // matchid list

  File recent;
  List<dynamic> players; // 최근 검색 라이더

  bool showAd;

  BannerAd bannerAd;

  void _init() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    track = jsonDecode(File('$dir/out/track.json').readAsStringSync());
    test = jsonDecode(File('$dir/out/gameType.json').readAsStringSync());
    pets = jsonDecode(File('$dir/out/pet.json').readAsStringSync());
    flyingPets = jsonDecode(File('$dir/out/flyingPet.json').readAsStringSync());
    karts = jsonDecode(File('$dir/out/kart.json').readAsStringSync());
    characters = jsonDecode(File('$dir/out/character.json').readAsStringSync());
    recent = File('$dir/recent.txt');
    players = jsonDecode(recent.readAsStringSync());

    character = Directory('$dir/out/character');
    kart = Directory('$dir/out/kart');

    test = jsonDecode(File('$dir/out/gameType.json').readAsStringSync());
    for (int i=0; i < test.length; i++) {
      switch (test[i]["name"].toString()) {
        case "아이템 개인전":
          matchTypes[0] = test[i]["id"];
          break;
        case "아이템 팀전":
          matchTypes[1] = test[i]["id"];
          break;
        case "스피드 개인전":
          matchTypes[2] = test[i]["id"];
          break;
        case "스피드 팀전":
          matchTypes[3] = test[i]["id"];
          break;
        case "클럽 아이템 팀전":
          matchTypes[4] = test[i]["id"];
          break;
        case "클럽 스피드 팀전":
          matchTypes[5] = test[i]["id"];
          break;
      }
    }

    setState(() {
      characterRandom = Random().nextInt(character.listSync().length);
      kartRandom = Random().nextInt(kart.listSync().length);
    });
  }

  void first() {
    setState(() {
      setting = false;
      cells = null;
      localPlayers = null; // 점수 집계용 라이더 정보 모음
      localPlayersForTeam = null; // Score변수들을 팀으로 묶는 변수
      sortedPlayers = null;
      trackIds = null;
      matchIds = null;
      if (isNow) {
        endDate = DateTime.now();
      }
    });
//    Ads.hideBannerAd();
  }

  void second() {
    setState(() {
      sortedPlayers = [];
      setting = true;
      if (isNow) {
        endDate = DateTime.now();
      }
    });
//    if (showAd) {
//      Ads.showBannerAd();
//    }
  }

  @override
  void initState() {
    bannerAd = Ads.createBannerAd();

    if (showAd) {
      Ads.showBannerAd(bannerAd);
    }
    print("showAd: " + showAd.toString());

    if (startDate == null) {
      startDate = DateTime.now();
    }
    if (endDate == null) {
      endDate = DateTime.now();
    }
    matchTypes = <String> [
      "","","","","",""
    ];
    _init();
    super.initState();
  }

  Future<User> _user(String access_id, {String start_date = "", String end_date = "", int offset = 0, int limit = 10, String match_types = ""}) async {
    final response = await http.get (
      "https://api.nexon.co.kr/kart/v1.0/users/$access_id/matches?start_date=$start_date&end_date=$end_date&offset=$offset&limit=$limit&match_types=$match_types",
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
        "Authorization" : getAuthorization(),
      },
    );

    return User.fromJson(json.decode(response.body));
  }

  Future<void> _matches(List<String> matchIds) async {
    cells = [];
    if (matchIds != null && matchIds[0] != null) {
      for (int i = 0; i < matchIds.length; i++) {
        final response = await http.get (
          "https://api.nexon.co.kr/kart/v1.0/matches/${matchIds[i]}",
          headers: {
            "content-type" : "application/json",
            "accept" : "application/json",
            "Authorization" : getAuthorization(),
          },
        );
        cells.add(Match.fromJson(json.decode(response.body)));
      }
    }
  }

  Future<Get> _nickname(String nickname) async {
    final response = await http.get (
      "https://api.nexon.co.kr/kart/v1.0/users/nickname/" + nickname,
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
        "Authorization" : getAuthorization(),
      },
    );

    return Get.fromJson(json.decode(response.body));
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          leading: new IconButton(
            icon: new Icon(Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
//              if (showAd) {
//                Ads.showBannerAd();
//              }
            },
          ),
          title: Text('점수 계산', style: TextStyle(fontWeight: FontWeight.bold,),),
          actions: <Widget>[
            Row(
              children: <Widget>[
                setting ? IconButton(
                  icon: Icon(Icons.swap_horiz, color: Colors.white,),
                  onPressed: () {
                    first();
                  },
                ) : Container(),
                Text(speed ? "팀전" : "개인전"),
                !setting ? Switch(
                  value: speed,
                  onChanged: (value) {
                    speed = value;
                    first();
                  },
                ) : IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white,),
                  onPressed: () async {
                    if (isNow) {
                      endDate = DateTime.now();
                    }
                    await _nickname(nickname).then((get) async {
                      if (get.name != null) {
                        var data = await _user(get.accessId, start_date: DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate.add(Duration(hours: -9))), end_date: DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate.add(Duration(hours: -9))), limit: 200, match_types: speed ? matchTypes[3] : matchTypes[2]);
                        if (data != null && data.matches.length > 0) {
                          var shortcut = data.matches[0]["matches"];
                          trackIds = [];
                          matchIds = [];
                          for (int i = 0; i < shortcut.length; i++) {
                            if (track == null) break;
                            trackIds.insert(0, shortcut[i]["trackId"]);
                            matchIds.insert(0, shortcut[i]["matchId"]);
                          }
                        }
                      }
                    });
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
        body: setting ? ListView(
          shrinkWrap: true,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.softLight,
                  color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.black12 : Colors.white
              ),
              height: 500,
              child: FutureBuilder<void>(
                future: _matches(matchIds),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  List<Widget> children;
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (speed) {
                      if (localPlayersForTeam == null) {
                        localPlayers = new Map<String, Score>();
                        localPlayersForTeam = [];
                        localPlayersForTeam.add(TeamScore(players: []));
                        localPlayersForTeam.add(TeamScore(players: []));
                        try {
                          for (int j = 0; j < cells[0].match["teams"][0]["players"].length; j++) {
                            if (!localPlayers.containsKey(cells[0].match["teams"][0]["players"][j]["accountNo"])) {
                              localPlayers[cells[0].match["teams"][0]["players"][j]["accountNo"]] = new Score(win: [], nickname: cells[0].match["teams"][0]["players"][j]["characterName"]);
                            }
                            if (!localPlayersForTeam[0].players.contains(localPlayers[cells[0].match["teams"][0]["players"][j]["accountNo"]])) {
                              localPlayersForTeam[0].players.add(localPlayers[cells[0].match["teams"][0]["players"][j]["accountNo"]]);
                            }
                          }
                          for (int j = 0; j < cells[0].match["teams"][1]["players"].length; j++) {
                            if (!localPlayers.containsKey(cells[0].match["teams"][1]["players"][j]["accountNo"])) {
                              localPlayers[cells[0].match["teams"][1]["players"][j]["accountNo"]] = new Score(win: [], nickname: cells[0].match["teams"][1]["players"][j]["characterName"]);
                            }
                            if (!localPlayersForTeam[1].players.contains(localPlayers[cells[0].match["teams"][1]["players"][j]["accountNo"]])) {
                              localPlayersForTeam[1].players.add(localPlayers[cells[0].match["teams"][1]["players"][j]["accountNo"]]);
                            }
                          }
                        } catch (e) {
                          print(e);
                        }
                      }
                      localPlayersForTeam[0].win = 0;
                      localPlayersForTeam[1].win = 0;
                      for (int i = 0; i < localPlayersForTeam[0].players.length; i++) {
                        localPlayersForTeam[0].players[i].win.clear();
                      }
                      for (int i = 0; i < localPlayersForTeam[1].players.length; i++) {
                        localPlayersForTeam[1].players[i].win.clear();
                      }
                      for (int i = 0; i < cells.length; i++) {
                        if (int.parse(cells[i].match["teams"][0]["players"][0]["matchWin"] == "" ? "0" : cells[i].match["teams"][0]["players"][0]["matchWin"]) == 1) {
                          for (int j = 0; j < cells[0].match["teams"][0]["players"].length; j++) {
                            try {
                              if (localPlayersForTeam[0].players.contains(localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]]) ?? new Score()) {
                                localPlayersForTeam[0].win++;
                                break;
                              } else if (localPlayersForTeam[1].players.contains(localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]]) ?? new Score()) {
                                localPlayersForTeam[1].win++;
                                break;
                              }
                            } catch (e) {
                              print(e);
                            }
                          }
                        } else { // int.parse(cells[i].match["teams"][1]["players"][0]["matchWin"]) != 0
                          for (int j = 0; j < cells[0].match["teams"][1]["players"].length; j++) {
                            try {
                              if (localPlayersForTeam[0].players.contains(localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]]) ?? new Score()) {
                                localPlayersForTeam[0].win++;
                                break;
                              } else if (localPlayersForTeam[1].players.contains(localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]]) ?? new Score()) {
                                localPlayersForTeam[1].win++;
                                break;
                              }
                            } catch (e) {
                              print(e);
                            }
                          }
                        }
                        for (int j = 0; j < cells[i].match["teams"][0]["players"].length; j++) {
                          if (localPlayers.containsKey(cells[i].match["teams"][0]["players"][j]["accountNo"])) {
                            switch (cells[i].match["teams"][0]["players"][j]["matchRank"]) {
                              case "1":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(10);
                                break;
                              case "2":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(8);
                                break;
                              case "3":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(6);
                                break;
                              case "4":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(5);
                                break;
                              case "5":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(4);
                                break;
                              case "6":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(3);
                                break;
                              case "7":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(2);
                                break;
                              case "8":
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(1);
                                break;
                              default:
                                localPlayers[cells[i].match["teams"][0]["players"][j]["accountNo"]].win.add(0);
                                break;
                            }
                          }
                        }
                        for (int j = 0; j < cells[i].match["teams"][1]["players"].length; j++) {
                          if (localPlayers.containsKey(cells[i].match["teams"][1]["players"][j]["accountNo"])) {
                            switch (cells[i].match["teams"][1]["players"][j]["matchRank"]) {
                              case "1":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(10);
                                break;
                              case "2":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(8);
                                break;
                              case "3":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(6);
                                break;
                              case "4":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(5);
                                break;
                              case "5":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(4);
                                break;
                              case "6":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(3);
                                break;
                              case "7":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(2);
                                break;
                              case "8":
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(1);
                                break;
                              default:
                                localPlayers[cells[i].match["teams"][1]["players"][j]["accountNo"]].win.add(0);
                                break;
                            }
                          }
                        }
                      }
                    } else {
                      localPlayers = new Map<String, Score>();
                      for (int i = 0; i < cells.length; i++) {
                        if (i == 0) {
                          for (int j = 0; j < cells[0].match["players"].length; j++) {
                            localPlayers[cells[0].match["players"][j]["accountNo"]] = new Score(win: [], nickname: cells[0].match["players"][j]["characterName"]);
                          }
                        }
                        for (int j = 0; j < cells[i].match["players"].length; j++) {
                          if (localPlayers.containsKey(cells[i].match["players"][j]["accountNo"])) {
                            switch (cells[i].match["players"][j]["matchRank"]) {
                              case "1":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(10);
                                break;
                              case "2":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(7);
                                break;
                              case "3":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(5);
                                break;
                              case "4":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(4);
                                break;
                              case "5":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(3);
                                break;
                              case "6":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(1);
                                break;
                              case "7":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(0);
                                break;
                              case "8":
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(-1);
                                break;
                              default:
                                localPlayers[cells[i].match["players"][j]["accountNo"]].win.add(-5);
                                break;
                            }
                          }
                        }
                      }
                    }
                    children = localPlayers.length > 0 ? <Widget>[
                      speed ? Expanded(
                        child: Column(
                          children: _firstColumn(-3),
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        ),
                        flex: 5,
                      ) : Container(),
                      Expanded(
                        child: Column(
                          children: _firstColumn(-2),
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        ),
                        flex: speed ? 4 : 5,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(),
                            ),
                          ),
                          child: Column(
                            children: _firstColumn(-1),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          ),
                        ),
                        flex: 3,
                      ),
                      Expanded(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: trackIds.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext _context, int i) {
                              return _buildColumn(i);
                            }),
                        flex: 7,
                      ),
                    ] : <Widget>[
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
                        child: Text('Error: 정보가 없습니다.', textAlign: TextAlign.center,),
                      )
                    ];
                  } else if (snapshot.hasError) {
                    children = <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: ${snapshot.error}'),
                      )
                    ];
                  } else {
                    children = <Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text('잠시만 기다려주세요...', textAlign: TextAlign.center,),
                      )
                    ];
                  }
                  return Stack(
                    children: [
                      Row(
                        children: children,
                        crossAxisAlignment: snapshot.connectionState == ConnectionState.done ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          alignment: Alignment.center,
                          child: AdWidget(ad: bannerAd),
                          width: bannerAd.size.width.toDouble(),
                          height: bannerAd.size.height.toDouble(),
                        ),
                      ),
                    ]
                  );
                },
              ),
            ),
          ],
        ) : Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.softLight,
              color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.black12 : Colors.white
          ),
          child: Form(
            key: _formKey,
            child: new ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showEmailInput(),
                TextButton(
                    onPressed: () {
                      DatePicker.showDatePicker(context,
                          showTitleActions: true,
                          minTime: DateTime(2011, 1, 1),
                          onConfirm: (date) {
                            setState(() {
                              startDate = new DateTime(date.year, date.month, date.day, startDate.hour, startDate.minute, startDate.second);
                            });
                          }, currentTime: startDate, locale: LocaleType.ko);
                    },
                    child: Text(
                      '시작한 날짜 설정',
                      style: TextStyle(color: Colors.blue),
                    )
                ),
                TextButton(
                    onPressed: () {
                      DatePicker.showTime12hPicker(context, showTitleActions: true,
                          onConfirm: (date) {
                            setState(() {
                              startDate = new DateTime(startDate.year, startDate.month, startDate.day, date.hour, date.minute, date.second);
                            });
                          }, currentTime: startDate, locale: LocaleType.ko);
                    },
                    child: Text(
                      '시작한 시간 설정',
                      style: TextStyle(color: Colors.blue),
                    )
                ),
                TextButton(
                    onPressed: () {
                      DatePicker.showDatePicker(context,
                          showTitleActions: true,
                          minTime: DateTime(2011, 1, 1),
                          onConfirm: (date) {
                            setState(() {
                              isNow = false;
                              endDate = new DateTime(date.year, date.month, date.day, endDate.hour, endDate.minute, endDate.second);
                            });
                          }, currentTime: endDate, locale: LocaleType.ko);
                    },
                    child: Text(
                      '끝난 날짜 설정',
                      style: TextStyle(color: Colors.blue),
                    )
                ),
                TextButton(
                    onPressed: () {
                      DatePicker.showTime12hPicker(context,
                          showTitleActions: true,
                          onConfirm: (date) {
                            setState(() {
                              isNow = false;
                              endDate = new DateTime(endDate.year, endDate.month, endDate.day, date.hour, date.minute, date.second);
                            });
                          }, currentTime: endDate, locale: LocaleType.ko);
                    },
                    child: Text(
                      '끝난 시간 설정',
                      style: TextStyle(color: Colors.blue),
                    )
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 30.0),
                  child: Row(
                    children: <Widget>[
                      Checkbox(value: isNow, onChanged: (bool value) {
                        setState(() {
                          isNow = value;
                          if (value) {
                            endDate = DateTime.now();
                          }
                        });
                      }),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              isNow = !isNow;
                              if (isNow) {
                                endDate = DateTime.now();
                              }
                            });
                          },
                          child: Text(
                            '끝난 시간을 현재 시간으로',
                          )
                      ),
                    ],
                  ),
                ),
                Text('시작한 시간: ${DateFormat.yMMMd().add_jm().format(startDate)}', textAlign: TextAlign.center,),
                Text('끝난 시간: ${DateFormat.yMMMd().add_jm().format(endDate)}', textAlign: TextAlign.center,),

                _submit(),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                ),
                _image(),
                Text("\nData based on NEXON DEVELOPERS\n\n"
                    "이 어플은 NEXON 공식 어플이 아닌 제3자가 개발/배포한 어플입니다.", textAlign: TextAlign.center,),
              ],
            ),
          ),
        ),
      ),
      onWillPop: _pop,
    );
  }

  Future<bool> _pop() async {
    Navigator.of(context).pop();
//    if (showAd) {
//      Ads.showBannerAd();
//    }
    return true;
  }

  Widget _buildColumn(int index) {// 맨 처음 2개 컬럼을 제외한 나머지 컬럼 만들기
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _firstColumn(index),
    );
  }

  List<Widget> _firstColumn(int index) { // 맨 처음 2개 컬럼 만들기
    List<Widget> children = [];
    if (sortedPlayers == null || sortedPlayers.length < 1) {
      _arrange(-1);
    }
    if (speed) {
      children.add(
        Column(
          children: <Widget>[
            TextButton(
              child: Text(index < 0 ? (index == -1 ? '승' : (index == -2 ? '기여도' : '닉네임')) : (index + 1).toString()),
              onPressed: () {
                setState(() {
                  _arrange(index >= 0 ? index : -1);
                });
              },
            ),
            Divider()
          ],
        ),
      );
      for (int i = 0; i < localPlayersForTeam.length; i++) {
        for (int j = 0; j < localPlayersForTeam[i].players.length; j++) {
          if (index == -3) {
            children.add(
                Container(
                  child: Text(localPlayersForTeam[i].players[j].nickname)
                )
            );
          } else if (index == -2) {
            children.add(
                Container(
                  child: Text((localPlayersForTeam[i].players[j].sum() * 100 / localPlayersForTeam[i].total()).toStringAsFixed(2) + "%"),
                )
            );
          } else if (index == -1) { /// 균등 분배
            children.add(
                Container(
                  child: Text(localPlayersForTeam[i].win.toString()),
                )
            );
            break;
          } else {
            children.add(
                Container(
                    child: Text(localPlayersForTeam[i].players[j].validate(index) ? localPlayersForTeam[i].players[j].win[index].toString() : "X")
                )
            );
          }
        }
        if (i == 0) {
          children.add(Divider());
        }
      }
      children.add(
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Divider(),
              Container(
                height: 80.0,
                child: index >= 0 && File("$dir/out/track/${trackIds[index]}.png").existsSync() ? Image.file(
                    File("$dir/out/track/${trackIds[index]}.png")
                ) : Container(),
              ),
              Container(
                height: 80.0,
              )
            ],
          )
      );
    } else {
      children.add(
        TextButton(
          child: Text(index < 0 ? (index == -1 ? '점수' : '닉네임') : (index + 1).toString()),
          onPressed: () {
            setState(() {
              _arrange(index >= 0 ? index : -1);
            });
          },
        ),
      );
      children.add(
          Divider()
      );
      for (int i = 0; i < sortedPlayers.length; i++) {
        if (index == -2) {
          children.add(
              Container(
                  child: Text(localPlayers[sortedPlayers[i]].nickname)
              )
          );
        } else if (index == -1) {
          children.add(
              Container(
                  child: Text(localPlayers[sortedPlayers[i]].sum().toString()),
              )
          );
        } else {
          children.add(
              Container(
                  child: Text(localPlayers[sortedPlayers[i]].validate(index) ? localPlayers[sortedPlayers[i]].win[index].toString() : "X")
              )
          );
        }
      }
      children.add(
          Divider()
      );
      children.add(
          Container(
            height: 80.0,
            child: index >= 0 && File("$dir/out/track/${trackIds[index]}.png").existsSync() ? Image.file(
              File("$dir/out/track/${trackIds[index]}.png"),
            ) : Container(),
          )
      );
    }
//    children.add(
//        Container(
//          height: 80.0,
//        )
//    );

    return children;
  }

  void _arrange(int index) {
    sortedPlayers = [];
    if (speed) {
      for (String key in localPlayers.keys) {
        sortedPlayers.add(key);
      }
      if (localPlayersForTeam[0].win < localPlayersForTeam[1].win) {
        localPlayersForTeam = localPlayersForTeam.reversed.toList();
      }
      if (index == -1) {
        for (int i = 0; i < localPlayersForTeam.length; i++) {
          localPlayersForTeam[i].players.sort((a, b) => b.sum().compareTo(a.sum()));
        }
      } else {
        for (int i = 0; i < localPlayersForTeam.length; i++) {
          localPlayersForTeam[i].players.sort((a, b) => b.validate(index) && a.validate(index) ? b.win[index].compareTo(a.win[index]) : (b.validate(index) && !a.validate(index) ? b.win[index].compareTo(0) : -11));
        }
      }
    } else {
      if (index == -1) {
        for (var key in localPlayers.keys) {
          bool added = false;
          for (int j = 0; j < sortedPlayers.length; j++) {
            if (sortedPlayers.length > 0 && localPlayers[key].sum() > localPlayers[sortedPlayers[j]].sum()) {
              sortedPlayers.insert(j, key);
              added = true;
              break;
            }
          }
          if (!added) {
            sortedPlayers.add(key);
          }
        }
      } else {
        for (var key in localPlayers.keys) {
          bool added = false;
          for (int j = 0; j < sortedPlayers.length; j++) {
            if (sortedPlayers.length == 0) {
              break;
            }
            if (localPlayers[key].validate(index) && localPlayers[sortedPlayers[j]].validate(index) && localPlayers[key].win[index] > localPlayers[sortedPlayers[j]].win[index]) {
              sortedPlayers.insert(j, key);
              added = true;
              break;
            } else if (localPlayers[key].validate(index) && !localPlayers[sortedPlayers[j]].validate(index)) {
              sortedPlayers.insert(j, key);
              added = true;
              break;
            }
          }
          if (!added) {
            sortedPlayers.add(key);
          }
        }
      }
    }
  }

  Future<Get> getAccessId(String aceess_id) async {
    final response = await http.get (
      "https://api.nexon.co.kr/kart/v1.0/users/" + aceess_id,
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
        "Authorization" : getAuthorization(),
      },
    );

    return Get.fromJson(json.decode(response.body));
  }

  Future<Widget> loadImage() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    if (character != null && kart != null && await character.exists() && await kart.exists()) {
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
    return FutureBuilder(builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
      return snapshot.data;
    },
      future: loadImage(),
      initialData: Container(width: 0.0, height: 0.0),
    );
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
        initialValue: nickname ?? "",
        onSaved: (value) => nickname = value,
      ),
    );
  }

  Widget _submit() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
      child: ElevatedButton(
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.blue[900] : Colors.blue[700])),
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
      await _nickname(nickname).then((get) async {
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
          await _user(get.accessId, start_date: DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate.add(Duration(hours: -9))), end_date: DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate.add(Duration(hours: -9))), limit: 200, match_types: speed ? matchTypes[3] : matchTypes[2]).then((data) async {
            var shortcut;
            trackIds = [];
            matchIds = [];
            if (data != null && data.matches.length > 0) {
              shortcut = data.matches[0]["matches"];
              for (int i = 0; i < shortcut.length; i++) {
                if (track == null) break;
                trackIds.insert(0, shortcut[i]["trackId"]);
                matchIds.insert(0, shortcut[i]["matchId"]);
              }
            }
            if (trackIds.length > 0) {
              await _confirm(trackIds[0]);
            } else {
              _alert("정보가 없습니다. 날짜를 다시 확인해주세요.");
            }
          });
        } else {
          _alert("라이더 정보가 없습니다. 닉네임을 다시 확인해주세요.");
        }
      }).catchError((e) {
        print(e);
        _alert("닉네임, 날짜 또는 개인전/팀전 스위치를 다시 확인해주세요.");
      });
    }
  }

  Future<void> _alert(String message) async {
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

  Future<void> _confirm(String trackId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        String trackName = "알 수 없는 트랙";
        for (int j = 0; j < track.length; j++) {
          if (track[j]["id"] == trackId) {
              trackName = track[j]["name"];
              break;
            }
        }
        return AlertDialog(
          title: Text("첫 번째 트랙이 아래와 같습니까?"),
          actions: <Widget>[
            TextButton(
              child: Text('아니오'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('네'),
              onPressed: () {
                second();
                Navigator.of(context).pop();
              },
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              File("$dir/out/track/$trackId.png").existsSync() ? Image.file(
                  File("$dir/out/track/$trackId.png")
              ) : Container(),
              Text(trackName),
            ],
          ),
        );
      },
    );
  }
}