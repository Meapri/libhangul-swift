# 시작하기

LibHangul 라이브러리 사용 방법을 알아봅니다.

## 설치

### Swift Package Manager

`Package.swift`에 다음을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", from: "3.0.0")
]
```

## 기본 사용법

### 1. 입력 컨텍스트 생성

```swift
import LibHangul

// 두벌식 키보드로 생성
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 세벌식 390으로 생성
let context3 = LibHangul.createThreadSafeInputContext(keyboard: "3")
```

### 2. 키 입력 처리

```swift
// ASCII 키 코드로 입력
_ = context.process(Int(Character("r").asciiValue!)) // ㄱ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ
_ = context.process(Int(Character("s").asciiValue!)) // ㄴ

// 현재 조합 중인 문자열
let preedit = context.getPreeditString()
print(String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) }))
// 출력: "간"
```

### 3. 입력 확정

```swift
// 조합 완료 후 확정
let committed = context.flush()
print(String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) }))
// 출력: "간"
```

### 4. 백스페이스

```swift
// 마지막 자모 삭제
_ = context.backspace()
```

## 키보드 레이아웃

| ID | 이름 | 설명 |
|----|------|------|
| `"2"` | 두벌식 | 표준 두벌식 자판 (기본값) |
| `"3"` | 세벌식 390 | 세벌식 390 자판 |
| `"2y"` | 두벌식 옛한글 | 옛한글 입력용 |
| `"3y"` | 세벌식 옛한글 | 옛한글 입력용 |

## 스레드 안전성

`ThreadSafeHangulInputContext`는 NSLock 기반으로 스레드 안전합니다.
멀티스레드 환경에서 안전하게 사용할 수 있습니다.

```swift
let context = LibHangul.createThreadSafeInputContext()

DispatchQueue.concurrentPerform(iterations: 100) { _ in
    _ = context.process(Int(Character("r").asciiValue!))
    _ = context.flush()
}
```
