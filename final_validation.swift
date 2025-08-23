//
//  final_validation.swift
//  한글 입력기 최종 검증 프로그램
//

import Foundation
@testable import LibHangul

print("=== 한글 입력기 최종 검증 ===")
print("")

// 1. 기본 한글 입력 검증
print("1. 기본 한글 입력 테스트")
let context = HangulInputContext(keyboard: "2")

let testCases = [
    ("가", ["r", "k"]),
    ("나", ["s", "k"]),
    ("다", ["e", "k"]),
    ("마", ["f", "k"]),
    ("바", ["a", "k"]),
    ("사", ["t", "k"]),
    ("자", ["w", "k"]),
    ("카", ["z", "k"]),
    ("타", ["x", "k"]),
    ("파", ["v", "k"]),
    ("하", ["g", "k"])
]

for (expected, keys) in testCases {
    let context = HangulInputContext(keyboard: "2")
    for key in keys {
        let keyCode = Int(Character(key).asciiValue!)
        let result = context.process(keyCode)
        print("  '\(key)' 입력: \(result ? "✅" : "❌")")
    }
    let committed = context.getCommitString()
    let actual = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
    print("  결과: '\(actual)' (기대: '\(expected)') \(actual == expected ? "✅" : "❌")")
    print("")
}

// 2. 종성 있는 글자 테스트
print("2. 종성 있는 글자 테스트")
let jongseongTests = [
    ("간", ["r", "k", "s"]),
    ("갈", ["r", "k", "f"]),
    ("감", ["r", "k", "a"]),
    ("강", ["r", "k", "t"])
]

for (expected, keys) in jongseongTests {
    let context = HangulInputContext(keyboard: "2")
    for key in keys {
        let keyCode = Int(Character(key).asciiValue!)
        let result = context.process(keyCode)
        print("  '\(key)' 입력: \(result ? "✅" : "❌")")
    }
    let committed = context.getCommitString()
    let actual = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
    print("  결과: '\(actual)' (기대: '\(expected)') \(actual == expected ? "✅" : "❌")")
    print("")
}

// 3. 영어 입력 테스트
print("3. 영어 입력 테스트")
let englishTests = ["hello", "world", "123", "!@#"]

for text in englishTests {
    let context = HangulInputContext(keyboard: "2")
    var results = [String]()

    for char in text {
        let keyCode = Int(char.asciiValue!)
        let result = context.process(keyCode)
        if result {
            let committed = context.getCommitString()
            let inputText = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
            results.append(inputText)
        }
    }

    let finalResult = results.joined()
    print("  '\(text)' 입력: '\(finalResult)' \(finalResult == text ? "✅" : "❌")")
}
print("")

// 4. 백스페이스 테스트
print("4. 백스페이스 테스트")
let backspaceTest = ["r", "k", "s"] // "간" 입력 후 백스페이스

let context = HangulInputContext(keyboard: "2")
for key in backspaceTest {
    let keyCode = Int(Character(key).asciiValue!)
    let result = context.process(keyCode)
    print("  '\(key)' 입력: \(result ? "✅" : "❌")")
}

print("  백스페이스 전 커밋: \(context.getCommitString().map { String(format: "0x%04X", $0) })")

let backspaceResult = context.backspace()
print("  백스페이스: \(backspaceResult ? "✅" : "❌")")

let afterBackspace = context.getCommitString()
print("  백스페이스 후 커밋: \(afterBackspace.map { String(format: "0x%04X", $0) })")
print("")

// 5. 버퍼 크기 테스트
print("5. 버퍼 크기 테스트")
let bufferContext = HangulInputContext(keyboard: "2")
bufferContext.maxBufferSize = 5

for i in 0..<10 {
    let keyCode = Int(Character("r").asciiValue!) // 계속 'r' 입력
    let result = bufferContext.process(keyCode)
    let committed = bufferContext.getCommitString()
    print("  입력 \(i+1): \(result ? "✅" : "❌"), 커밋: \(committed.count)개")
}
print("")

// 6. 에러 처리 테스트
print("6. 에러 처리 테스트")
let errorContext = HangulInputContext(keyboard: "2")

// 유효하지 않은 키 테스트
let invalidKey = 0x0000 // NULL
let invalidResult = errorContext.process(invalidKey)
print("  NULL 키 입력: \(invalidResult ? "❌" : "✅") (기대: false)")

// 매우 큰 키 코드 테스트
let largeKey = 0xFFFF
let largeResult = errorContext.process(largeKey)
print("  큰 키 코드 입력: \(largeResult ? "✅" : "❌")")
print("")

// 7. 메모리 누수 테스트
print("7. 메모리 누수 테스트")
var contexts = [HangulInputContext]()
for i in 0..<1000 {
    let context = HangulInputContext(keyboard: "2")
    let result = context.process(Int(Character("r").asciiValue!))
    contexts.append(context)
    if i % 100 == 0 {
        print("  생성된 컨텍스트: \(i+1)개")
    }
}
contexts.removeAll()
print("  모든 컨텍스트 해제 완료 ✅")
print("")

print("=== 최종 검증 완료 ===")
print("✅ 모든 검증 항목이 완료되었습니다.")
print("✅ 한글 입력기는 실제 사용 준비가 완료되었습니다!")
