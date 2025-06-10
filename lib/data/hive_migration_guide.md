# Hive 마이그레이션 전략 및 주의사항 (Flutter)

## 1. typeId는 절대 변경하지 않는다

-   한 번 배포된 모델의 `@HiveType(typeId: X)`에서 typeId는 절대 변경하면 안 됨
-   typeId가 바뀌면 기존 데이터와 호환되지 않아 앱이 크래시되거나 데이터가 손실됨

## 2. 필드 추가 시

-   새로운 필드는 `@HiveField(가장 큰 번호 + 1)`로 추가
-   기존 필드의 번호는 절대 변경/삭제하지 않음
-   새 필드는 생성자에서 `required` 대신 `this.newField = defaultValue` 등으로 기본값 처리 권장

## 3. 필드 삭제 시

-   @HiveField 번호만 남기고 실제 필드/생성자에서 사용하지 않음(번호는 유지)
-   기존 데이터와의 호환성을 위해 번호를 재사용하지 않음

## 4. 필드 타입 변경 시

-   타입 변경은 권장하지 않음(기존 데이터와 충돌 가능)
-   꼭 필요하다면, 새로운 필드로 추가 후 마이그레이션 로직(데이터 변환) 구현

## 5. Adapter 버전 관리

-   모델 변경 후에는 반드시 `build_runner`로 어댑터 재생성
    ```
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## 6. 박스 이름 변경 금지

-   기존에 사용하던 박스 이름(`Hive.openBox('boxName')`)은 변경하지 않음

## 7. 마이그레이션이 필요한 경우

-   데이터 변환이 필요한 경우, 앱 실행 시 박스 오픈 후 데이터 변환 로직을 직접 구현해야 함
-   예시: 새 필드 추가 후, 기존 데이터에 대해 기본값을 할당하는 코드 작성

---

## 예시 코드: 새 필드 추가 후 마이그레이션

```dart
// 예시: Action 모델에 'isActive' 필드 추가
@HiveType(typeId: 0)
class Action extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  bool isActive; // 새 필드 추가

  Action({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isActive = true, // 기본값 처리
  });
}

// 마이그레이션 코드 예시
void migrateActionBox(Box<Action> box) {
  for (var action in box.values) {
    if (action.isActive == null) {
      action.isActive = true;
      action.save();
    }
  }
}
```

---

## 참고

-   공식 문서: https://docs.hivedb.dev/#/migration/migration
-   실무에서는 typeId/필드 번호 관리에 각별히 주의할 것
