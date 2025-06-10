# Hive 박스 관리 및 오류 처리 가이드 (Flutter)

## 1. 박스 오픈/클로즈 관리

-   박스는 앱 시작 시 한 번만 오픈하고, 앱 종료 시 닫는 것이 일반적
-   여러 번 `Hive.openBox()`를 호출하면 중복 오픈 예외가 발생할 수 있음
-   이미 오픈된 박스는 `Hive.isBoxOpen('boxName')`으로 확인 후 재사용

### 예시 코드

```dart
Future<Box<T>> openBoxSafe<T>(String name) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<T>(name);
  } else {
    return await Hive.openBox<T>(name);
  }
}
```

## 2. 박스 예외 처리 패턴

-   박스 오픈/읽기/쓰기 시 try-catch로 예외를 반드시 처리
-   대표적인 예외: Box not found, Box already open, HiveError, 데이터 손상 등

### 예시 코드

```dart
try {
  var box = await openBoxSafe<Action>('actions');
  // 데이터 사용
} catch (e) {
  // 예외 로깅 및 사용자 알림
  print('Hive 오류 발생: $e');
}
```

## 3. 데이터 손상 복구

-   박스 파일이 손상되면 HiveError가 발생하며, 앱이 크래시될 수 있음
-   복구 방법: 손상된 박스 파일 삭제 후 재생성(데이터 복구 불가, 사용자 동의 필요)

### 예시 코드

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> recoverCorruptedBox(String boxName) async {
  final dir = await getApplicationDocumentsDirectory();
  final boxFile = File('${dir.path}/$boxName.hive');
  if (await boxFile.exists()) {
    await boxFile.delete();
  }
  await Hive.openBox(boxName); // 새로 생성
}
```

## 4. 안전한 Hive 사용을 위한 팁

-   박스 이름, typeId, 필드 번호 등은 상수/enum으로 관리
-   박스 오픈/클로즈는 앱 라이프사이클에 맞게 한 번만 수행
-   데이터 저장/조회 시 항상 예외 처리
-   박스가 이미 오픈된 상태에서 또 오픈하지 않도록 주의
-   박스가 null이거나 닫힌 상태에서 접근하지 않도록 체크

## 5. 참고

-   공식 문서: https://docs.hivedb.dev/#/usage/boxes
-   HiveError 종류: https://pub.dev/documentation/hive/latest/hive/HiveError-class.html
