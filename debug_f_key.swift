//
//  debug_f_key.swift
//  Debug 'f' key processing issue
//

import Foundation
@testable import LibHangul

let inputContext = HangulInputContext(keyboard: "2")

// Test 'f' key specifically
let fKey = Int(Character("f").asciiValue!) // 102
let mappedJamo = inputContext.keyboard?.mapKey(fKey) ?? 0

print("'f' key (102) -> Jamo: 0x\(String(format: "%04X", mappedJamo))")
print("isJamo: \(HangulCharacter.isJamo(mappedJamo))")
print("isChoseong: \(HangulCharacter.isChoseong(mappedJamo))")
print("isJungseong: \(HangulCharacter.isJungseong(mappedJamo))")
print("isJongseong: \(HangulCharacter.isJongseong(mappedJamo))")

// Test process
let result = inputContext.process(fKey)
print("process result: \(result)")

// Check commit string
let commit = inputContext.getCommitString()
print("commit string: \(commit.map { String(format: "0x%04X", $0) })")
