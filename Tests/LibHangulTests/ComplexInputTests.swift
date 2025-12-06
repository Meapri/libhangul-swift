//
//  ComplexInputTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//
//  복잡한 자모 조합 및 이중 모음/자음 테스트
//

import XCTest
@testable import LibHangul

final class ComplexInputTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2") // 두벌식
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    func testDoubleJongseongCombinations() {
        // 테스트 케이스: (입력 키 배열, 기대되는 초/중/종성)
        let testCases: [([String], UCSChar, UCSChar, UCSChar)] = [
            // ㄱ + ㅅ = ㄳ (몫)
            (["a", "h", "r", "t"], 0x1106, 0x1169, 0x11AA), // ㅁ ㅗ ㄱ ㅅ -> 몫
            
            // ㄴ + ㅈ = ㄵ (앉)
            (["d", "k", "s", "w"], 0x110B, 0x1161, 0x11AC), // ㅇ ㅏ ㄴ ㅈ -> 앉
            
            // ㄴ + ㅎ = ㄶ (않)
            (["d", "k", "s", "g"], 0x110B, 0x1161, 0x11AD), // ㅇ ㅏ ㄴ ㅎ -> 않
            
            // ㄹ + ㄱ = ㄺ (닭)
            (["e", "k", "f", "r"], 0x1103, 0x1161, 0x11B0), // ㄷ ㅏ ㄹ ㄱ -> 닭
            
            // ㄹ + ㅁ = ㄻ (삶)
            (["t", "k", "f", "a"], 0x1109, 0x1161, 0x11B1), // ㅅ ㅏ ㄹ ㅁ -> 삶
            
            // ㄹ + ㅂ = ㄼ (밟)
            (["q", "k", "f", "q"], 0x1107, 0x1161, 0x11B2), // ㅂ ㅏ ㄹ ㅂ -> 밟
            
            // ㄹ + ㅅ = ㄽ (곬) -> ㄽ 예제가 드물어서 '곬' (외골수 할때 골)
            (["r", "h", "f", "t"], 0x1100, 0x1169, 0x11B3), // ㄱ ㅗ ㄹ ㅅ -> 곬
            
            // ㄹ + ㅌ = ㄾ (핥)
            (["g", "k", "f", "x"], 0x1112, 0x1161, 0x11B4), // ㅎ ㅏ ㄹ ㅌ -> 핥
            
            // ㄹ + ㅍ = ㄿ (읊)
            (["d", "m", "f", "v"], 0x110B, 0x1173, 0x11B5), // ㅇ ㅡ ㄹ ㅍ -> 읊
            
            // ㄹ + ㅎ = ㅀ (앓)
            (["d", "k", "f", "g"], 0x110B, 0x1161, 0x11B6), // ㅇ ㅏ ㄹ ㅎ -> 앓
            
            // ㅂ + ㅅ = ㅄ (없)
            (["d", "j", "q", "t"], 0x110B, 0x1165, 0x11B9)  // ㅇ ㅓ ㅂ ㅅ -> 없
        ]

        for (keys, expectedChoseong, expectedJungseong, expectedJongseong) in testCases {
            inputContext.reset()
            
            print("Testing combination: \(keys)")
            
            for key in keys {
                let charCode = Int(Character(key).asciiValue!)
                _ = inputContext.process(charCode)
            }
            
            let commit = inputContext.getCommitString()
            // 조합 중인 상태일 수도 있고 커밋된 상태일 수도 있음 (보통 마지막 입력에서 아직 조합 중)
            // 하지만 테스트 편의를 위해 flush 하여 확인
            let flushed = inputContext.flush()
            var result = commit
            result.append(contentsOf: flushed)
            
            XCTAssertEqual(result.count, 1, "Should produce exactly 1 syllable for inputs \(keys)")
            
            if let syllable = result.first {
                let decomposed = HangulCharacter.syllableToJamo(syllable)
                XCTAssertEqual(decomposed.choseong, expectedChoseong, "Choseong mismatch for \(keys)")
                XCTAssertEqual(decomposed.jungseong, expectedJungseong, "Jungseong mismatch for \(keys)")
                XCTAssertEqual(decomposed.jongseong, expectedJongseong, "Jongseong mismatch for \(keys)")
            }
        }
    }
    
    func testComplexChoseong() {
        // ㄲ, ㄸ, ㅃ, ㅆ, ㅉ (Shift 키 없이 입력 가능한 경우 테스트, 즉 이미 매핑된 키 말고 조합으로)
        // 두벌식에서는 보통 Shift키로 입력하지만, 엔진 차원에서 ㄱ+ㄱ=ㄲ 등을 지원하는지 확인
        // 현재 엔진은 초성 조합도 지원함 (HangulBuffer.combineChoseong)
        
        let testCases: [([String], UCSChar)] = [
            // ㄱ + ㄱ = ㄲ (깎) -> 종성 ㄲ 테스트 겸용
            (["R", "k", "R"], 0x1101) // ㄲ ㅏ ㄲ 
            // Note: 두벌식에서 ㄲ은 Shift+ㄱ (R) 이므로, 단일 입력으로 처리됨.
            // 초성 조합(ㄱ+ㄱ=ㄲ)은 표준 두벌식 동작은 아니지만 일부 입력기에서 지원.
            // 여기서는 이미 매핑된 Shift 키 입력 테스트
        ]
        
        for (keys, expectedChoseong) in testCases {
            inputContext.reset()
            for key in keys {
                let charCode = Int(Character(key).asciiValue!)
                _ = inputContext.process(charCode)
            }
            
            let result = inputContext.flush()
            if let syllable = result.first {
                let decomposed = HangulCharacter.syllableToJamo(syllable)
                XCTAssertEqual(decomposed.choseong, expectedChoseong)
            }
        }
    }
}
