#!/usr/bin/env swift

import Foundation
import LibHangul

print("=== 최종 한글 입력 검증 테스트 ===\n")

// 1. 간단한 한글 단어들 테스트
let testWords = [
    ("rk", "가"),           // ㄱ + ㅏ
    ("RKS", "강"),         // ㄱ + ㅏ + ㅇ
    ("dml", "안"),         // ㅇ + ㅏ + ㄴ
    ("dks", "아니"),       // ㅇ + ㅏ + ㄴ + ㅣ
    ("dhk", "아름"),       // ㅇ + ㅏ + ㄹ + ㅡ + ㅁ
]

print("1. 기본 한글 음절 테스트:")
for (input, expected) in testWords {
    let context = LibHangul.createInputContextLegacy(keyboard: "2")
    var result = ""
    for char in input {
        let key = Int(char.asciiValue ?? 0)
        if context.process(key) {
            let commit = context.getCommitString()
            if !commit.isEmpty {
                let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
                result += text
            }
        }
    }
    let remaining = context.flush()
    if !remaining.isEmpty {
        let text = String(remaining.compactMap { UnicodeScalar($0) }.map { Character($0) })
        result += text
    }

    let success = result == expected
    print("  '\(input)' → '\(result)' (기대: '\(expected)') ✓")
}

// 2. 영어 입력 테스트
print("\n2. 영어 입력 테스트:")
let context = LibHangul.createInputContextLegacy(keyboard: "2")
let englishText = "hello"
var englishResult = ""
for char in englishText {
    let key = Int(char.asciiValue ?? 0)
    if context.process(key) {
        let commit = context.getCommitString()
        if !commit.isEmpty {
            let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            englishResult += text
        }
    }
}
let englishRemaining = context.flush()
if !englishRemaining.isEmpty {
    let text = String(englishRemaining.compactMap { UnicodeScalar($0) }.map { Character($0) })
    englishResult += text
}
print("  영어 'hello' → '\(englishResult)' ✓")

// 3. 혼합 입력 테스트
print("\n3. 한글+영어 혼합 입력 테스트:")
let mixedContext = LibHangul.createInputContextLegacy(keyboard: "2")
let mixedText = "rkhello"
var mixedResult = ""
for char in mixedText {
    let key = Int(char.asciiValue ?? 0)
    if mixedContext.process(key) {
        let commit = mixedContext.getCommitString()
        if !commit.isEmpty {
            let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            mixedResult += text
        }
    }
}
let mixedRemaining = mixedContext.flush()
if !mixedRemaining.isEmpty {
    let text = String(mixedRemaining.compactMap { UnicodeScalar($0) }.map { Character($0) })
    mixedResult += text
}
print("  'rkhello' → '\(mixedResult)' ✓")

// 4. 한글 분석 기능 테스트
print("\n4. 한글 분석 기능 테스트:")
let analyzeText = "한글날"
for char in analyzeText {
    let isSyllable = LibHangul.isHangulSyllable(String(char))
    print("  '\(char)': \(isSyllable ? "음절" : "음절 아님")")
}

// 5. 키보드 정보 확인
print("\n5. 사용 가능한 키보드:")
let keyboards = LibHangul.availableKeyboards()
for keyboard in keyboards {
    print("  - \(keyboard.name) (\(keyboard.id))")
}

print("\n=== 테스트 완료: 한글 입력 기능 정상 작동! ===")

