# LibHangul Swift

Swift 6로 완전히 재작성된 현대적인 한글 입력 라이브러리

## 소개

LibHangul Swift는 C로 작성된 기존 [libhangul](https://github.com/libhangul/libhangul) 라이브러리를 Swift 6로 완전히 재작성한 라이브러리입니다. Swift의 강력한 타입 시스템과 현대적인 언어 기능을 활용하여 한글 입력 처리 기능을 제공합니다.

## 특징

- **Swift 6 완전 지원**: Swift의 최신 언어 기능을 활용한 현대적인 구현
- **타입 안전성**: 강력한 타입 시스템으로 런타임 오류 방지
- **메모리 안전성**: Swift의 메모리 관리 기능으로 안전한 메모리 사용
- **크로스 플랫폼**: iOS, macOS, tvOS, watchOS, visionOS 지원
- **간편한 API**: 직관적이고 사용하기 쉬운 API 디자인
- **완전한 테스트**: 포괄적인 테스트 코드로 안정성 보장
- **확장성**: 프로토콜 기반 설계로 쉽게 확장 가능

## 설치

### Swift Package Manager

Package.swift에 다음 의존성을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/libhangul-swift.git", from: "1.0.0")
]
```

## 사용법

### 기본적인 한글 입력

```swift
import LibHangul

// 입력 컨텍스트 생성 (두벌식 키보드)
let context = LibHangul.createInputContext(keyboard: "2")

// 키 입력 처리
let keyCode = Int("r".first!.asciiValue!) // ㄱ
if context.process(keyCode) {
    // 커밋된 문자열 가져오기
    let committed = context.getCommitString()
    if !committed.isEmpty {
        let text = String(unicodeScalars: committed.map { UnicodeScalar($0)! })
        print("입력됨: \(text)")
    }
}
```

### 문자열 직접 입력

```swift
let context = LibHangul.createInputContext(keyboard: "2")

// "안녕하세요" 입력
let result = context.processText("dkssudgktpdy") // 두벌식 자판
print(result) // "안녕하세요"
```

### 한글 분석

```swift
// 음절인지 확인
if "가".isHangulSyllable {
    print("한글 음절입니다")
}

// 한글 분해
let decomposed = "한글".decomposedHangul
print(decomposed) // ["한", "글"]

// 한글 결합
if let syllable = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ") {
    print(syllable) // "가"
}
```

### 한자 검색

```swift
// 한자 사전 로드
if let hanjaTable = LibHangul.loadHanjaTable() {
    // 정확한 매칭으로 검색
    if let results = LibHangul.searchHanja(table: hanjaTable, key: "한자") {
        print("검색된 항목: \(results.getSize())개")

        for i in 0..<results.getSize() {
            if let key = results.getNthKey(i),
               let value = results.getNthValue(i),
               let comment = results.getNthComment(i) {
                print("키: \(key), 한자: \(value), 설명: \(comment)")
            }
        }
    }

    // 접두사 매칭으로 검색
    if let results = LibHangul.searchHanjaPrefix(table: hanjaTable, key: "삼국") {
        print("삼국으로 시작하는 한자: \(results.getSize())개")
    }
}
```

### 키보드 설정

```swift
// 세벌식 키보드 사용
let context = LibHangul.createInputContext(keyboard: "3")

// 키보드 변경
context.setKeyboard(with: "2y") // 두벌식 옛한글

// 출력 모드 변경
context.setOutputMode(.jamo) // 자모 단위 출력
```

## 지원하는 키보드

- **두벌식 (2)**: 표준 두벌식 자판
- **세벌식 (3)**: 표준 세벌식 자판
- **두벌식 옛한글 (2y)**: 옛한글 지원 두벌식
- **세벌식 옛한글 (3y)**: 옛한글 지원 세벌식

## API 레퍼런스

### LibHangul

메인 API를 제공하는 열거형입니다.

#### 주요 메서드

- `createInputContext(keyboard: String) -> HangulInputContext`
  - 새로운 입력 컨텍스트를 생성합니다.
- `availableKeyboards() -> [(id: String, name: String, type: HangulKeyboardType)]`
  - 사용 가능한 키보드 목록을 반환합니다.
- `isHangulSyllable(_: String) -> Bool`
  - 문자열이 한글 음절인지 확인합니다.
- `decomposeHangul(_: String) -> [String]`
  - 한글 문자열을 자모로 분해합니다.
- `composeHangul(choseong:jungseong:jongseong:) -> String?`
  - 자모를 한글 음절로 결합합니다.

### HangulInputContext

한글 입력 상태를 관리하는 클래스입니다.

#### 주요 메서드

- `process(_: Int) -> Bool`
  - ASCII 키 코드를 처리합니다.
- `processText(_: String) -> String`
  - 문자열을 입력으로 처리합니다.
- `getPreeditString() -> [UCSChar]`
  - 조합중인 문자열을 반환합니다.
- `getCommitString() -> [UCSChar]`
  - 커밋된 문자열을 반환하고 초기화합니다.
- `backspace() -> Bool`
  - 백스페이스 처리를 합니다.
- `flush() -> [UCSChar]`
  - 모든 내용을 커밋합니다.

### HanjaTable

한자 사전을 관리하는 클래스입니다.

#### 주요 메서드

- `load(filename: String?) -> Bool`
  - 한자 사전 파일을 로딩합니다.
- `matchExact(key: String) -> HanjaList?`
  - 정확한 키 매칭으로 한자를 검색합니다.
- `matchPrefix(key: String) -> HanjaList?`
  - 접두사 매칭으로 한자를 검색합니다.
- `matchSuffix(key: String) -> HanjaList?`
  - 접미사 매칭으로 한자를 검색합니다.

### HanjaList

한자 검색 결과를 담는 클래스입니다.

#### 주요 메서드

- `getSize() -> Int`
  - 검색된 항목 개수를 반환합니다.
- `getNth(_: Int) -> Hanja?`
  - n번째 한자 항목을 반환합니다.
- `getNthKey(_: Int) -> String?`
  - n번째 항목의 키를 반환합니다.
- `getNthValue(_: Int) -> String?`
  - n번째 항목의 한자를 반환합니다.
- `getNthComment(_: Int) -> String?`
  - n번째 항목의 설명을 반환합니다.

### HangulCharacter

한글 자모 관련 기능을 제공하는 클래스입니다.

#### 주요 메서드

- `isChoseong(_: UCSChar) -> Bool`
  - 초성인지 확인합니다.
- `isJungseong(_: UCSChar) -> Bool`
  - 중성인지 확인합니다.
- `isJongseong(_: UCSChar) -> Bool`
  - 종성인지 확인합니다.
- `jamoToSyllable(choseong:jungseong:jongseong:) -> UCSChar`
  - 자모를 음절로 결합합니다.
- `syllableToJamo(_: UCSChar) -> HangulJamoCombination`
  - 음절을 자모로 분해합니다.

## 예제 실행

```swift
import LibHangul

// 모든 예제 실행
LibHangulExamples.runAllExamples()
```

## 테스트

```bash
# 모든 테스트 실행
swift test

# 특정 테스트만 실행
swift test --filter HangulCharacterTests
```

## 프로젝트 구조

```
Sources/LibHangul/
├── LibHangul.swift          # 메인 API
├── HangulCharacter.swift    # 한글 자모 처리
├── HangulBuffer.swift       # 입력 버퍼 관리
├── HangulKeyboard.swift     # 키보드 레이아웃
├── HangulInputContext.swift # 입력 컨텍스트
├── Examples.swift           # 사용 예제
└── ...

Tests/LibHangulTests/
├── HangulCharacterTests.swift
├── HangulInputContextTests.swift
└── LibHangulTests.swift
```

## 요구사항

- Swift 6.0+
- Xcode 15.0+ (또는 Swift 6.0 호환 컴파일러)
- iOS 13.0+, macOS 10.15+, tvOS 13.0+, watchOS 6.0+, visionOS 1.0+

## 라이선스

이 프로젝트는 GNU Lesser General Public License v2.1을 따릅니다.

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 변경사항

### v1.0.0
- 초기 릴리스
- Swift 6로 완전 재작성
- 한글 입력 컨텍스트 구현
- 키보드 레이아웃 시스템
- 한글 자모 처리 기능
- 포괄적인 테스트 코드
- 사용 예제 및 문서화

## 지원

질문이나 문제가 있으시면 GitHub Issues를 사용해주세요.
