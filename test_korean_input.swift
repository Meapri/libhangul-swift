#!/usr/bin/env swift

import Foundation
import LibHangul

print("한글 입력 실전 테스트")
print("==================\n")

// 1. 기본 한글 입력 테스트
print("1. 기본 한글 입력 테스트:")
let context = LibHangul.createInputContextLegacy(keyboard: "2")

print("테스트 1: '안' 입력")
let input1 = "dk"  // d(ㅇ) + k(ㅏ)
var result1 = ""
for char in input1 {
    let key = Int(char.asciiValue ?? 0)
    if context.process(key) {
        let commit = context.getCommitString()
        if !commit.isEmpty {
            let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            result1 += text
        }
    }
}

let remaining1 = context.flush()
if !remaining1.isEmpty {
    let text = String(remaining1.compactMap { UnicodeScalar($0) }.map { Character($0) })
    result1 += text
}

print("  입력: '\(input1)'")
print("  결과: '\(result1)'")
print("  성공: \(result1 == "안")")

// 2. '녕' 입력 테스트
print("\n테스트 2: '녕' 입력")
let context2 = LibHangul.createInputContextLegacy(keyboard: "2")
let input2 = "sld"  // s(ㄷ) + l(ㅕ) + d(ㅇ)
var result2 = ""
for char in input2 {
    let key = Int(char.asciiValue ?? 0)
    if context2.process(key) {
        let commit = context2.getCommitString()
        if !commit.isEmpty {
            let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            result2 += text
        }
    }
}

let remaining2 = context2.flush()
if !remaining2.isEmpty {
    let text = String(remaining2.compactMap { UnicodeScalar($0) }.map { Character($0) })
    result2 += text
}

print("  입력: '\(input2)'")
print("  결과: '\(result2)'")
print("  성공: \(result2 == "녕")")

// 3. '안녕하세요' 입력 테스트
print("\n테스트 3: '안녕하세요' 입력")
let context3 = LibHangul.createInputContextLegacy(keyboard: "2")
let input3 = "dkssudgksrnldj"  // 안녕하세요 두벌식
var result3 = ""
for char in input3 {
    let key = Int(char.asciiValue ?? 0)
    if context3.process(key) {
        let commit = context3.getCommitString()
        if !commit.isEmpty {
            let text = String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            result3 += text
        }
    }
}

let remaining3 = context3.flush()
if !remaining3.isEmpty {
    let text = String(remaining3.compactMap { UnicodeScalar($0) }.map { Character($0) })
    result3 += text
}

print("  입력: '\(input3)'")
print("  결과: '\(result3)'")
print("  기대: '안녕하세요' 또는 유사한 결과")

// 4. 한글 분석 테스트
print("\n4. 한글 분석 테스트:")
let testText = "한글"
print("분석할 텍스트: \(testText)")

for char in testText {
    let isSyllable = LibHangul.isHangulSyllable(String(char))
    print("  '\(char)': \(isSyllable ? "음절" : "음절 아님")")

    if isSyllable {
        let decomposed = LibHangul.decomposeHangul(String(char))
        print("    분해된 결과: \(decomposed)")
    }
}

// 5. 한글 결합 테스트
print("\n5. 한글 결합 테스트:")
let syllable1 = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ")
print("  ㄱ + ㅏ = '\(syllable1 ?? "실패")'")

let syllable2 = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ", jongseong: "ㄴ")
print("  ㄱ + ㅏ + ㄴ = '\(syllable2 ?? "실패")'")

print("\n테스트 완료!")

