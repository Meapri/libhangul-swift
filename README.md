# libhangul-swift

Swift로 작성된 한글 입력 엔진 라이브러리입니다. C 기반 `libhangul`의 로직을 Swift로 포팅하여, 브릿징이나 포인터 연산 없이 Apple 플랫폼에서 네이티브로 동작하도록 구현했습니다.

## 주요 특징

- **100% Swift 구현**: C 의존성 없이 순수 Swift 코드로 작성되어 macOS InputMethodKit 및 iOS 커스텀 키보드 확장에서 바로 사용 가능합니다.
- **동시성 처리**: 멀티스레드 환경에서 안전하게 동작하도록 `OSAllocatedUnfairLock`을 사용하여 상태를 보호합니다.
- **한자 검색**: Prefix Tree (Trie) 자료구조를 사용하여 한자 DB 검색 속도를 최적화했습니다. 초기 구동 메모리 사용량을 줄이기 위해 스트림 방식으로 DB를 파싱합니다.
- **타입 안정성**: 키 입력 처리에 명시적인 타입(`KeyInput`)을 사용하여 컴파일 타임 검증을 지원합니다.

## 설치 (Swift Package Manager)

프로젝트의 `Package.swift`에 다음 의존성을 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/libhangul-swift.git", branch: "main")
]
```

## 사용 방법

```swift
import LibHangul

// 1. 스레드 안전 컨텍스트 생성 (예: 두벌식)
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 2. 키 입력 처리
_ = context.process(KeyInput.character("r")) // 'ㄱ'
_ = context.process(KeyInput.character("k")) // 'ㅏ'
_ = context.process(KeyInput.character("r")) // 'ㄱ'

// 3. 현재 조합 중인 문자열 가져오기
let preedit = context.getPreeditString() // "각"

// 4. 조합 완료 및 텍스트 확정
let committed = context.flush()
```

## 지원 자판

| ID | 자판 | 설명 |
| :--- | :--- | :--- |
| `2` | **두벌식** | 표준 QWERTY 기반 두벌식 (기본값) |
| `3` | **세벌식 390** | 세벌식 390 배열 |
| `2y` / `3y` | **옛한글** | 제주어 및 고문서 작성을 위한 옛한글 매핑 |

## 내부 동작

- `HangulBuffer` 및 `HangulCharacter`: 초·중·종성 결합 오토마타를 통해 유니코드 문자 조합 처리.
- macOS와 Windows 간의 NFD/NFC 정규화 차이 교정 지원.

## 라이선스

MIT License
