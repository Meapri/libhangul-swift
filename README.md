# libhangul-swift

Swift 6 기반의 고성능 한글 입력 엔진입니다.
기존 C 언어 기반의 `libhangul` 로직을 현대적인 Swift 아키텍처로 재작성하여, Strict Concurrency를 완벽하게 지원하며 높은 성능과 메모리 안정성을 제공합니다.

## 주요 특징

### 1. 고성능 한자 및 조합 엔진
- **Trie 기반 한자 검색**: 기존 해시맵 구조의 한계를 극복하기 위해 Prefix Tree (Trie) 자료구조를 자체 구현하여, 접두어 검색(`matchPrefix`)에서 **O(m)** 성능을 보장합니다.
- **스트리밍 파싱 (Streaming Load)**: 대용량 한자 사전 로딩 시 전체 파일을 메모리에 적재하지 않고 `Swift.String.enumerateLines`를 활용해 스트리밍 방식으로 파싱하여 초기 메모리 점유율을 획기적으로 낮췄습니다.

### 2. 동시성과 안정성
- **Swift 6 Strict Concurrency 완벽 대응**: 컴파일러 수준에서 데이터 경쟁(Data Race)을 방지하는 현대적인 동시성 모델 적용.
- **스레드 안전성 (Thread Safety)**: `ThreadSafeHangulInputContext`를 통해 내부적으로 Lock 기반 동기화를 제공하여, `InputMethodKit` 환경과 같은 멀티스레드 접근에서도 안전하게 상태를 관리합니다.
- **OSLog 통합**: 릴리즈 빌드에서 오버헤드가 거의 없는 효율적인 로깅 시스템을 구축했습니다.

### 3. 유니코드 및 플랫폼 호환성
- **유니코드 정규화**: NFC/NFD 자동 변환 및 파일명 호환 모드를 지원하여 macOS 파일 시스템과의 완벽한 호환성을 제공합니다.
- **크로스 플랫폼 지원**: macOS뿐만 아니라 iOS, tvOS, watchOS, visionOS 등 다양한 Apple 생태계 플랫폼과 호환됩니다.

---

## 설치

Swift Package Manager를 통해 프로젝트에 추가할 수 있습니다.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

---

## 기본 사용법

멀티스레드 환경에서는 상태 오염을 방지하기 위해 반드시 `ThreadSafeHangulInputContext`를 사용해야 합니다.

### 입력 및 조합
```swift
import LibHangul

// 1. 컨텍스트 생성 (기본: 두벌식)
let context = LibHangul.createThreadSafeInputContext()

// 2. 키 입력 처리 ('ㄱ', 'ㅏ', 'ㄴ' 입력)
_ = context.process(Int(Character("r").asciiValue!)) 
_ = context.process(Int(Character("k").asciiValue!))
_ = context.process(Int(Character("s").asciiValue!))

// 3. 현재 조합 중인 상태 확인
let preedit = context.getPreeditString() // [0xD55C] ("한")

// 4. 입력 확정
let committed = context.flush()
```

### 문자열 일괄 변환
```swift
let context = LibHangul.createThreadSafeInputContext()
let result = context.processText("gksrmfdlqslek") // "한글입니다"
```

### 백스페이스 처리
```swift
let context = LibHangul.createThreadSafeInputContext()

_ = context.process(Int(Character("r").asciiValue!)) // ㄱ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ
_ = context.process(Int(Character("r").asciiValue!)) // ㄱ (종성: 각)

_ = context.backspace() // "각" → "가"
_ = context.backspace() // "가" → "ㄱ"
_ = context.backspace() // "ㄱ" → ""
```

---

## 지원 자판

| ID | 이름 | 설명 |
| :--- | :--- | :--- |
| `2` | **두벌식** | 표준 두벌식 자판 (기본값) |
| `3` | **세벌식 390** | 세벌식 390 자판 |
| `2y` | **두벌식 옛한글** | 옛한글 입력용 두벌식 |
| `3y` | **세벌식 옛한글** | 옛한글 입력용 세벌식 |

---

## 아키텍처 구조

1. **Public API Layer**: 
   - `ThreadSafeHangulInputContext`를 통한 동시성 제어 및 외부 인터페이스 제공.
2. **Core Engine Layer**: 
   - `HangulInputContext`: 입력 상태와 비즈니스 로직 관리.
   - `HangulKeyboard`: 영문 자판 입력값을 한글 자모로 매핑.
   - `HangulBuffer` & `HangulCharacter`: 유니코드 기반 자모 조합 처리.
3. **Utilities Layer**: 
   - Trie 구조의 한자 사전 변환(`Hanja`), OSLog 연동(`Logging`), 에러 처리(`HangulError`).

---

## 라이선스

MIT License
Copyright © 2026 PriType Team.
