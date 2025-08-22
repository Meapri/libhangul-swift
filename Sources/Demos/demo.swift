#!/usr/bin/env swift

import Foundation
import LibHangul

// LibHangul Swift 데모
print("LibHangul Swift 데모")
print("===================\n")

// 1. 기본적인 한글 입력
print("1. 기본적인 한글 입력:")
let context = LibHangul.createInputContext(keyboard: "2") // 두벌식

// "안녕" 입력 시뮬레이션
let input = "dkssud" // 두벌식 자판: 안녕
print("입력: \(input)")

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

print("결과: \(result)\n")

// 2. 한글 분석
print("2. 한글 분석:")
let text = "한글"
print("분석할 텍스트: \(text)")

for char in text {
    let isSyllable = LibHangul.isHangulSyllable(String(char))
    print("\(char): \(isSyllable ? "음절" : "음절 아님")")

    if isSyllable {
        let decomposed = LibHangul.decomposeHangul(String(char))
        print("  분해된 결과: \(decomposed)")
    }
}
print()

// 3. 한글 결합
print("3. 한글 결합:")
let syllable = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ")
print("ㄱ + ㅏ = \(syllable ?? "실패")")

let syllable2 = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ", jongseong: "ㄴ")
print("ㄱ + ㅏ + ㄴ = \(syllable2 ?? "실패")")
print()

// 4. 키보드 정보
print("4. 사용 가능한 키보드:")
let keyboards = LibHangul.availableKeyboards()
for keyboard in keyboards {
    print("  - \(keyboard.name) (\(keyboard.id))")
}
print()

print("데모 완료!")
