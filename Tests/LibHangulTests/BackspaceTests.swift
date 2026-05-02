//
//  BackspaceTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//

import XCTest
@testable import LibHangul

final class BackspaceTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2")
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }
    
    func processInput(_ keys: String) {
        for char in keys {
            _ = inputContext.process(Int(char.asciiValue!))
        }
    }

    func testBackspaceJongseong() {
        // 각 -> 가
        processInput("rkr") // ㄱ ㅏ ㄱ = 각
        
        _ = inputContext.backspace()
        
        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "가")
    }
    
    func testBackspaceJungseong() {
        // 가 -> ㄱ
        processInput("rk") // ㄱ ㅏ = 가
        
        _ = inputContext.backspace()
        
        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "ㄱ")
    }

    func testBackspaceMoachigiSyllable() {
        // ㅏ + ㄱ = 가 -> ㄱ
        processInput("kr")

        _ = inputContext.backspace()

        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "ㄱ")
    }
    
    func testBackspaceChoseong() {
        // ㄱ -> (empty)
        processInput("r") // ㄱ
        
        _ = inputContext.backspace()
        
        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "")
    }

    func testBackspaceDoubleJongseong() {
        // 닭 -> 달
        processInput("ekfr") // ㄷ ㅏ ㄹ ㄱ = 닭
        
        _ = inputContext.backspace()
        
        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "달")
    }
    
    func testBackspaceDoubleJungseong() {
        // 와 -> 오
        processInput("dhk") // ㅇ ㅗ ㅏ = 와
        
        _ = inputContext.backspace()
        
        let result = inputContext.getPreeditString()
        XCTAssertEqual(result, "오")
    }

    func testBackspaceCompositeVowelIsFineGrainedByDefault() {
        // 몌 -> 며 when fine-grained backspace is enabled
        processInput("aul") // ㅁ ㅕ ㅣ = 몌

        _ = inputContext.backspace()

        XCTAssertEqual(inputContext.getPreeditString(), "며")
    }

    func testBackspaceCompositeVowelRemovesWholeVowelWhenFineGrainedDisabled() {
        // 몌 -> ㅁ when fine-grained backspace is disabled
        inputContext.setOption(.fineGrainedBackspace, value: false)
        processInput("aul") // ㅁ ㅕ ㅣ = 몌

        _ = inputContext.backspace()

        XCTAssertEqual(inputContext.getPreeditString(), "ㅁ")
    }

    func testBackspaceCompositeJongseongRemovesWholeJongseongWhenFineGrainedDisabled() {
        // 닭 -> 다 when fine-grained backspace is disabled
        inputContext.setOption(.fineGrainedBackspace, value: false)
        processInput("ekfr") // ㄷ ㅏ ㄹ ㄱ = 닭

        _ = inputContext.backspace()

        XCTAssertEqual(inputContext.getPreeditString(), "다")
    }
    
    func testBackspaceSyllableBoundary() {
        // 가나 -> 간
        processInput("rksk") // ㄱ ㅏ ㄴ ㅏ = 가나
        // At this point, "가" is committed or in buffer depending on engine logic, usually "가" is committed and "나" is preedit.
        // Actually for "rksk", it produces "가나".
        // Let's check the state.
        
        // Backspace should delete 'ㅏ' of '나' -> 'ㄴ'
        // So we expect "가ㄴ"
        
        _ = inputContext.backspace()
        
        let commit = inputContext.getCommitString()
        let preedit = inputContext.getPreeditString()
        
        // This assertion depends on whether "가" was auto-committed.
        // If "가" is committed, commit="가", preedit="ㄴ".
        // If not, preedit="가ㄴ".
        // Standard behavior: first char committed when second starts if resolved.
        
        let fullString = commit + preedit
        XCTAssertEqual(fullString, "가ㄴ")
    }
    
    func testBackspaceToPreviousSyllable() {
        // 아 -> (backspace) -> ㅇ -> (backspace) -> empty
        processInput("dk") // ㅇ ㅏ
        
        _ = inputContext.backspace() // ㅇ
        XCTAssertEqual(inputContext.getPreeditString(), "ㅇ")
        
        _ = inputContext.backspace() // empty
        XCTAssertEqual(inputContext.getPreeditString(), "")
    }
}
