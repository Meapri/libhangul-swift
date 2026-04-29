# libhangul-swift

기존 C 언어 기반 `libhangul`의 구조와 로직을 순수 Swift로 재구현한 한글 입력 코어 엔진입니다. 브릿징(Bridging) 및 포인터 연산을 배제하여 Apple 플랫폼(macOS, iOS, iPadOS)에서 네이티브로 안전하게 구동되도록 설계되었습니다.

## 핵심 아키텍처 및 특징

### 1. Pure Swift 구현 및 호환성
C/Objective-C 라이브러리 의존성 없이 작성되어, 패키지 추가만으로 macOS `InputMethodKit` 및 iOS 커스텀 키보드 Extension에 즉시 통합할 수 있습니다. 메모리 누수나 크래시 발생 가능성을 언어 레벨에서 차단했습니다.

### 2. 스레드 동기화 및 성능 (OSAllocatedUnfairLock)
입력기의 실시간(Real-time) 응답성을 보장하기 위해, 상태 관리에 `OSAllocatedUnfairLock`을 도입했습니다. 비동기(Async/Await) 컨텍스트 스위칭으로 인한 오버헤드를 방지하면서도, 멀티스레드 환경에서 발생할 수 있는 데이터 경합(Data Race)을 안전하게 제어합니다.

### 3. Trie 기반 고속 한자 검색
전통적인 해시맵 대신 Prefix Tree(Trie) 자료구조를 적용했습니다. 접두어 기반 매칭(`matchPrefix`)을 통해 O(m)의 시간 복잡도로 수만 개의 한자 후보군을 탐색합니다. 또한 한자 DB를 메모리에 한 번에 올리지 않고 `String.enumerateLines`를 활용해 스트림 방식으로 파싱하여, 엔진 초기화에 소모되는 메모리와 시간을 최적화했습니다.

### 4. 타입 안정성 (Type-Safety) 강제
정수형 키 코드를 사용하는 대신, `KeyInput.character("r")` 또는 `KeyInput.keyCode(51)`과 같이 명시적인 열거형 타입을 사용합니다. 입력값의 유효성을 컴파일 타임에 검증하여 오류를 방지합니다.

### 5. 유니코드 오토마타 및 정규화
- **`HangulBuffer` & `HangulCharacter`**: 초·중·종성 결합 법칙(Conjoinability)을 상태 머신(Automata)으로 제어하며, 완성형 및 조합형 유니코드 문자를 합성합니다.
- **NFD/NFC 교정**: macOS와 Windows 간에 발생하는 유니코드 정규화(Normalization) 방식 차이로 인한 텍스트 깨짐 현상을 코어 레벨에서 보정합니다.

## 지원 자판 배열

| ID | 분류 | 설명 |
| :--- | :--- | :--- |
| `2` | **두벌식** | 표준 QWERTY 기반 두벌식 자판 (기본값) |
| `3` | **세벌식 390** | 세벌식 390 배열 |
| `2y` / `3y` | **옛한글** | 제주어 및 고문서 작성을 위한 옛한글 조합 매핑 |

## 시작하기

### Swift Package Manager 설치

프로젝트의 `Package.swift`에 아래 의존성을 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

### 사용 예시

```swift
import LibHangul

// 1. 스레드 안전 컨텍스트 활성화 (두벌식)
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 2. 키보드 입력 이벤트 처리 ('ㄱ', 'ㅏ', 'ㄱ')
_ = context.process(KeyInput.character("r"))
_ = context.process(KeyInput.character("k"))
_ = context.process(KeyInput.character("r"))

// 3. 현재 조합 중인 임시 문자열 반환 ("각")
let markedText = context.getPreeditString() 

// 4. 조합을 종료하고 최종 텍스트 확정
let committedText = context.flush()
```

## 라이선스

이 프로젝트는 **MIT 라이선스**로 배포됩니다.
