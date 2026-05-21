# WMS 범죄주의구간 기반 도로 안전 점수 계획

작성일: 2026-05-13

이 문서는 다른 Codex 세션이나 Codex 앱 새 채팅에서 현재 작업 맥락을 이어가기 위한 설계 메모다.
아직 구현하지 않고, `crime_wms.png` 기반 위험 감점 기능을 어떤 방식으로 붙일지 정리한다.

## 프로젝트 맥락

이 프로젝트는 아동을 위한 야간 안심 보행 플랫폼이다.

핵심 목표는 단순 시설물 마커 표시가 아니라, 도로 구간별 안전도를 계산해서 지도 위 도로 선 색상과 안심 경로 탐색에 반영하는 것이다.

현재 주요 구조:

- Flutter 앱: `night_safe_walk`
- Flask 서버: `safe-walk-server`
- DB: PostgreSQL/PostGIS
- 지도: 네이버 지도 Flutter SDK

현재 앱에는 도로 오버레이 전용 파일이 있다.

- `night_safe_walk/lib/features/map/service/road_overlay_service.dart`

현재 서버에는 테스트용 도로 API가 있다.

- `safe-walk-server/app.py`
- `/roads/sample`

## 현재 DB 확인 결과

사용자가 의도한 최종 도로 그래프 테이블:

```text
osm_edges
```

컬럼:

```text
edge_id
source_node_id
target_node_id
length_m
geom
safety_score
cost
```

확인된 특이사항:

- `osm_edges.geom`: SRID 4326, LINESTRING
- 현재 로컬 DB 기준 `osm_edges` 행 수는 0건이었다.
- 실제 OSM 도로 데이터가 들어 있는 테이블은 `road_edges_cheongju`였다.
- `road_edges_cheongju` 행 수는 약 43,467건이었다.
- `road_edges_cheongju.geom`: SRID 3857, LINESTRING
- `road_edges_cheongju` 컬럼은 `osm_id`, `name`, `highway`, `geom`이다.

따라서 현재 테스트용 도로 표시는 `road_edges_cheongju`를 쓰고, 최종 안전 점수/경로 탐색용 구조는 `osm_edges`를 채운 뒤 그쪽을 기준으로 가는 것이 자연스럽다.

## 구현하고 싶은 기능

생활안전지도 범죄주의구간 WMS 이미지를 `crime_wms.png`로 저장해둔다.

그 다음 도로별로 다음 과정을 수행한다.

1. 도로 `geom`을 10~20개 샘플점으로 나눈다.
2. 각 샘플점을 EPSG:3857 좌표로 변환한다.
3. EPSG:3857 좌표를 `crime_wms.png`의 픽셀 좌표로 변환한다.
4. 해당 픽셀 색상이 빨강, 주황, 노랑 계열인지 판정한다.
5. 위험 색상에 따라 감점값을 계산한다.
6. 기존 `safety_score`에서 감점을 반영해 `final_score`를 계산한다.
7. 앱의 도로 색상 표시와 경로 탐색 비용 계산에 활용한다.

## 중요한 전제

`crime_wms.png`만으로는 좌표 변환이 불가능하다.

반드시 아래 메타데이터가 함께 필요하다.

```text
CRS: EPSG:3857
BBOX: minx, miny, maxx, maxy
WIDTH: 이미지 너비 px
HEIGHT: 이미지 높이 px
```

픽셀 좌표 변환 공식:

```text
pixel_x = (x - minx) / (maxx - minx) * image_width
pixel_y = (maxy - y) / (maxy - miny) * image_height
```

`pixel_y`는 이미지 좌상단이 0이므로 위아래 방향을 뒤집어 계산한다.

## 색상 판정 초안

초기에는 RGB 기준으로 단순 판정한다.

예시:

```text
red    -> -20
orange -> -15
yellow -> -10
none   -> 0
```

도로 하나에서 여러 샘플점이 위험 색상에 걸릴 경우, 초기 버전은 가장 큰 감점을 적용한다.

아동 야간 보행 서비스에서는 도로 일부라도 위험 구간이면 피하는 방향이 더 안전하기 때문이다.

## 방식 1: 전처리 스크립트로 한 번 계산

서버의 `scripts` 폴더에 계산 스크립트를 두는 방식이다.

예상 파일:

```text
safe-walk-server/scripts/calculate_crime_wms_scores.py
```

처리 흐름:

1. `crime_wms.png` 읽기
2. WMS BBOX 메타데이터 읽기
3. `osm_edges` 또는 `road_edges_cheongju` 조회
4. 도로마다 10~20개 샘플점 생성
5. 샘플점 좌표를 EPSG:3857로 맞춤
6. 픽셀 색상 판정
7. `crime_penalty`, `final_score` 계산
8. 결과 CSV 또는 별도 캐시 테이블로 저장

필요 패키지:

```text
Pillow
psycopg2
numpy 선택
pandas 선택
```

DB 쿼리 방향:

`osm_edges` 기준:

```sql
SELECT edge_id, safety_score, geom
FROM osm_edges;
```

현재 테스트 데이터 기준:

```sql
SELECT osm_id, geom
FROM road_edges_cheongju;
```

장점:

- 서버 API 요청 시 계산 부담이 없다.
- 전체 도로에 대해 한 번 계산하고 검수하기 좋다.
- 결과가 재현 가능하다.
- 앱은 이미 계산된 `final_score`만 받아 색상 표시하면 된다.

단점:

- WMS 이미지가 바뀌면 다시 계산해야 한다.
- 계산 결과 저장 위치를 정해야 한다.
- 초기에 스크립트와 메타데이터 관리 구조가 필요하다.

앱 연결:

- `/roads` API가 `final_score`를 포함해 도로 좌표를 반환한다.
- Flutter는 `final_score` 범위에 따라 `NPathOverlay` 색상을 바꾼다.

## 방식 2: Flask API에서 실시간 계산

앱이 도로를 요청할 때 Flask가 해당 bounds 안의 도로를 조회하고, 그 자리에서 WMS 픽셀을 검사해 `final_score`를 계산하는 방식이다.

처리 흐름:

1. Flutter가 현재 화면 bounds 전송
2. Flask가 bounds 안 도로 조회
3. 각 도로를 샘플링
4. `crime_wms.png` 픽셀 색상 검사
5. 즉시 `final_score` 계산 후 응답

필요 패키지:

```text
Pillow
psycopg2
numpy 선택
```

DB 쿼리 방향:

```sql
SELECT edge_id, safety_score, geom
FROM osm_edges
WHERE geom && ST_MakeEnvelope(...);
```

`road_edges_cheongju`는 SRID 3857이므로 bounds를 3857로 변환해서 조회해야 한다.

장점:

- DB 컬럼을 바로 추가하지 않아도 된다.
- 현재 화면 범위만 계산하므로 작은 테스트에 빠르게 쓸 수 있다.
- WMS 이미지를 바꾸면 바로 결과가 달라진다.

단점:

- 지도를 움직일 때마다 계산해서 서버 부담이 크다.
- 같은 도로를 반복 계산할 수 있다.
- 나중에 경로 탐색 비용 계산에는 비효율적이다.
- 사용자 체감 속도가 느려질 수 있다.

앱 연결:

- 기존 `road_overlay_service.dart`가 `/roads` API를 호출한다.
- 응답의 `final_score`에 따라 선 색상을 정한다.

## 방식 3: 캐시 파일 또는 별도 결과 테이블 사용

계산은 전처리 스크립트로 수행하고, 결과만 별도 저장소에 남기는 방식이다.

예상 결과 형태:

```text
edge_id, safety_score, crime_penalty, final_score
1, 70, 15, 55
2, 85, 0, 85
```

저장 방식 후보:

- CSV 파일
- JSON 파일
- 별도 DB 테이블, 예: `road_risk_scores`

초기 단계에서는 CSV가 가장 안전하다.

필요 패키지:

```text
Pillow
pandas
psycopg2
```

DB 쿼리 방향:

계산 스크립트:

```sql
SELECT edge_id, safety_score, geom
FROM osm_edges;
```

서버 API:

```sql
SELECT
  e.edge_id,
  e.geom,
  e.safety_score,
  r.crime_penalty,
  r.final_score
FROM osm_edges e
LEFT JOIN road_risk_scores r ON e.edge_id = r.edge_id
WHERE e.geom && ...
```

CSV 캐시를 쓸 경우 Flask가 CSV를 메모리에 로드해서 `edge_id` 기준으로 매칭할 수 있다.

장점:

- 원본 `osm_edges`를 바로 수정하지 않는다.
- 계산 결과를 눈으로 검수하기 쉽다.
- 앱/서버 응답이 빠르다.
- 나중에 DB 컬럼 추가 여부를 천천히 결정할 수 있다.

단점:

- 캐시 파일 또는 결과 테이블 관리가 필요하다.
- 도로 데이터가 바뀌면 캐시를 다시 만들어야 한다.
- `edge_id`가 안정적으로 유지되어야 한다.

앱 연결:

- `/roads` API가 `final_score`를 포함해 반환한다.
- Flutter는 점수별 색상만 적용한다.

## 방식 4: PostGIS가 샘플점을 만들고 Python이 색상만 판정

샘플점 생성과 좌표계 변환은 PostGIS가 담당하고, Python은 픽셀 색상 판정과 점수 계산만 맡는 혼합 방식이다.

DB 쿼리 방향:

```sql
SELECT
  edge_id,
  safety_score,
  ST_X(sample_point) AS x,
  ST_Y(sample_point) AS y
FROM ...
```

`ST_LineInterpolatePoint`를 사용해 도로 위 샘플점을 만든다.

장점:

- 공간 연산은 PostGIS가 처리하므로 정확하다.
- Python 코드가 단순해진다.
- 대량 계산에 비교적 안정적이다.

단점:

- SQL이 복잡해진다.
- 샘플점 개수 조절 로직을 잘 설계해야 한다.
- 초기에 디버깅 난이도가 조금 있다.

## 현재 단계에서 추천 방식

현재 프로젝트 단계에서는 **방식 3: 전처리 스크립트 계산 + 캐시 결과 저장**을 추천한다.

추천 이유:

- 아직 WMS 픽셀 색상 판정 기준을 검증해야 한다.
- `osm_edges`를 바로 UPDATE하지 않는 조건과 잘 맞는다.
- `final_score`가 합리적인지 CSV로 먼저 확인할 수 있다.
- 앱은 이미 도로 오버레이 구조가 분리되어 있어서 결과만 연결하면 된다.
- 나중에 경로 탐색 `cost` 계산으로 확장하기 쉽다.

## 권장 다음 작업 순서

1. `crime_wms.png`의 저장 위치와 BBOX 메타데이터를 확정한다.
2. 계산 대상 도로 테이블을 확정한다.
   - 최종: `osm_edges`
   - 현재 테스트: `road_edges_cheongju`
3. 도로별 샘플점 10~20개 생성 방식을 정한다.
4. WMS 픽셀 색상 판정 기준을 작은 도로 샘플로 검증한다.
5. `edge_id`, `crime_penalty`, `final_score` 형태의 CSV 캐시를 만든다.
6. Flask `/roads` API가 `final_score`를 반환하도록 확장한다.
7. Flutter `road_overlay_service.dart`에서 점수별 색상을 적용한다.
8. 검증 후 별도 테이블 또는 `osm_edges` 반영 여부를 결정한다.

## 새 채팅에서 이어가기 위한 요약

새 Codex 채팅에서는 이 파일을 먼저 읽고 다음처럼 이어가면 된다.

```text
night_safe_walk/docs/ROAD_SAFETY_WMS_SCORING_PLAN.md 파일을 기준으로,
crime_wms.png 기반 도로 위험 감점 계산을 이어서 설계/구현해줘.
아직은 DB UPDATE 없이 CSV 캐시 방식부터 진행하고 싶어.
```
