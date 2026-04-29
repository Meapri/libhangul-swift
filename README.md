# libhangul-swift

C 기반 libhangul의 조합 로직과 자료구조를 순수 Swift로 재구현한 한글 입력 코어 엔진. C/Objective-C 브릿징 없이 동작하며, SPM 패키지 추가만으로 macOS, iOS, visionOS에서 사용할 수 있다.

## 모듈 구성

```
Sources/LibHangul/
├── LibHangul.swift                      # 팩토리 함수 (createInputContext 등)
├── HangulInputContext.swift             # 조합 상태 머신 (메인 엔진)
├── ThreadSafeHangulInputContext.swift   # OSAllocatedUnfairLock 기반 스레드 안전 래퍼
├── HangulBuffer.swift                   # 초·중·종성 조합 버퍼
├── HangulCharacter.swift                # 유니코드 한글 연산 (결합, 분리, 자모 변환)
├── HangulKeyboard.swift                 # 자판 배열 매핑 (두벌식, 세벌식 등)
├── HangulScalar.swift                   # UCSChar(UInt32) 유틸리티
├── Hanja.swift                          # 한자 사전 파서 및 HanjaTable
├── HanjaTrie.swift                      # Sorted Array + Binary Search Trie
├── KeyInput.swift                       # 타입 안전 키 입력 열거형
├── Logging.swift                        # 내부 디버그 로거
└── Examples.swift                       # 사용 예시 코드
```

### 주요 타입

| 타입 | 역할 |
|---|---|
| **`HangulInputContext`** | 한글 조합의 핵심 상태 머신. 키 입력을 받아 초·중·종성을 조합하고 preedit/commit 문자열을 생성한다. 자판 배열, 출력 모드, 버퍼 크기 등의 옵션을 관리한다. |
| **`ThreadSafeHangulInputContext`** | `HangulInputContext`를 `OSAllocatedUnfairLock`으로 감싼 스레드 안전 래퍼. 모든 public 메서드가 동기적(synchronous)이므로 InputMethodKit의 동기 콜백에서 직접 사용할 수 있다. `@unchecked Sendable`을 채택한다. |
| **`HangulBuffer`** | 초성·중성·종성 슬롯을 관리하는 조합 버퍼. 결합 가능 여부(Conjoinability)를 판정하고 완성형 음절을 합성한다. |
| **`HangulCharacter`** | 유니코드 한글 블록 연산. 초·중·종성 인덱스 추출/합성, 호환 자모(Compatibility Jamo, U+3130~U+318F)와 조합 자모(U+1100~U+11FF) 간 변환, NFC/NFD 정규화를 처리한다. |
| **`HangulKeyboard`** | 물리 키 코드를 한글 자모로 매핑하는 자판 정의. `HangulKeyboardManager`가 `"2"`, `"3"`, `"2y"`, `"3y"` 등의 ID로 관리한다. |
| **`KeyInput`** | 키 입력을 `.character("r")`, `.keyCode(51)`, `.backspace` 형태로 표현하는 타입 안전 열거형. 정수형 키 코드 사용 시 발생하는 오류를 컴파일 타임에 방지한다. |
| **`HanjaTable`** | 한자 사전 로더. 텍스트 파일을 `String.enumerateLines`로 스트림 파싱하여 `HanjaTrie`에 적재한다. `matchExact(key:)`와 `matchPrefix(key:)` 검색을 제공한다. |
| **`HanjaTrie`** | Sorted Array + Binary Search 기반 Trie. 자식 노드를 `[TrieChildEntry]` 단일 배열로 관리하여 노드당 힙 할당을 절반으로 줄였다. 검색 시간 복잡도는 O(m × log k), m=키 길이, k=자식 수. |

## 동기화 방식

`ThreadSafeHangulInputContext`는 `OSAllocatedUnfairLock`을 사용한다.

- InputMethodKit의 `handle()`, `activateServer()` 등은 동기 반환을 요구하므로 `async/await`(Actor)를 사용할 수 없다.
- `NSLock`보다 오버헤드가 낮고, Swift 6에서 공식 권장하는 동기화 메커니즘이다.
- 모든 상태 변경(`process`, `flush`, `reset`, `setKeyboard`)이 lock 스코프 내에서 수행된다.

## 지원 자판

| ID | 이름 | 설명 |
|---|---|---|
| `"2"` | 두벌식 표준 | QWERTY 기반 두벌식 (기본값) |
| `"3"` | 세벌식 390 | 세벌식 390 배열 |
| `"2y"` | 두벌식 옛한글 | 옛한글 자모 조합 |
| `"3y"` | 세벌식 옛한글 | 옛한글 자모 조합 |

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

타깃 의존성:
```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "LibHangul", package: "libhangul-swift")
    ]
)
```

## 사용 예시

### 기본 조합

```swift
import LibHangul

let context = ThreadSafeHangulInputContext(keyboard: "2")

// 'ㄱ' + 'ㅏ' + 'ㄱ' → "각"
context.process(Character("r"))  // ㄱ
context.process(Character("k"))  // ㅏ → preedit: "가"
context.process(Character("r"))  // ㄱ → preedit: "각"

let preedit = context.getPreeditString()   // [44033] (각)
let committed = context.flush()            // [44033]
```

### 한자 검색

```swift
let table = HanjaTable()
table.load(filename: "hanja.txt")

if let results = table.matchExact(key: "가") {
    for i in 0..<results.getSize() {
        if let entry = results.getNth(i) {
            print("\(entry.getValue()) - \(entry.getComment())")
            // 可 - 옳을 가
            // 加 - 더할 가
            // ...
        }
    }
}
```

### 배치 처리

```swift
let context = ThreadSafeHangulInputContext(keyboard: "2")
let results = context.processBatch([114, 107, 114])  // r, k, r
// results: [HangulInputResult] - 각 키의 처리 결과와 preedit/commit 상태
```

## 플랫폼

| 플랫폼 | 최소 버전 |
|---|---|
| macOS | 14.0 |
| iOS | 17.0 |
| tvOS | 17.0 |
| watchOS | 10.0 |
| visionOS | 1.0 |

Swift 6, Strict Concurrency 모드로 컴파일된다.

## 라이선스

MIT License
