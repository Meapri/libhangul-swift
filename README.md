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
├── HangulKeyboardLoader.swift           # 자판/조합 XML 데이터 기반 로더 (Bundle.module)
├── HangulCombination.swift              # 자모 결합 규칙 테이블 (현대/옛한글)
├── Resources/keyboards/*.xml            # libhangul 호환 자판·조합 데이터 (번들 리소스)
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

자판 배열과 자모 결합 규칙은 `Sources/LibHangul/Resources/keyboards/*.xml`(libhangul 호환)에서 로드된다. 이 디렉터리가 자판 데이터의 단일 출처이며, SPM 리소스로 번들되어 의존성으로 사용할 때도 `Bundle.module`에서 읽는다.

| ID | 이름 | 타입 | 설명 |
|---|---|---|---|
| `"2"` | 두벌식 | jamo | QWERTY 기반 두벌식 (기본값, 레거시 내장) |
| `"3"` | 세벌식 390 | jaso | 레거시 내장 |
| `"39"` | 세벌식 390 | jaso | 데이터 기반 |
| `"3f"` | 세벌식 최종 | jaso | 데이터 기반 |
| `"32"` | 세벌식 두벌 배열 | jaso | 데이터 기반 |
| `"3s"` | 세벌식 순아래 | jaso | 데이터 기반 |
| `"ahn"` | 안마태 | jaso | 데이터 기반 |
| `"ro"` | 로마자 | romaja | 다중 글자 로마자 처리 (예: `annyeonghaseyo`→안녕하세요) |
| `"2y"` | 두벌식 옛한글 | jamo-yet | 옛한글 자모 조합 지원 (full 결합 규칙) |
| `"3y"` | 세벌식 옛한글 | jaso-yet | 옛한글 자모 조합 지원 (full 결합 규칙) |

옛한글(`"2y"`/`"3y"`)은 `hangul-combination-full.xml`(352개 규칙)을 사용해 임의 자모 클러스터(예: ㄱ+ㄷ→ᄓ)와 아래아(ㆍ) 등 옛한글 음절을 조합한다. 완성형으로 합성되지 않는 음절은 조합용 자모(U+1100~)로 출력된다.

```swift
let yet = HangulInputContext(keyboard: "2y")
yet.process(Character("r"))   // ㄱ
yet.process(Character("e"))   // ㄷ → 초성 클러스터 ᄓ (U+115A)
```

로마자(`"ro"`)는 libhangul의 `hangul_ic_process_romaja`를 이식해, 모음 결합("eo"→ㅓ), 된소리("gg"→ㄲ), ㅇ 자동 삽입("a"→아), 받침 처리를 지원한다.

```swift
let ro = HangulInputContext(keyboard: "ro")
print(ro.processText("annyeonghaseyo")) // 안녕하세요
```

> **로마자 모호성:** `ng`는 받침 ㅇ으로 합쳐지므로(`annyeong`→안녕) "hangug"은 한국이 아니라 "항욱"이 된다. 이는 libhangul 로마자 자판의 본질적 동작이다.

## 입력 옵션

`HangulInputContextOption`으로 조합 동작을 조정한다.

| 옵션 | 기본값 | 설명 |
|---|---|---|
| `.autoReorder` | 켜짐 | 모아치기: 중성 입력 후 초성이 들어오면 같은 음절로 모음 (ㅏ+ㄱ→가) |
| `.combinationOnDoubleStroke` | 꺼짐 | 같은 초성 연속 입력을 된소리로 결합 (ㄱㄱ→ㄲ). Shift 없이 쌍자음 입력 |
| `.nonChoseongCombination` | 꺼짐 | 임의 자모 결합 허용(옛한글 클러스터). 옛한글 자판에서는 자동 활성화 |
| `.fineGrainedBackspace` | 켜짐 | 복합 자모(ㄲ, ㄳ, ㅘ 등)를 한 단계씩 분해하며 삭제 |

```swift
let context = HangulInputContext(keyboard: "2")
context.setOption(.combinationOnDoubleStroke, value: true)
// "rrk" → 까  (ㄱㄱ→ㄲ, +ㅏ)
```

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
