# libhangul-swift

<div align="center">

![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20limitless-lightgrey?style=flat-square)
![SPM](https://img.shields.io/badge/Swift_Package_Manager-compatible-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

**완벽한 한글 입력 경험을 위한 차세대 Swift 라이브러리**

[설치하기](#installation) • [시작하기](#quick-start) • [문서](#documentation) • [기여하기](#contributing)

</div>

---

## 💡 소개

`libhangul-swift`는 Swift 6의 강력한 동시성 모델을 기반으로 설계된 고성능 한글 입력 엔진입니다.
복잡한 자모 조합, 정확한 이중 모음 처리, 그리고 스레드 안전성을 보장하는 현대적인 API를 제공합니다.

### ✨ 주요 기능

-   **🛡️ Swift 6 Concurrency 완벽 지원**: `Actor` 기반의 `ThreadSafeHangulInputContext`로 데이터 경쟁 없는 안전한 환경 제공.
-   **⌨️ 강력한 입력 처리**:
    -   초성(ㄱ) + 중성(ㅏ) + 종성(ㄴ) → "간" 자동 조합
    -   이중 자음(ㄲ, ㄸ, ㅃ) 및 이중 모음(ㅞ, ㅙ) 완벽 지원
    -   초성으로 온 'ㄴ'이 앞 글자의 종성으로 붙는 관용적 입력 처리 지원
-   **🔄 정교한 상태 관리**: 백스페이스 시 자소 단위 분해 삭제 (예: "갋" -> "갈" -> "가" -> "ㄱ")
-   **💾 유니코드 정규화**: NFC(완성형), NFD(조합형) 및 파일명 안전 모드 자동 지원
-   **⚡ 고성능 버퍼링**: 효율적인 메모리 관리와 `processBatch`를 통한 대량 입력 고속 처리

## 📦 설치 (Installation)

### Swift Package Manager

`Package.swift` 파일의 `dependencies`에 다음을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", from: "3.0.0")
]
```

## 🚀 시작하기 (Quick Start)

### 1. 기본 사용법 (Swift 6 권장)

스레드 안전한 `ThreadSafeHangulInputContext`를 사용하세요. NSLock 기반으로 동기적으로 작동합니다.

```swift
import LibHangul

// 1. 컨텍스트 생성 (기본: 두벌식)
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 2. 입력 처리 (동기)
// 'ㅎ', 'ㅏ', 'ㄴ' 순서로 입력 시 -> "한"
_ = context.process(Int(Character("g").asciiValue!)) // ㅎ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ
_ = context.process(Int(Character("s").asciiValue!)) // ㄴ

// 3. 현재 조합 중인 상태 확인
let preedit = context.getPreeditString() 
print(String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) })) // 출력: "한"

// 4. 입력 확정 및 비우기
let committed = context.flush()
print(String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })) // 출력: "한"
```

### 2. 텍스트 일괄 처리

문자열 전체를 한 번에 한글로 변환할 때 유용합니다.

```swift
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")
let result = context.processText("gksrmfdlqslek") // "한글입니다"

print(String(result.committed.compactMap { UnicodeScalar($0) }.map { Character($0) }))
```

## 🛠️ 고급 설정 (Advanced Usage)

### 사용자 정의 설정 (Builder 패턴)

`HangulInputConfiguration`을 통해 세밀한 동작 제어가 가능합니다.

```swift
// 메모리 최적화 모드로 설정
let config = try HangulInputConfiguration(
    maxBufferSize: 50,              // 버퍼 크기 제한
    forceNFCNormalization: true,    // NFC 정규화 강제
    autoErrorRecovery: true,         // 입력 오류 시 자동 복구
    performanceMode: .memoryOptimized
)

let context = LibHangul.createThreadSafeInputContext(configuration: config)
```

### 지원하는 키보드 레이아웃

-   **두벌식 (`"2"`)**: 표준 두벌식 자판 (기본값)
-   **세벌식 390 (`"3"`)**: 세벌식 390 자판
-   **두벌식 옛한글 (`"2y"`)**: 옛한글 입력을 위한 두벌식
-   **세벌식 옛한글 (`"3y"`)**: 옛한글 입력을 위한 세벌식

```swift
// 세벌식 사용 예시
let context = LibHangul.createThreadSafeInputContext(keyboardId: "3")
```

## 🧩 아키텍처

-   **ThreadSafeHangulInputContext (Actor)**: 외부에서 접근하는 메인 진입점입니다. 내부 상태를 보호하며 비동기적으로 입력을 처리합니다.
-   **HangulInputContext (Class)**: 실제 입력 로직을 담당하는 코어 엔진입니다. 상태(초성, 중성, 종성)를 관리합니다.
-   **HangulBuffer**: 입력된 자소를 임시 저장하고 조합 규칙(오토마타)에 따라 합칩니다.
-   **HangulKeyboard**: 입력된 키 코드(ASCII)를 한글 자소로 매핑합니다.

## ⚠️ 문제 해결

**Q: `fatalError`가 발생하거나 테스트가 실패합니다.**
A: Xcode 환경이나 Playground 설정 문제일 수 있습니다. 특히 `XCTest` 프레임워크 로딩 문제인 경우가 많습니다. 코드는 Swift 6 표준을 준수하므로, 올바른 SDK 경로(`DEVELOPER_DIR` 등) 설정 후 다시 시도해보세요.

**Q: 동시성 경고(Concurrency Warning)가 뜹니다.**
A: 반드시 `ThreadSafeHangulInputContext`를 사용해야 합니다. 기존 `HangulInputContext`는 내부 구현용이거나 단일 스레드 보장이 확실한 곳에서만 사용해야 합니다.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참고하세요.
