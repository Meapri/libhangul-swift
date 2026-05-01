//
//  BasicCompositionTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//

import XCTest
@testable import LibHangul

final class BasicCompositionTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2") // 2-set keyboard
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    func testSimpleCv() {
        // ㄱ + ㅏ = 가
        let inputs = ["r", "k"]
        let expected = "가"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }

    func testMoachigiVowelFirstCv() {
        // ㅏ + ㄱ = 가
        let inputs = ["k", "r"]
        let expected = "가"

        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }

        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }

    func testMoachigiCanBeDisabled() {
        inputContext.setOption(.autoReorder, value: false)

        _ = inputContext.process(Int(Character("k").asciiValue!))
        _ = inputContext.process(Int(Character("r").asciiValue!))

        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertNotEqual(result, "가")
    }
    
    func testSimpleCvc() {
        // ㄱ + ㅏ + ㄱ = 각
        let inputs = ["r", "k", "r"]
        let expected = "각"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }
    
    func testSyllableSeparation() {
        // ㄱ + ㅏ + ㄱ + ㅏ = 가가
        let inputs = ["r", "k", "r", "k"]
        let expected = "가가"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }
    
    func testDoubleConsonantInput() {
        // ㄲ + ㅏ = 까 (shift + r)
        let inputs = ["R", "k"]
        let expected = "까"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }
    
    func testDoubleVowelInput() {
        // ㅇ + ㅘ = 와 (h + k)
        // h, k = ㅗ, ㅏ -> ㅘ
        let inputs = ["d", "h", "k"]
        let expected = "와"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        XCTAssertEqual(result, expected)
    }
}
