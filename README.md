# libhangul-swift

**Pure Swift로 구현된 고성능 한글 입력 엔진**

`libhangul-swift`는 C 언어 기반의 `libhangul`을 현대적인 Swift 6 아키텍처로 완전히 재작성한 라이브러리입니다. C 라이브러리 의존성 없이 순수 Swift로 구현되어 Apple 생태계(macOS, iOS, iPadOS 등) 어디에서나 즉시 통합 가능하며, Strict Concurrency를 완벽하게 준수합니다.

---

## 핵심 차별점

### 1. Pure Swift & 크로스 플랫폼
외부 C/C++ 라이브러리 브릿징이나 포인터 연산 없이 **100% 순수 Swift**로 설계되었습니다. 메모리 누수나 크래시 위험이 없으며, macOS의 `InputMethodKit`뿐만 아니라 iOS 커스텀 키보드 등 어떠한 Apple 플랫폼 환경에서도 즉시 사용할 수 있습니다.

### 2. 고성능 스레드 동기화 (Zero-Cost Abstraction)
입력기 엔진은 아주 짧은 지연 시간(Low Latency)이 생명입니다. `libhangul-swift`는 Swift 6의 표준 동시성 모델에서 발생할 수 있는 비동기 오버헤드를 제거하기 위해 `OSAllocatedUnfairLock`을 도입했습니다.
- `ThreadSafeHangulInputContext`는 데이터 경쟁(Data Race)을 완벽히 방지하면서도, **동기적(Synchronous) API**를 유지하여 `IMKInputController` 콜백 등 동기성이 강제되는 시스템 API와 완벽하게 호환됩니다.

### 3. 강력한 타입 안정성 (Type Safety)
기존 C 라이브러리의 모호한 `int` 타입 키 코드를 버리고, 명시적인 `KeyInput` 열거형을 도입했습니다.
- `KeyInput.character("r")`: 일반 문자 입력
- `KeyInput.keyCode(51)`: 시스템 특수 키(백스페이스 등) 입력
컴파일러 수준에서 잘못된 키 입력 처리를 방지하고 유지보수성을 극대화했습니다.

### 4. 다양한 한글 자판 지원
표준 두벌식은 물론, 세벌식 390, 세벌식 최종, 그리고 고어(옛한글) 입력을 위한 특수 자판까지 모두 내장하고 있습니다.

---

## 시작하기

### SPM (Swift Package Manager) 설치
```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

### 기본 사용법

안전한 멀티스레드 환경을 위해 `ThreadSafeHangulInputContext` 사용을 권장합니다.

```swift
import LibHangul

// 1. 컨텍스트 초기화 (두벌식)
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 2. 키 입력 전달 (예: 'ㄱ', 'ㅏ', 'ㄱ')
_ = context.process(KeyInput.character("r"))
_ = context.process(KeyInput.character("k"))
_ = context.process(KeyInput.character("r"))

// 3. 조합 중인 문자 확인
let markedText = context.getPreeditString() // "각"

// 4. 입력 확정 (커밋)
let committed = context.flush()
```

### 백스페이스 및 상태 제어
```swift
// 백스페이스 (자소 단위 분해)
_ = context.backspace() // "각" -> "가"

// 컨텍스트 초기화
context.reset()
```

---

## 아키텍처 하이라이트

- **`ThreadSafeHangulInputContext`**: `OSAllocatedUnfairLock`을 래핑하여 초고속 동기화를 제공하는 엔진의 메인 인터페이스입니다.
- **`HangulKeyboard`**: 영문 쿼티 배열을 기반으로 두벌식/세벌식 등 다양한 물리적 키 매핑을 담당합니다.
- **`HangulBuffer` & `HangulCharacter`**: 초성, 중성, 종성의 결합 법칙(Conjoinability)과 오토마타 상태를 관리하고, 이를 유니코드(`UCSChar`)로 정밀하게 변환합니다.

---

## 라이선스

이 프로젝트는 **MIT 라이선스**로 배포됩니다.
오픈소스로서 누구나 자유롭게 사용, 수정, 배포할 수 있습니다.
