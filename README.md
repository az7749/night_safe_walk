# 🌙 Night Safe Walk · 야간안심보행플랫폼

**도로 안전도와 보행 경로를 지도에서 확인하는 Flutter 앱입니다.**

야간 보행 시 주변 도로의 안전 정보를 살펴보고 이동 경로를 확인할 수 있도록 개발하고 있습니다. 네이버 지도 위에 서버에서 제공하는 도로 안전 점수를 색상으로 표시하고, 선택한 출발지와 도착지 사이의 경로를 보여줍니다.

> 이 README는 GitHub 기본 브랜치에 반영된 기능을 기준으로 작성했습니다. 도로 데이터 조회와 경로 탐색에는 별도의 백엔드 서버가 필요합니다.

## 주요 기능

| 기능 | 설명 |
| --- | --- |
| 지도 탐색 | 네이버 지도 기반으로 주변 지역 확인 |
| 현재 위치 | 위치 권한을 받아 현재 위치로 지도 이동 |
| 도로 안전도 표시 | 지도에 보이는 영역의 도로를 조회해 안전 점수별 색상으로 표시 |
| 출발지·도착지 선택 | 지도에서 두 지점을 차례로 눌러 경로 설정 |
| 경로 조회 | 백엔드에서 받은 경로를 지도에 표시 |
| 하단 메뉴 | 길 안내·즐겨찾기·더보기 패널 제공 |

현재 앱은 메인 지도 화면으로 시작합니다. 검색창은 클릭 로그만 출력하는 상태이며, 하단 메뉴의 화면 구성과 실제 서비스 연동 여부는 구분해서 확인해야 합니다.

### 도로 안전도 색상

| 서버에서 받은 안전 점수 | 지도 표시 |
| --- | --- |
| 40 미만 | 🔴 빨강 |
| 40 이상 ~ 60 미만 | 🟠 주황 |
| 60 이상 ~ 80 미만 | 🟡 노랑 |
| 80 이상 | 🟢 초록 |

도로 정보는 지도 줌 레벨 14 이상에서 표시됩니다. 점수가 없는 도로는 현재 코드에서 0점으로 처리합니다. 안전 점수의 산정은 백엔드에서 담당합니다.

## 기술 스택

| 구분 | 사용 기술 |
| --- | --- |
| 앱 | Flutter / Dart |
| 지도 | `flutter_naver_map` |
| 위치 | `geolocator` |
| API 통신 | `http` |
| 로컬 저장소 | `shared_preferences` |

Dart SDK 요구 사항은 `^3.11.1`이며, 패키지 정보는 [pubspec.yaml](pubspec.yaml)에서 확인할 수 있습니다.

## 실행 방법

### 1. 개발 환경 준비

- Dart SDK 요구 사항을 충족하는 Flutter SDK
- Android SDK 및 Android 에뮬레이터 또는 실제 기기
- 사용할 앱에 맞는 네이버 지도 Client ID
- 도로 데이터 및 경로 API를 제공하는 백엔드 서버

### 2. 프로젝트 받기

```bash
git clone https://github.com/az7749/night_safe_walk.git
cd night_safe_walk
flutter pub get
```

### 3. 지도 설정

[lib/main.dart](lib/main.dart)의 `FlutterNaverMap().init()`에서 `clientId`를 실행 환경에 맞게 설정합니다. 지도 인증에 사용되는 앱 등록 정보도 실행할 앱과 일치해야 합니다.

### 4. 백엔드 연결

현재 API 주소는 코드에 `http://10.0.2.2:5000`으로 지정되어 있습니다.

- **Android 에뮬레이터:** 호스트 PC의 5000번 포트에서 백엔드를 실행합니다.
- **실제 기기:** 기기에서 접근 가능한 서버 주소로 API URL을 변경합니다.

경로 API 주소는 [main_screen.dart](lib/features/main/main_screen.dart), 도로 API 주소는 [road_overlay_service.dart](lib/features/map/service/road_overlay_service.dart)에 있습니다. 다른 API를 사용할 경우 해당 서비스의 주소도 확인해야 합니다.

주요 지도 API는 다음과 같습니다.

| 요청 | 역할 | 주요 쿼리 |
| --- | --- | --- |
| `GET /roads` | 현재 지도 영역의 도로·안전 점수 조회 | `min_lat`, `max_lat`, `min_lng`, `max_lng`, `limit` |
| `GET /route` | 출발지와 도착지 사이 경로 조회 | `s_lat`, `s_lng`, `e_lat`, `e_lng` |

앱은 도로 응답의 `success`, `roads`와 경로 응답의 `success`, `path` 필드를 사용합니다. 백엔드 실행 및 데이터 준비는 별도로 필요합니다.

### 5. 앱 실행

```bash
flutter run
```

현재 위치 기능을 사용할 때는 기기의 위치 서비스를 켜고 위치 권한을 허용합니다.

## 사용 흐름

1. 지도를 이동하거나 현재 위치 버튼으로 원하는 지역을 확인합니다.
2. 지도를 확대해 도로 안전도 색상을 확인합니다.
3. 지도에서 출발지와 도착지를 차례로 선택합니다.
4. 길 안내 패널에서 경로를 요청하고 지도에 표시된 경로를 확인합니다.

## 주요 코드 구조

```text
lib/
├── main.dart                       # 앱 시작 및 네이버 지도 초기화
├── components/
│   ├── bottom_navbar.dart          # 하단 내비게이션
│   ├── map_search_bar.dart         # 검색창 UI
│   └── bottom_sheets/              # 길 안내·즐겨찾기·더보기 패널
└── features/
    ├── auth/                       # 인증 관련 화면 및 로직
    ├── main/
    │   └── main_screen.dart        # 메인 화면 및 경로 요청
    └── map/
        ├── map_screen.dart         # 지도·위치·경로 표시
        └── service/
            └── road_overlay_service.dart  # 도로 안전도 조회 및 표시
```

## 개발 명령어

```bash
flutter analyze
flutter test
flutter build apk --debug
```

위 명령은 정적 분석, 테스트, 개발용 APK 빌드에 사용합니다.
