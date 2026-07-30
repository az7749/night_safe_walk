# 기능 현황

앱과 서버 전반의 기능 구현 상태를 추적하는 문서이다.

## 상태 표기

| 상태 | 의미 |
| --- | --- |
| `○ 완료` | 사용자가 실제 흐름을 수행할 수 있는 상태 |
| `△ 진행 중` | 일부 구현됐지만 API, 화면, 예외 처리, 검증 중 하나 이상이 남은 상태 |
| `X 미구현` | 아직 사용자 기능으로 동작하지 않는 상태 |

## 사용자 기능

### 1.1 회원 관리

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 회원가입 | `○ 완료` | 아이디, 비밀번호, 이름, 전화번호, 성별, 생년월일 입력 기반 회원가입 흐름 구현. |
| 로그인 | `○ 완료` | 아이디와 비밀번호 기반 로그인 흐름 구현. |
| 비밀번호 찾기 | `△ 진행 중` | 로그인 화면에서 비밀번호 찾기 화면으로 이동해 아이디, 이름, 전화번호, 새 비밀번호를 입력하고 `/password-reset` API를 호출하는 흐름이 연결돼 있다. 다만 본인 확인 기준과 서버 응답 계약 검증은 남아 있다. |
| 정보 수정 | `△ 진행 중` | 더보기 시트에서 내 정보 화면으로 이동해 프로필 조회, 이름/전화번호/생년월일/성별 수정, 비밀번호 변경 API 호출까지 연결돼 있다. 다만 로그인 세션 유지와 서버 검증 규칙 확인은 남아 있다. |

### 1.2 지도

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 안전 인프라 지도 보기 | `△ 진행 중` | 현재 워킹트리 기준 `MapScreen`은 현재 위치 이동, 지도 탭 기반 경로 지점 선택, 검색 결과 카메라 이동, bounds 기준 도로 오버레이 재조회, 반경 30m 내 신고 후보 시설물 표시까지 연결돼 있다. 다만 상시 시설물 레이어와 지도 범례, `final_score` 기준 안내는 아직 없다. |
| 도로 안전 등급 확인 | `△ 진행 중` | `RoadOverlayService`가 현재 화면 bounds 기준 `/roads` 오버레이를 재조회하고 지도의 폴리라인으로 표시한다. 현재는 `safety_score` 4단계 색상 매핑 기준으로 동작하며 `final_score` 사용, 5단계 규칙 정리, 시설물 레이어와 병행 표시는 남아 있다. |

### 1.3 내비게이션

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 안심 경로 탐색 | `△ 진행 중` | 지도 탭 또는 `/search/places` 검색 패널 결과로 출발지/도착지 좌표를 선택하고, 길안내 시트에서 빠른길/안전한길 모드로 `/route` API를 호출해 경로 폴리라인을 그리는 흐름이 연결됐다. 아직 경로 품질 검증, 안전한길 모드의 실제 점수 반영 검증, 검색 UX 다듬기가 남아 있다. |
| 경로 옵션 설정 | `X 미구현` | 추천 안심 경로와 대로변 우선 경로 선택 기능은 아직 미구현. |

### 1.4 안심 케어

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 긴급 SOS 요청 | `X 미구현` | 위급 상황 시 사전 등록 연락처로 현재 위치와 도로 정보를 전송하는 기능은 아직 미구현. |

### 1.5 신고

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 안전 시설물 신고 | `△ 진행 중` | 지도에서 현재 위치 기준 반경 30m 내 신고 후보 시설물을 불러오고, 시설물 종류/거리 확인 후 신고 CTA를 띄우는 시제품이 연결돼 있다. 다만 신고 작성 화면, 사진 첨부, 실제 신고 전송은 아직 미구현이다. |
| 신고 내역 조회 | `X 미구현` | 사용자가 제보한 신고 내역과 처리 상태 조회 기능은 아직 미구현. |

### 1.6 알림

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 위험 진입 알림 | `△ 진행 중` | `MapScreen`이 위치 스트림을 구독하고 `RiskZoneAlertService`로 `/roads/nearest-risk`를 조회해 위험 도로 근접 시 화면 경고 오버레이와 배너를 표시한다. 다만 진동/푸시 연동, 백그라운드 처리, 임계값 검증은 남아 있다. |
| 알림 내역 조회 | `X 미구현` | 위험 진입 알림, SOS 관련 알림 등의 내역 조회 기능은 아직 미구현. |
| 알림 설정 | `X 미구현` | 위험 진입 알림, SOS 관련 알림 등의 수신 여부 설정 기능은 아직 미구현. |

### 1.7 비상 연락처

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 비상 연락처 등록 | `X 미구현` | 긴급 SOS 호출 시 문자를 받을 보호자 및 지인 연락처 등록 기능은 아직 미구현. |
| 비상 연락처 수정 | `X 미구현` | 등록된 보호자 이름과 전화번호 수정 기능은 아직 미구현. |
| 비상 연락처 삭제 | `X 미구현` | 더 이상 사용하지 않는 비상 연락처 삭제 기능은 아직 미구현. |

### 1.8 즐겨찾기

| 기능 | 상태 | 현재 구현/남은 작업 |
| --- | --- | --- |
| 즐겨찾기 추가 | `X 미구현` | 자주 방문하는 장소를 등록해 빠르게 목적지를 설정하는 기능은 아직 미구현. |
| 즐겨찾기 삭제 | `X 미구현` | 목록에서 불필요한 즐겨찾기 장소를 삭제하는 기능은 아직 미구현. |

## 구현 상태 요약

| 구분 | 기능 |
| --- | --- |
| 완료 | 회원가입, 로그인, 하단 내비게이션 기본 구조, 지도 중심 메인 화면, 현재 위치 이동 버튼과 권한 요청 흐름 |
| 진행 중 | 비밀번호 재설정/프로필 수정 화면과 API 연동, bounds 기반 도로 오버레이 조회, 장소 검색 패널과 빠른길/안전한길 버튼을 포함한 경로탐색 시제품, 위험 도로 진입 알림 시제품, 반경 30m 시설물 신고 후보 표시 |
| 보류/미구현 | 시설물 상시 레이어/범례 정리, 경로 품질 검증, SOS, 알림 내역/설정, 실제 신고 작성/전송, 비상 연락처, 즐겨찾기 관리 |

## 다음 세미나까지 할 일

- PPT에 점수 산정 알고리즘 설명을 추가한다. 특히 안전 점수를 왜 해당 방식으로 계산했는지 근거와 계산 흐름을 정리한다.
- 지도 기능은 완료된 범위로 정리하고, 이후 작업의 중심을 경로탐색 기능 구현으로 이동한다.
- 출발지와 목적지를 기반으로 안심 경로를 탐색하는 기능의 화면 흐름, 데이터/API 연동 방식, 안전 점수 반영 방식을 구체화한다.
- 빠른길과 안전한길 모드 차이를 발표 때 설명할 수 있도록, 현재 `/route` 응답이 어떤 기준으로 분기되는지와 검증 계획을 정리한다.

## 현재 중점 작업

- 인증 부가 기능은 비밀번호 재설정과 프로필 수정 화면이 연결된 만큼 서버 계약과 오류 처리 기준을 검증한다.
- 경로탐색 기능을 다음 주요 개발 범위로 두고 검색 기반 출발지/목적지 입력, 경로 후보 조회, 안전 점수 기반 추천 흐름을 구체화한다.
- `/roads` 오버레이를 `final_score` 기반 색상 표시와 5단계 안전 등급 규칙으로 보강하고 시설물 마커와 함께 운영할 방식을 정리한다.
- `crime_wms.png` 기반 범죄주의구간 감점 계산은 CSV 캐시 방식부터 검증한다.
- 검색 패널, 경로 모드 버튼, 지도 탭 선택 흐름이 한 화면에서 이어지도록 연결된 만큼 실제 서버 응답 기준으로 빠른길/안전한길 차이를 검증한다.
- 위험 도로 진입 알림은 현재 화면 오버레이 시제품 수준이므로 진동/푸시 여부, 임계 반경, 중복 알림 쿨다운 규칙을 실제 시나리오로 검증한다.

## 작업 로그

### 2026-05-28

- 확인: `lib/features/map/map_screen.dart`는 현재 화면 bounds 기준 시설물 마커 재조회와 현재 위치 이동 흐름까지 연결돼 있으며, 도로 오버레이 호출은 아직 연결되지 않았다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`가 새로 추가되어 `/roads` 응답을 `NPolylineOverlay`로 그리는 시제품이 준비됐다.
- 진행 중: `lib/features/main/main_screen.dart`, `lib/components/bottom_sheets/guide_bottom_sheet.dart`, `lib/components/map_search_bar.dart`에는 길안내 화면 골격과 안내 문구가 있으나 실제 출발지/목적지 입력 및 경로 계산은 연결되지 않았다.
- 완료: `docs/ROAD_SAFETY_WMS_SCORING_PLAN.md`에 범죄주의구간 WMS 기반 감점 계산과 `final_score` CSV 캐시 방향이 정리됐다.
- 보류: `docs/WORK_LOG.md`는 현재 워킹트리에서 삭제 상태로 남아 있으며 이번 작업에서는 삭제 여부를 변경하지 않았다.

### 2026-06-02

- 확인: `lib/features/map/map_screen.dart`는 지도 탭으로 출발지와 도착지를 순서대로 선택하고, 선택 지점 마커와 경로 폴리라인을 함께 표시하도록 확장됐다.
- 진행 중: `lib/features/main/main_screen.dart`와 `lib/components/bottom_sheets/guide_bottom_sheet.dart`에 출발지/도착지 좌표 표시, 초기화, `/route` 호출 버튼이 추가되어 경로탐색 시제품이 실제 API 호출 단계까지 연결됐다.
- 진행 중: 도로 안전도 표시는 `RoadOverlayService`를 통해 `MapScreen`과 연결됐지만 현재는 `safety_score` 4단계 색상 매핑 기준이며 `final_score`와 5단계 기준 반영은 남아 있다.
- 진행 중: 지도 탭 선택 방식은 연결됐지만 `lib/components/map_search_bar.dart` 기준 검색 입력 흐름과 경로 옵션 선택 UI는 아직 미연결 상태다.
- 완료: `android/app/src/main/AndroidManifest.xml`에 위치 권한 선언이 들어가 있고 `lib/main.dart` 기본 시작 화면도 `MainScreen` 기준으로 맞춰져 지도/경로 화면을 바로 확인할 수 있다.

### 2026-06-04

- 확인: 지난 실행 이후 새 커밋은 없고, 현재 변경 사항은 워킹트리 수정본에 반영돼 있다.
- 완료: `lib/features/main/main_screen.dart`와 `lib/components/map_search_bar.dart`에 검색 패널이 연결되어 `/search/places` 결과를 선택하면 지도 카메라 이동과 출발지/도착지 지정까지 이어진다.
- 완료: `lib/components/bottom_sheets/guide_bottom_sheet.dart`는 좌표 표시, 초기화, 경로 계산 버튼을 포함하는 길안내 시트 형태로 정리됐다.
- 진행 중: `lib/features/map/map_screen.dart`는 도로 오버레이 재조회, 출발지/도착지 마커, 경로 폴리라인 표시는 연결됐지만 시설물 마커 로딩은 빠진 상태라 지도 기능 범위를 다시 정리해야 한다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`는 `/roads` 응답을 `safety_score` 기준 4색 폴리라인으로 표시하며, `final_score` 및 5단계 규칙 반영은 남아 있다.
- 완료: `docs/ROAD_SAFETY_WMS_SCORING_PLAN.md`에 `crime_wms.png` 기반 감점 계산을 CSV 캐시 중심으로 연결하는 설계 메모가 추가됐다.
- 보류: 다음 세미나 할 일은 기존 문서 항목 외에 새로 확인된 사용자 전달 사항이 없어 중복 없이 유지했다.

### 2026-06-20

- 확인: 현재 워킹트리는 `CCTV 화면 범위 재조회 적용` 커밋 이후 추가 커밋 없이 수정본만 누적된 상태이며, 지도 화면의 중심 기능이 시설물 마커에서 도로 오버레이와 경로 선택 흐름으로 이동했다.
- 완료: `lib/features/main/main_screen.dart`가 검색 패널 열기/닫기, `/search/places` 결과 목록, 출발지/도착지 상태, `/route` 호출 결과 경로 좌표를 한 화면에서 관리하도록 확장됐다.
- 완료: `lib/components/bottom_sheets/guide_bottom_sheet.dart`는 출발지/도착지 좌표 요약, 초기화, 경로 계산 버튼을 포함하는 실제 조작 UI로 바뀌어 경로탐색 시제품 흐름을 바로 실행할 수 있다.
- 완료: `lib/features/map/map_screen.dart`는 지도 탭으로 경로 지점을 선택하고, 검색 결과 좌표로 카메라를 이동시키며, 출발지/도착지 마커와 경로 폴리라인을 함께 렌더링한다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`와 `MapScreen`의 연동으로 줌 14 이상에서 현재 화면 bounds 기준 `/roads`를 재조회하지만, 점수 표시는 아직 `safety_score` 4단계 색상 기준이라 `final_score` 및 5단계 규칙 반영이 남아 있다.
- 진행 중: `/facilities` 기반 시설물 마커 레이어는 현재 지도 흐름에서 빠져 있어 "안전 인프라 지도 보기" 범위를 현 상태 기준으로 재정의하거나 시설물 레이어를 다시 연결해야 한다.
- 보류: 저장소 안에서는 다음 세미나 관련 새 전달 사항이 추가로 확인되지 않아 기존 "다음 세미나까지 할 일" 항목만 유지했다.

### 2026-06-25

- 확인: `lib/features/main/main_screen.dart`, `lib/features/map/map_screen.dart`, `lib/components/bottom_sheets/guide_bottom_sheet.dart`, `lib/features/map/service/road_overlay_service.dart` 기준 현재 워킹트리의 핵심 흐름은 장소 검색, 지도 탭 선택, `/route` 호출, `/roads` 오버레이 재조회까지로 유지되고 있으며 지난 기록 이후 새 기능 완료 항목은 추가로 확인되지 않았다.
- 확인: `docs/WORK_LOG.md`는 삭제 상태로 남아 있고, 최근 작업 이력은 `docs/FEATURE_STATUS.md` 한 곳에 합쳐 관리하는 형태로 정리되고 있다.
- 진행 중: 도로 안전도 표시는 여전히 `safety_score` 4단계 색상 기준이며, `final_score` 반영과 5단계 등급 규칙 정리는 다음 구현 과제로 유지한다.
- 보류: 저장소 안에서는 다음 세미나 관련 새 전달 사항을 추가로 찾지 못해 기존 "다음 세미나까지 할 일" 항목은 중복 없이 그대로 둔다.

### 2026-07-02

- 확인: `lib/features/main/main_screen.dart`에 검색 패널 열기/닫기, `PlaceSearchService` 기반 `/search/places` 호출, 검색 결과 선택 후 지도 카메라 이동과 출발지/도착지 지정 흐름이 한 화면 상태로 연결돼 있다.
- 완료: `lib/features/map/widgets/search_panel.dart`와 `lib/features/map/service/place_search_service.dart`가 추가되어 장소 검색 입력, 로딩 상태, 결과 목록 선택 UI가 실제 API 호출과 연결됐다.
- 완료: `lib/components/bottom_sheets/guide_bottom_sheet.dart`가 출발지/도착지 좌표 요약, 초기화, 빠른길/안전한길 버튼을 갖춘 길안내 시트로 바뀌었고 `RouteApiService`를 통해 `/route` 호출 트리거가 연결됐다.
- 완료: `lib/features/map/map_screen.dart`는 지도 탭으로 출발지/도착지를 순서대로 선택하고, 선택 마커와 경로 폴리라인을 별도 오버레이로 렌더링하며 검색 결과 좌표로 카메라를 이동시킨다.
- 진행 중: `lib/features/map/service/route_api_service.dart`와 길안내 시트는 빠른길/안전한길 모드 파라미터를 서버로 넘기지만, 두 모드의 실제 분기 기준과 안전 점수 반영 결과는 아직 검증 기록이 없다.
- 진행 중: 도로 오버레이는 여전히 `RoadOverlayService`의 `safety_score` 4단계 색상 기준이며, `final_score` 반영과 5단계 규칙 정리, 시설물 레이어 병행 여부는 남아 있다.
- 보류: 저장소 안에서는 다음 세미나 관련 새 전달 사항을 추가로 찾지 못해 기존 세미나 할 일은 유지하고, 이번에는 빠른길/안전한길 검증 계획만 중복 없이 보강했다.

### 2026-07-08

- 확인: 지난 실행 시각인 2026-07-02 09:47 KST 이후 새 커밋은 없고, 이번 상태 갱신은 현재 워킹트리에 쌓인 인증/문서 수정본을 기준으로 정리했다.
- 완료: `lib/main.dart` 기본 진입 화면이 `LoginScreen`으로 돌아갔고, `lib/features/auth/screen/login_screen.dart`는 로그인 성공 시 `userId`를 `MainScreen`으로 전달하며 비밀번호 찾기 화면 진입 링크도 연결했다.
- 진행 중: `lib/features/auth/screen/password_reset_screen.dart`와 `lib/features/auth/service/auth_service.dart`에 비밀번호 재설정 화면과 `/password-reset` API 호출이 추가됐지만, 입력 필드가 기존 문서의 생년월일 포함 요구와 다르고 서버 계약 검증 기록도 아직 없다.
- 진행 중: `lib/features/auth/screen/profile_edit_screen.dart`, `lib/components/bottom_sheets/more_bottom_sheet.dart`, `lib/features/main/main_screen.dart`에 내 정보 진입, 프로필 조회/수정, 비밀번호 변경, 로그아웃 흐름이 연결됐지만 세션 유지 방식과 실패 케이스 검증은 남아 있다.
- 확인: `docs/WORK_LOG.md`는 계속 삭제 상태이며, 이번에도 별도 복구 없이 `docs/FEATURE_STATUS.md` 한 곳에만 상태 기록을 누적한다.
- 보류: 저장소와 자동화 메모리에서는 다음 세미나까지 해야 할 일에 대한 새 사용자 전달 사항을 찾지 못해 기존 세미나 할 일 목록은 중복 없이 유지했다.

### 2026-07-16

- 확인: 지난 실행 시각인 2026-07-08 23:18 KST 이후에도 새 커밋은 없고, 현재 상태 점검 대상은 동일한 워킹트리 수정본과 문서 변경분이다.
- 확인: `lib/features/main/main_screen.dart`, `lib/features/map/map_screen.dart`, `lib/components/bottom_sheets/guide_bottom_sheet.dart`, `lib/features/map/service/place_search_service.dart`, `lib/features/map/service/route_api_service.dart` 기준 검색 패널, 지도 탭 선택, `/route` 호출, 경로 폴리라인 표시 흐름은 이미 연결된 상태로 유지되고 있으며 이번 점검에서 추가 완료 기능은 확인되지 않았다.
- 진행 중: `lib/features/auth/screen/password_reset_screen.dart`와 `lib/features/auth/screen/profile_edit_screen.dart`는 비밀번호 재설정/프로필 수정 흐름을 제공하지만 라벨과 스낵바 문자열이 일부 깨져 보여 사용자 화면 품질 점검과 파일 인코딩 정리가 추가로 필요하다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`는 여전히 `/roads` 응답의 `safety_score` 4단계 색상 기준으로만 동작하고 있어 `final_score` 반영, 5단계 규칙 정리, 시설물 레이어 병행 여부 검증이 남아 있다.
- 보류: 저장소와 자동화 메모리, 현재 문서에서 다음 세미나 전 해야 할 일에 대한 새 사용자 전달 사항은 추가로 발견되지 않아 기존 "다음 세미나까지 할 일" 목록은 중복 없이 유지한다.

### 2026-07-22

- 확인: 지난 실행 시각인 2026-07-16 20:11 KST 이후에도 새 커밋은 없고, 이번 갱신은 동일 워킹트리에서 새로 확인한 지도 알림 시제품과 문서 정리 범위를 반영했다.
- 완료: `lib/features/map/service/risk_zone_alert_service.dart`가 추가되어 현재 좌표 기준 `/roads/nearest-risk` 조회와 위험 도로 판정 응답을 별도 서비스로 분리했다.
- 진행 중: `lib/features/map/map_screen.dart`는 위치 스트림을 구독해 위험 도로 근접 시 스낵바 알림을 띄우고 중복 알림 쿨다운을 두지만, 아직 진동/푸시 연동과 백그라운드 알림 흐름은 없다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`와 위험 알림 서비스 모두 `safety_score`/`threshold` 기반으로 동작하고 있어 `final_score` 기준 통일과 임계값 검증이 남아 있다.
- 확인: `lib/features/auth/screen/password_reset_screen.dart`와 `lib/features/auth/screen/profile_edit_screen.dart`의 실제 파일 내용은 한글 문자열 기준으로 읽히며, 이번 점검에서는 문서상 "문자열 깨짐" 이슈를 새 진행 항목으로 유지하지 않았다.
- 보류: 저장소와 자동화 메모리, 현재 문서에서 다음 세미나 전 해야 할 일에 대한 새 사용자 전달 사항은 추가로 발견되지 않아 기존 "다음 세미나까지 할 일" 목록을 중복 없이 유지한다.

### 2026-07-30

- 확인: 지난 실행 시각인 2026-07-22 21:19 KST 이후에도 새 커밋은 없고, 이번 갱신 대상은 현재 워킹트리에 누적된 지도 신고 시제품과 위험구역 화면 표시 변경분이다.
- 완료: `lib/features/map/service/nearby_facility_service.dart`가 추가되어 현재 위치 기준 `/facilities/nearby` 조회와 반경 30m 신고 후보 시설물 파싱 로직이 분리됐다.
- 진행 중: `lib/features/map/map_screen.dart`는 시설물 신고 플로팅 버튼, 후보 시설물 마커 렌더링, 시설물 종류/거리 표시, 신고 CTA 바텀시트까지 연결됐지만 실제 신고 작성 화면과 서버 전송은 아직 연결되지 않았다.
- 진행 중: `lib/features/main/main_screen.dart`는 위험 도로 진입 시 전체 화면 경고 테두리와 배너 오버레이를 표시하도록 바뀌었고, 알림 표현은 강화됐지만 진동/푸시 및 백그라운드 처리 검증은 남아 있다.
- 진행 중: `lib/features/map/service/road_overlay_service.dart`와 `lib/features/map/service/risk_zone_alert_service.dart`는 여전히 `safety_score`/`threshold` 기준이라 `final_score` 반영, 5단계 안전 등급, 경로 점수와의 기준 통일이 다음 과제로 남아 있다.
- 보류: 저장소와 자동화 메모리, 현재 문서에서 다음 세미나 전 해야 할 일에 대한 새 사용자 전달 사항은 추가로 발견되지 않아 기존 "다음 세미나까지 할 일" 목록을 중복 없이 유지한다.
