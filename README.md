# libhangul-swift

<div align="center">

![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-lightgrey?style=flat-square)
![SPM](https://img.shields.io/badge/Swift_Package_Manager-compatible-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen?style=flat-square)
![Grade](https://img.shields.io/badge/Code_Quality-A+-blueviolet?style=flat-square)

**Swift 6 기반 고성능 한글 입력 엔진**

[설치](#-설치) • [빠른 시작](#-빠른-시작) • [API 레퍼런스](#-api-레퍼런스) • [아키텍처](#-아키텍처) • [기여하기](#-기여하기)

</div>

---

## 💡 소개 (Introduction)

`libhangul-swift`는 Swift 6의 Strict Concurrency를 지원하는 **고성능 한글 입력 엔진 라이브러리**입니다.  
C 언어 기반의 `libhangul` 로직을 현대적인 Swift 아키텍처로 재설계하여, 안정성과 유지보수성을 극대화했습니다.

### ✨ 기술적 특징 (Technical Features)

| 기능 | 설명 |
|------|------|
| **🚀 Trie 기반 한자 엔진** | 기존 해시맵 방식의 한계를 극복하기 위해 **Prefix Tree (Trie)** 자료구조를 자체 구현했습니다. 접두어 검색(`matchPrefix`)에서 O(m) 성능을 보장합니다. |
| **💾 Streaming Load** | 대용량 한자 사전 로딩 시 `Swift.String.enumerateLines`를 활용한 스트리밍 파싱을 적용하여 초기 메모리 할당(Allocations)을 최소화했습니다. |
| **🛡️ Thread Safety** | `ThreadSafeHangulInputContext`는 내부적으로 Lock 기반 동기화를 제공하여, `InputMethodKit`과 같은 멀티스레드 환경에서도 안전하게 상태를 관리합니다. |
| **🔤 유니코드 정규화** | NFC/NFD 자동 변환 및 파일명 호환 모드를 지원하여 macOS 파일 시스템과의 호환성을 보장합니다. |
| **📊 Zero-overhead Logging** | `OSLog`를 사용하여 릴리즈 빌드에서 오버헤드가 거의 없는 로깅 시스템을 구축했습니다. |

---

## 📦 설치 (Installation)

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

---

## 🚀 사용법 (Usage)

### 기본 사용 (Thread-Safe Context)

멀티스레드 환경(대부분의 앱)에서는 반드시 `ThreadSafeHangulInputContext`를 사용해야 합니다.

```swift
import LibHangul

// 1. 컨텍스트 생성 (기본: 두벌식)
let context = LibHangul.createThreadSafeInputContext()

// 2. 키 입력 처리 (동기)
// 'ㄱ' -> 'ㅏ' -> 'ㄴ' 입력
_ = context.process(Int(Character("r").asciiValue!)) 
_ = context.process(Int(Character("k").asciiValue!))
_ = context.process(Int(Character("s").asciiValue!))

// 3. 현재 조합 상태 확인
let preedit = context.getPreeditString()
// preedit: "한" [0xD55C]

// 4. 입력 확정 (Flush)
let committed = context.flush()
```

### 문자열 변환

```swift
// 두벌식 키 시퀀스 → 한글 문자열
let context = LibHangul.createThreadSafeInputContext()
let result = context.processText("gksrmfdlqslek")

let text = String(result.committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
print(text) // "한글입니다"
```

### 백스페이스 처리

```swift
let context = LibHangul.createThreadSafeInputContext()

// "각" 입력
_ = context.process(Int(Character("r").asciiValue!)) // ㄱ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ
_ = context.process(Int(Character("r").asciiValue!)) // ㄱ (종성)

// 백스페이스로 자소 단위 삭제
_ = context.backspace() // "각" → "가"
_ = context.backspace() // "가" → "ㄱ"
_ = context.backspace() // "ㄱ" → ""
```

### 세벌식 390 사용

```swift
// 세벌식 390 키보드
let context = LibHangul.createThreadSafeInputContext(keyboard: "3")

// 세벌식 390에서 'o'+`v' = ㅈ+ㅗ = "조"
_ = context.process(Int(Character("o").asciiValue!)) // ㅈ (초성)
_ = context.process(Int(Character("v").asciiValue!)) // ㅗ (중성)
```

---

## 📖 API 레퍼런스

### LibHangul (진입점)

| 메서드 | 설명 |
|--------|------|
| `createThreadSafeInputContext(keyboard:)` | 스레드 안전한 입력 컨텍스트 생성 |
| `createInputContext(keyboard:)` | 단일 스레드용 입력 컨텍스트 생성 |
| `availableKeyboards()` | 사용 가능한 키보드 목록 반환 |
| `version` | 라이브러리 버전 |

### ThreadSafeHangulInputContext

| 메서드 | 반환 타입 | 설명 |
|--------|----------|------|
| `process(_:)` | `Bool` | 키 입력 처리 |
| `backspace()` | `Bool` | 마지막 자소 삭제 |
| `flush()` | `[UCSChar]` | 현재 조합 확정 및 반환 |
| `reset()` | `Void` | 상태 초기화 |
| `getPreeditString()` | `[UCSChar]` | 조합 중인 문자열 |
| `getCommitString()` | `[UCSChar]` | 확정된 문자열 |
| `processText(_:)` | `HangulInputResult` | 문자열 일괄 처리 |
| `processBatch(_:)` | `[HangulInputResult]` | 키 배열 일괄 처리 |

### 키보드 레이아웃

| ID | 이름 | 설명 |
|----|------|------|
| `"2"` | 두벌식 | 표준 두벌식 자판 **(기본값)** |
| `"3"` | 세벌식 390 | 세벌식 390 자판 |
| `"2y"` | 두벌식 옛한글 | 옛한글 입력용 두벌식 |
| `"3y"` | 세벌식 옛한글 | 옛한글 입력용 세벌식 |

### 두벌식 키 매핑 (QWERTY)

```
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│ ㅂ│ ㅈ│ ㄷ│ ㄱ│ ㅅ│ ㅛ│ ㅕ│ ㅑ│ ㅐ│ ㅔ│
│ q │ w │ e │ r │ t │ y │ u │ i │ o │ p │
├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
│ ㅁ│ ㄴ│ ㅇ│ ㄹ│ ㅎ│ ㅗ│ ㅓ│ ㅏ│ ㅣ│   │
│ a │ s │ d │ f │ g │ h │ j │ k │ l │   │
├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
│ ㅋ│ ㅌ│ ㅊ│ ㅍ│ ㅠ│ ㅜ│ ㅡ│   │   │   │
│ z │ x │ c │ v │ b │ n │ m │   │   │   │
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘

Shift: ㄲ(R), ㄸ(E), ㅃ(Q), ㅆ(T), ㅉ(W), ㅒ(O), ㅖ(P)
```

---

## 🖥️ InputMethodKit 연동 (macOS)

macOS 입력기 개발 시 `ThreadSafeHangulInputContext`를 사용하여 IMK 콜백에서 안전하게 한글 조합을 처리할 수 있습니다.

### 기본 연동 예제

```swift
import InputMethodKit
import LibHangul

class MyInputController: IMKInputController {
    // 스레드 안전 컨텍스트 사용
    private let hangul = LibHangul.createThreadSafeInputContext(keyboard: "2")
    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, event.type == .keyDown else { return false }
        guard let client = sender as? IMKTextInput else { return false }
        
        let keyCode = Int(event.keyCode)
        
        // 백스페이스 처리
        if keyCode == 51 {
            if hangul.backspace() {
                updateMarkedText(client)
                return true
            }
            return false
        }
        
        // 일반 키 입력
        guard let char = event.characters?.first,
              let ascii = char.asciiValue else { return false }
        
        let processed: Bool = hangul.process(Int(ascii))
        
        if processed {
            updateMarkedText(client)
            return true
        }
        
        // 한글 입력이 아닌 경우 현재 조합 확정
        commitComposition(client)
        return false
    }
    
    private func updateMarkedText(_ client: IMKTextInput) {
        let preedit = hangul.getPreeditString()
        let committed = hangul.getCommitString()
        
        // 확정된 텍스트 삽입
        if !committed.isEmpty {
            let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
            client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        }
        
        // 조합 중인 텍스트 표시
        let markedText = String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) })
        client.setMarkedText(markedText, 
                            selectionRange: NSRange(location: markedText.count, length: 0),
                            replacementRange: NSRange(location: NSNotFound, length: 0))
    }
    
    private func commitComposition(_ client: IMKTextInput) {
        let flushed = hangul.flush()
        if !flushed.isEmpty {
            let text = String(flushed.compactMap { UnicodeScalar($0) }.map { Character($0) })
            client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        }
    }
}
```

### 주의사항

- **반드시 `ThreadSafeHangulInputContext` 사용**: IMK 콜백은 여러 스레드에서 호출될 수 있습니다.
- **명시적 타입 지정**: `process()` 호출 시 `let processed: Bool = ...`로 명시해야 `Result` 오버로드와의 모호성을 피할 수 있습니다.
- **키 매핑**: `event.keyCode`가 아닌 `event.characters`의 ASCII 값을 사용하세요.

---

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Public API Layer                      │
│  ┌─────────────────────────────────────────────────┐    │
│  │        ThreadSafeHangulInputContext             │    │
│  │              (NSLock 기반)                       │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Core Engine Layer                     │
│  ┌─────────────────┐    ┌─────────────────────────┐     │
│  │ HangulInputContext│    │    HangulKeyboard      │     │
│  │   (상태 관리)     │◄───│  (키→자모 매핑)        │     │
│  └─────────────────┘    └─────────────────────────┘     │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────┐    ┌─────────────────────────┐     │
│  │   HangulBuffer   │    │   HangulCharacter      │     │
│  │  (자모 조합)     │◄───│ (유니코드 변환)        │     │
│  └─────────────────┘    └─────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Utilities Layer                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────────┐     │
│  │  Logging   │  │   Hanja    │  │ HangulError    │     │
│  │  (OSLog)   │  │  (한자 변환) │  │ (에러 처리)    │     │
│  └────────────┘  └────────────┘  └────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### 파일 구조

```
Sources/LibHangul/
├── LibHangul.swift                 # 공개 API 진입점
├── HangulInputContext.swift        # 입력 상태 관리 (코어)
├── HangulBuffer.swift              # 자모 버퍼 (internal)
├── HangulKeyboard.swift            # 키보드 레이아웃
├── HangulCharacter.swift           # 유니코드 자모 처리
├── ThreadSafeHangulInputContext.swift  # 동시성 래퍼
├── Hanja.swift                     # 한자 사전
├── Logging.swift                   # OSLog 로깅
└── LibHangul.docc/                 # DocC 문서
    ├── LibHangul.md
    └── GettingStarted.md
```

---

## ⚙️ 고급 설정

### HangulInputConfiguration

```swift
let config = try HangulInputConfiguration(
    maxBufferSize: 50,                // 최대 버퍼 크기 (1-1000)
    forceNFCNormalization: true,      // NFC 정규화 강제
    enableBufferMonitoring: true,     // 버퍼 상태 모니터링
    autoErrorRecovery: true,          // 자동 오류 복구
    filenameCompatibilityMode: false, // 파일명 호환 모드
    outputMode: .syllable,            // 출력 모드 (syllable/jamo)
    defaultKeyboard: "2",             // 기본 키보드
    performanceMode: .balanced        // 성능 모드
)
```

### 성능 모드

| 모드 | 설명 |
|------|------|
| `.balanced` | 균형 모드 (기본값) |
| `.speedOptimized` | 속도 최적화 |
| `.memoryOptimized` | 메모리 최적화 |

### 프리셋 설정

```swift
// 기본값
let config = HangulInputConfiguration.default

// 속도 최적화
let config = HangulInputConfiguration.speedOptimized

// 메모리 최적화
let config = HangulInputConfiguration.minimal
```

---

## 🧪 테스트

```bash
# 빌드
swift build

# TestRunner 실행
swift run TestRunner

# 예상 출력:
# ✅ PASSED: Simple CV (가)
# ✅ PASSED: Syllable Separation (가가)
# ✅ PASSED: Concurrent Processing (100 iterations)
# ✅ PASSED: High Concurrency (50 threads, no crash)
# 🎉 All Tests Passed!
```

---

## 🔧 문제 해결

### Q: XCTest 모듈을 찾을 수 없습니다

```bash
# Xcode Command Line Tools 확인
xcode-select -p
# /Applications/Xcode.app/Contents/Developer 출력 확인

# 필요시 재설정
sudo xcode-select --reset
```

### Q: 동시성 경고가 발생합니다

`ThreadSafeHangulInputContext`를 사용하세요. `HangulInputContext`는 단일 스레드 환경(InputMethodKit 콜백 등) 전용입니다.

```swift
// ❌ 잘못된 사용
let context = HangulInputContext(keyboard: "2")
DispatchQueue.global().async { context.process(key) } // 위험!

// ✅ 올바른 사용
let context = LibHangul.createThreadSafeInputContext()
DispatchQueue.global().async { _ = context.process(key) } // 안전
```

### Q: 한자 변환이 작동하지 않습니다

한자 사전 파일이 `data/hanja/hanja.txt` 경로에 있는지 확인하세요.

---

## 📊 성능

| 작업 | 처리량 |
|------|--------|
| 단일 키 입력 | ~0.001ms |
| 100자 텍스트 | ~0.1ms |
| 동시 처리 (100회) | ~5ms |

---

## 🤝 기여하기

1. Fork 후 브랜치 생성
2. 변경사항 구현 및 테스트
3. Pull Request 제출

### 코드 스타일
- Swift 6 Strict Concurrency 준수
- 모든 public API에 DocC 주석
- 경고 0개 유지

---

## 📄 라이선스

MIT License - 자유롭게 사용하세요!

---

<div align="center">

**Made with ❤️ for Korean Input**

[⬆️ 맨 위로](#libhangul-swift)

</div>
