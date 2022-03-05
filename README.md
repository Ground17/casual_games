# 카트라이더 전적검색 17%
Flutter application 입니다.

## 다운로드 링크
- [Android Play Store](https://play.google.com/store/apps/details?id=com.hyla981020.kartridersearch)
- [Apple App Store](https://apps.apple.com/us/app/%EC%B9%B4%ED%8A%B8-%EC%A0%84%EC%A0%81%EA%B2%80%EC%83%89-17/id1496982527)

## 화면 구성
- chart.dart
  - 승률, 완주율을 파이 차트로 나타낼 수 있게 하는 파일

- detail.dart
  - 실제 상세정보 페이지, 최근 200개 경기의 전적을 나타냄. 모드는 최근에 치른 경기의 모드가 기본값인데, 예를 들어 최근에 아이템 모드를 진행했다면, 기본으로 최근의 아이템 200경기가 나타난다. 당연히, 모드는 수정할 수 있다.

- main.dart
  - 어플을 실행했을 때의 초기 화면이다. 오른쪽 위에 최근 검색한 라이더를 한 눈에 볼 수 있도록 하여 이용자의 편의성을 조금 높였다.

- point.dart
  - 스피드전 팀전에서 팀 기여도나 팀이 이긴 횟수 등을 살펴보거나, 스피드전 개인전에서 10, 7, 5, 4, 3, 1, 0, -1, -5 계산법으로 특정 기간 내에 누적 점수를 계산할 수 있도록 하는 화면. 현재 리팩토링 진행 중.

- purchase.dart
  - 인앱 결제 관련 화면, 현재는 사정상 쓰이지 않음

- question.dart
  - 여러 information(어플 사용 방법 등)들을 모아놓은 화면

## (고급) API 이용법
[NEXON 개발자 센터](https://developers.nexon.com/kart)

## (고급) API json 응답 상세 구조
### metadata의 json들은 id가 사용되기 때문에, 적절히 name과 mapping하는 것이 중요하다.
**[여기](https://github.com/mschadev/kartrider-open-api-docs)가 공식 문서보다 정리가 아주 잘 되어있다.**
1. GET https://api.nexon.co.kr/kart/v1.0/users/{access_id} (유저 고유 식별자로 라이더명 조회)  
Response Body 예시
{
        "accessId": "1325628999",
        "name": "구글인턴",
        "level": 106
}
2. GET https://api.nexon.co.kr/kart/v1.0/users/nickname/{nickname} (라이더명으로 유저 정보 조회)  
Response Body 예시
{
        "accessId": "1325628999",
        "name": "구글인턴",
        "level": 106
}
3. GET https://api.nexon.co.kr/kart/v1.0/users/{access_id}/matches?start_date={start_date}&end_date={end_date}&offset={offset}&limit={limit}&match_types={match_types} (유저 고유 식별자로 매치 리스트 조회)  
Response Body 예시
{
        ~~추후작성~~
}
4. GET https://api.nexon.co.kr/kart/v1.0/matches/all?start_date={start_date}&end_date={end_date}&offset={offset}&limit={limit}&match_types={match_types} (모든 매치 리스트 조회)  
Response Body 예시
{
        ~~추후작성~~
}
5. GET https://api.nexon.co.kr/kart/v1.0/matches/{match_id} (특정 매치의 상세 정보 조회)  
Response Body 예시
{
        ~~추후작성~~
}
6. GET https://static.api.nexon.co.kr/kart/latest/metadata.zip (메타 데이터 다운로드)  
- metadata 폴더 구조
  - character
    - 00b6ba1b9d74bd6e9d8dc8f75288ed2419c68b466953b87ce4c22430f761bbcb.png
    - ...
  - character.json
    - [{"id":"4c139477f1eef41ec9a1c7c50319c6f391abb074fa44242eb7a143007e7f7720","name":"황금우비 배찌"}, ...]
  - kart
    - 0a7e18a68411c467d9cf2b3847a926b0b517651a1241416871a06a1b62a60234.png
    - ...
  - kart.json
    - [{"id":"4a3d34d9958d54ab218513e2dc406a6a7bc30e529292895475a11a986550b437","name":"골드 드래곤 HT"}, ...]
  - track
    - 0a2bcd781bffefe9fd176f3683c7dff645a9d179e4085fc47c137f439dbcd7c4.png
    - ...
  - track.json
    - [{"id":"c93843288b6c038f11328c0e4a4dae0663a94154242059e1a62f73503e84b104","name":"빌리지 두개의 관문"}, ...]
  - gameType.json
    - 아이템 개인전, 아이템 팀전, 스피드 개인전, 스피드 팀전 등 여러 모드들을 id와 name으로 구분.
  - pet.json
    - 펫의 id와 name.
  - flyingPet.json
    - 플라잉펫의 id와 name.

- Response Headers에서 이 서비스에 사용하는 데이터
  - Content-Length: 112721304 -> 메타데이터 다운로드 받을 때 전체 크기 추정
  - Last-Modified: Wed, 23 Feb 2022 09:21:50 GMT -> 메타데이터가 최근 다운받은 버전으로부터 변경되었는지 확인하여 변경될 때만 다운로드
