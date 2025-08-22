//
//  HangulInputContextTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//
//  한글 입력 컨텍스트 테스트
//

import XCTest
@testable import LibHangul

final class HangulInputContextTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2") // 두벌식
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    func testBasicHangulInput() {
        // "가" 입력: ㄱ + ㅏ
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1)
        XCTAssertTrue(inputContext.hasChoseong())
        XCTAssertFalse(inputContext.hasJungseong())
        XCTAssertFalse(inputContext.hasJongseong())

        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2)
        XCTAssertTrue(inputContext.hasChoseong())
        XCTAssertTrue(inputContext.hasJungseong())
        XCTAssertFalse(inputContext.hasJongseong())

        // 조합이 완료되면 커밋됨
        let commit = inputContext.getCommitString()
        XCTAssertEqual(commit.count, 1)
        if let syllable = commit.first {
            let decomposed = HangulCharacter.syllableToJamo(syllable)
            XCTAssertEqual(decomposed.choseong, 0x1100) // ㄱ
            XCTAssertEqual(decomposed.jungseong, 0x1161) // ㅏ
            XCTAssertEqual(decomposed.jongseong, 0)
        }
    }

    func testHangulWithJongseong() {
        // "간" 입력: ㄱ + ㅏ + ㄴ
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        inputContext.process(Int(Character("s").asciiValue!)) // ㄴ

        let commit = inputContext.getCommitString()
        XCTAssertEqual(commit.count, 1)
        if let syllable = commit.first {
            let decomposed = HangulCharacter.syllableToJamo(syllable)
            XCTAssertEqual(decomposed.choseong, 0x1100) // ㄱ
            XCTAssertEqual(decomposed.jungseong, 0x1161) // ㅏ
            XCTAssertEqual(decomposed.jongseong, 0x11AB) // ㄴ
        }
    }

    func testEnglishInput() {
        // 영어 입력은 바로 커밋되어야 함
        let processed = inputContext.process(Int(Character("a").asciiValue!))
        XCTAssertTrue(processed)

        let commit = inputContext.getCommitString()
        XCTAssertEqual(commit.count, 1)
        XCTAssertEqual(commit.first, 0x61) // 'a'
    }

    func testBackspace() {
        // "가" 입력 후 백스페이스
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ

        // 조합이 완료되었으므로 백스페이스로는 지울 수 없음
        let backspaceResult = inputContext.backspace()
        XCTAssertFalse(backspaceResult)

        // 새로운 자모 입력 후 백스페이스
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        let backspaceResult2 = inputContext.backspace()
        XCTAssertTrue(backspaceResult2)
        XCTAssertFalse(inputContext.hasChoseong())
    }

    func testReset() {
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        inputContext.process(Int(Character("s").asciiValue!)) // ㄴ

        // 커밋된 내용 확인
        let commit1 = inputContext.getCommitString()
        XCTAssertEqual(commit1.count, 1) // "간"

        // 추가 입력
        inputContext.process(Int(Character("f").asciiValue!)) // ㅁ

        // 리셋
        inputContext.reset()

        // 모든 내용이 초기화되어야 함
        XCTAssertTrue(inputContext.isEmpty())
        let commit2 = inputContext.getCommitString()
        XCTAssertEqual(commit2.count, 0)
    }

    func testPreeditString() {
        // 조합중인 문자열 확인
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        var preedit = inputContext.getPreeditString()
        XCTAssertEqual(preedit.count, 1)
        if let jamo = preedit.first {
            XCTAssertEqual(jamo, 0x1100) // ㄱ
        }

        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        preedit = inputContext.getPreeditString()
        // 음절 모드에서는 완성된 음절이 표시됨
        if inputContext.outputMode == .syllable {
            XCTAssertEqual(preedit.count, 1)
            if let syllable = preedit.first {
                let decomposed = HangulCharacter.syllableToJamo(syllable)
                XCTAssertEqual(decomposed.choseong, 0x1100) // ㄱ
                XCTAssertEqual(decomposed.jungseong, 0x1161) // ㅏ
            }
        }
    }

    func testKeyboardSwitching() {
        // 두벌식에서 세벌식으로 변경
        inputContext.setKeyboard(with: "3")

        // 세벌식 자판으로 입력
        inputContext.process(Int(Character("k").asciiValue!)) // 세벌식 ㄱ
        inputContext.process(Int(Character("f").asciiValue!)) // 세벌식 ㅏ

        let commit = inputContext.getCommitString()
        XCTAssertEqual(commit.count, 1)
    }

    func testOutputMode() {
        // 자모 모드로 변경
        inputContext.setOutputMode(.jamo)

        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ

        let commit = inputContext.getCommitString()
        // 자모 모드에서는 개별 자모가 커밋되어야 함
        XCTAssertEqual(commit.count, 2)
        XCTAssertEqual(commit[0], 0x1100) // ㄱ
        XCTAssertEqual(commit[1], 0x1161) // ㅏ
    }

    func testOptions() {
        // 옵션 테스트
        inputContext.setOption(.autoReorder, value: true)
        XCTAssertTrue(inputContext.getOption(.autoReorder))

        inputContext.setOption(.autoReorder, value: false)
        XCTAssertFalse(inputContext.getOption(.autoReorder))
    }

    func testFlush() {
        inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        inputContext.process(Int(Character("s").asciiValue!)) // ㄴ

        let flushed = inputContext.flush()
        XCTAssertEqual(flushed.count, 1) // "간"

        // 플러시 후에는 비어있어야 함
        let remaining = inputContext.getCommitString()
        XCTAssertEqual(remaining.count, 0)
    }

    func testComplexInput() {
        // 복잡한 한글 입력 테스트
        let inputs = ["r", "k", "s", "f", "r", "R", "k", "i"] // 간 + ㅁ + ㄲ + ㅑ

        for input in inputs {
            let char = Character(input)
            let key = Int(char.asciiValue!)
            inputContext.process(key)
        }

        let commit = inputContext.getCommitString()
        // "간", "ㅁ", "ㄲ", "ㅑ"가 각각 커밋되어야 함
        XCTAssertEqual(commit.count, 4)
    }
}
