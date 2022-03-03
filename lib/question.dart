import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionApp extends StatefulWidget {
  QuestionApp({Key key}) : super(key: key);

//  final BuildContext context;
  @override
  _MyHomePageStates createState() => _MyHomePageStates();
}

class _MyHomePageStates extends State<QuestionApp> {
  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
      child: new ListView(
        shrinkWrap: true,
        children: <Widget>[
          ListTile(
            title: Text("이 어플리케이션을 이용해주셔서 감사합니다. 기본적으로, 초기 화면 검색창에 라이더명을 입력하여 최근 기록을 볼 수 있습니다."),
          ),
          Divider(),
          Text("초기 화면 상단 버튼", textAlign: TextAlign.left, style: TextStyle(fontSize: 20),),
          ListTile(
            leading: Icon(
              Icons.recent_actors,
            ),
            title: Text("이 버튼을 사용하면 최근 검색 라이더를 최대 10개까지 볼 수 있습니다."),
          ),
          ListTile(
            leading: Icon(
              Icons.person,
            ),
            title: Text("이 버튼을 사용하면 설정한 기간 내 점수를 계산할 수 있습니다. 팀전 친선 경기나 개인전 리그 경기 준비에 유용하게 쓰실 수 있습니다."),
          ),
          Divider(),
          Text("개발자 SNS", textAlign: TextAlign.center,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: "YouTube",
                      style: TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://www.youtube.com/channel/UCi_0ws8YydzS-C2i8GKoR4w';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        }
                  ),
                ),
              ),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: "Instagram",
                      style: TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://www.instagram.com/ground17_official/';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        }
                  ),
                ),
              )
            ],
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
        leading: new IconButton(
          icon: new Icon(Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("도움말"),
      ),
      body: _showBody(),
    );
  }
}