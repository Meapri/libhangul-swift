# ``LibHangul``

Swift 6 기반의 고성능 한글 입력 엔진

## 개요

`LibHangul`은 한글 입력 처리를 위한 순수 Swift 라이브러리입니다. 두벌식, 세벌식 키보드를 지원하며, 스레드 안전한 API를 제공합니다.

### 주요 기능

- **🛡️ Swift 6 Concurrency 지원**: `ThreadSafeHangulInputContext`로 스레드 안전성 보장
- **⌨️ 다양한 키보드**: 두벌식, 세벌식 390 레이아웃 지원  
- **🔤 정확한 한글 조합**: 자동 음절 분리, 복합 자모 처리
- **📝 유니코드 정규화**: NFC, NFD 지원

## 시작하기

### 기본 사용법

```swift
import LibHangul

// 스레드 안전한 컨텍스트 생성
let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

// 키 입력 처리
_ = context.process(Int(Character("r").asciiValue!)) // ㄱ
_ = context.process(Int(Character("k").asciiValue!)) // ㅏ

// 결과 확인
let preedit = context.getPreeditString() // "가"
```

## Topics

### 핵심 타입

- ``HangulInputContext``
- ``ThreadSafeHangulInputContext``
- ``HangulBuffer``

### 키보드

- ``HangulKeyboard``
- ``HangulKeyboardType``

### 유틸리티

- ``HangulCharacter``
- ``HangulError``

### 한자

- ``HanjaTable``
- ``Hanja``
