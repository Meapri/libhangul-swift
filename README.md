# libhangul-swift

**C의 한계를 극복한 100% Pure Swift 고성능 한글 입력 엔진**

`libhangul-swift`는 수십 년간 널리 쓰여온 C 기반 `libhangul`의 복잡한 포인터 로직과 레거시를 과감히 버리고, Apple 생태계에 가장 완벽하게 최적화된 형태로 재탄생시킨 차세대 한글 입력 코어 엔진입니다. macOS, iOS, iPadOS 등 플랫폼을 가리지 않고 최고 수준의 속도와 안정성으로 한글 조합을 처리합니다.

---

## 🚀 왜 libhangul-swift인가요?

### 1. C 의존성 제로, 100% 네이티브 Swift
기존 한글 입력기 개발자들은 C 라이브러리를 브릿징(Bridging)하며 메모리 누수와 크래시에 시달려야 했습니다.
- **포인터 해방**: `libhangul-swift`는 단 한 줄의 C 코드나 불안정한 포인터 연산 없이, 오직 Swift만으로 처음부터 끝까지 새로 작성되었습니다.
- **어디서든 즉시 사용**: 패키지 하나만 추가하면 macOS의 `InputMethodKit`은 물론 iOS의 커스텀 키보드 Extension에서도 즉시 네이티브 수준의 한글 엔진을 탑재할 수 있습니다.

### 2. 한 치의 오차도 없는 동기화 (Zero-Cost Abstraction)
입력기는 0.01초의 지연(Latency)도 용납되지 않는 극한의 실시간 소프트웨어입니다.
- **초고속 UnfairLock 도입**: 최신 Swift 6의 강력한 동시성 모델(Strict Concurrency)을 완벽히 지원하면서도, 비동기(Async) 큐 변환 과정에서 발생하는 스위칭 오버헤드를 막기 위해 `OSAllocatedUnfairLock`을 깊숙이 적용했습니다.
- 멀티스레드 환경에서 데이터가 꼬이는 일(Data Race)을 물리적으로 차단하면서, 기존 C 함수처럼 **즉각적이고 동기적인(Synchronous) 응답**을 보장합니다.

### 3. 더 똑똑하고 거침없는 한자 엔진
수만 개가 넘는 한자 사전을 매번 뒤지는 것은 매우 무거운 작업입니다.
- **Trie 기반 초고속 검색**: 구형 해시맵 구조의 한계를 부수고 Prefix Tree(Trie) 자료구조를 자체 설계했습니다. 접두어 기반 매칭(`matchPrefix`)에서 O(m)의 압도적인 속도로 수천 개의 한자 후보군을 즉각 뽑아냅니다.
- **메모리 스트리밍 파싱**: 거대한 한자 DB를 메모리에 무식하게 얹지 않고, `String.enumerateLines`를 활용해 스트림 방식으로 지능적으로 파싱하여 앱의 초기 실행 속도를 획기적으로 낮췄습니다.

### 4. 컴파일 타임에 버그를 잡는 타입 안정성
더 이상 '알 수 없는 Int 코드 값' 때문에 런타임 크래시를 겪지 마세요.
- 모호한 정수형 키 코드를 버리고 `KeyInput.character("r")`나 `KeyInput.keyCode(51)`과 같이 명시적인 타입(Type-Safety)을 강제합니다. 키보드의 어떤 물리적 입력을 넘겨도 컴파일러가 먼저 검증합니다.

---

## 💻 시작하기 (Getting Started)

### SPM (Swift Package Manager) 통합
프로젝트의 `Package.swift`에 단 한 줄만 추가하면 준비가 끝납니다.

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

### 압도적으로 쉬운 사용법
단 4줄의 코드로 당신의 앱에 완벽한 한글 조합 시스템을 이식하세요.

```swift
import LibHangul

// 1. 최고 성능의 스레드 안전 컨텍스트 활성화 (두벌식)
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 2. 키보드 입력 전달 ('ㄱ', 'ㅏ', 'ㄱ')
_ = context.process(KeyInput.character("r"))
_ = context.process(KeyInput.character("k"))
_ = context.process(KeyInput.character("r"))

// 3. 실시간 조합 화면 출력 (화면에 "각" 표시)
let markedText = context.getPreeditString() 

// 4. 조합 끝! 텍스트 확정
let committed = context.flush()
```

---

## 🛠 지원 자판 및 아키텍처

| ID | 지원 자판 | 설명 |
| :--- | :--- | :--- |
| `2` | **두벌식** | 표준 QWERTY 기반 두벌식 (기본값) |
| `3` | **세벌식 390** | 빠르고 리듬감 있는 세벌식 390 |
| `2y` / `3y` | **옛한글 (고어)** | 제주어 및 고문서 작성을 위한 옛한글 조합 매핑 |

- **`HangulBuffer` & `HangulCharacter`**: 초·중·종성의 결합 법칙(Conjoinability) 오토마타를 제어하며 완벽한 유니코드(`UCSChar`)합성을 수행합니다.
- **크로스 플랫폼 유니코드 정규화**: 파일 이름이 깨지는 고질적인 Mac-Windows 간의 NFD/NFC 정규화 차이를 코어단에서 매끄럽게 교정합니다.

---

## ⚖️ 라이선스 (License)

이 프로젝트는 **MIT 라이선스**로 배포됩니다.
오픈소스로서 누구나 자유롭게 사용, 수정, 배포할 수 있습니다.
