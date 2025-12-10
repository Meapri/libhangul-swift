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

## 💡 소개

`libhangul-swift`는 Swift 6의 Strict Concurrency를 완벽히 지원하는 **프로덕션 레디** 한글 입력 라이브러리입니다.

### ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| **🛡️ 스레드 안전** | NSLock 기반 `ThreadSafeHangulInputContext`로 동시성 환경 완벽 지원 |
| **⌨️ 다중 키보드** | 두벌식, 세벌식 390, 옛한글 레이아웃 지원 |
| **🔤 정확한 조합** | 초성+중성+종성 자동 결합, 복합 자모 처리 |
| **⬅️ 스마트 백스페이스** | 자소 단위 분해 (갋→갈→가→ㄱ) |
| **📝 유니코드 정규화** | NFC/NFD 자동 변환, 파일명 호환 모드 |
| **📊 OSLog 로깅** | Instruments 통합 디버깅 지원 |

---

## 📦 설치

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", from: "3.0.0")
]
```

### Xcode
1. File → Add Package Dependencies
2. URL 입력: `https://github.com/Meapri/libhangul-swift.git`
3. 버전 선택: `3.0.0` 이상

---

## 🚀 빠른 시작

### 기본 사용법

```swift
import LibHangul

// 1. 컨텍스트 생성 (기본: 두벌식)
let context = LibHangul.createThreadSafeInputContext()

// 2. 키 입력 처리 (동기)
_ = context.process(Int(Character("g").asciiValue!)) // ㅎ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ
_ = context.process(Int(Character("s").asciiValue!)) // ㄴ

// 3. 현재 조합 상태 확인
let preedit = context.getPreeditString()
// preedit: [0xD55C] = "한"

// 4. 입력 확정
let committed = context.flush()
// committed: [0xD55C] = "한"
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
