# Hive 쿼리 최적화 및 활용 가이드 (Flutter)

## 1. Hive의 인덱스 개념

-   Hive는 RDBMS처럼 인덱스를 지원하지 않음
-   모든 쿼리는 메모리 내에서 반복문/필터링으로 처리됨
-   대용량 데이터는 성능 저하가 발생할 수 있으므로, 필요한 데이터만 저장/조회하는 구조 설계가 중요

## 2. 필터링(검색) 패턴

-   `box.values.where((e) => 조건)` 형태로 필터링
-   자주 쓰는 조건은 별도의 Map/Set 등으로 캐싱하거나, 박스를 분리하여 관리

### 예시 코드

```dart
// 특정 날짜의 Action만 조회
final actions = box.values.where((a) => a.date == targetDate).toList();

// 특정 카테고리의 Action만 조회
final actions = box.values.where((a) => a.categoryId == 'cat1').toList();
```

## 3. 정렬 패턴

-   `box.values.toList()..sort((a, b) => a.date.compareTo(b.date))` 형태로 정렬
-   정렬 후 UI에 전달

### 예시 코드

```dart
final sortedActions = box.values.toList()
  ..sort((a, b) => a.date.compareTo(b.date));
```

## 4. 대용량 데이터 처리

-   1만 건 이상 데이터는 메모리 사용량/속도에 주의
-   페이징, 검색어 기반 필터, 최근 데이터만 로딩 등으로 최적화
-   필요시 박스를 여러 개로 분리(예: 월별, 카테고리별 등)

## 5. 박스 분할/구조 설계 팁

-   자주 조회하는 단위로 박스를 분할하면 성능 개선
-   예: 월별 Action 박스, 카테고리별 Notification 박스 등

## 6. 기타 활용 팁

-   값이 자주 바뀌는 데이터는 Hive 대신 provider, riverpod 등 상태관리와 조합 사용 고려
-   박스 내 데이터가 많을수록 쿼리 속도 저하 → 필요한 데이터만 저장/조회

## 7. 한계점 및 주의사항

-   복잡한 쿼리(조인, 집계 등)는 불가 → 앱 단에서 직접 구현 필요
-   대용량 데이터는 SQLite 등 다른 DB와 혼용 고려

## 8. 참고

-   공식 문서: https://docs.hivedb.dev/#/queries/queries
-   실무에서는 박스 구조 설계와 데이터 양 관리가 핵심
