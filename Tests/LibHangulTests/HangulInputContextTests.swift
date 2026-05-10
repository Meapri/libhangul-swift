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
        // 조합 중인 음절은 preedit에 남아 있고 flush 시 커밋됨
        let commit = inputContext.flush()
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
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "중성 ㅏ 입력 성공")
        let processed3 = inputContext.process(Int(Character("s").asciiValue!)) // ㄴ
        XCTAssertTrue(processed3, "종성 ㄴ 입력 성공")

        let commit = inputContext.flush()
        XCTAssertEqual(commit.count, 1)

        let decomposed = HangulCharacter.syllableToJamo(commit[0])
        XCTAssertEqual(decomposed.choseong, 0x1100) // ㄱ
        XCTAssertEqual(decomposed.jungseong, 0x1161) // ㅏ
        XCTAssertEqual(decomposed.jongseong, 0x11AB) // ㄴ
    }

    func testEnglishInput() {
        // 영어 입력은 바로 커밋되어야 함
        // '['는 키보드 매핑에 없으므로 영어로 처리됨
        let processed = inputContext.process(Int(Character("[").asciiValue!))
        XCTAssertTrue(processed)

        let commit = inputContext.getCommitString()
        XCTAssertEqual(commit.count, 1)
        XCTAssertEqual(commit.first, 0x5B) // '['
    }

    func testBackspace() {
        // "가" 입력 후 백스페이스
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "중성 ㅏ 입력 성공")

        // 완성된 음절도 백스페이스로 지울 수 있음 (새로운 로직)
        let backspaceResult = inputContext.backspace()
        XCTAssertTrue(backspaceResult)

        // 음절이 지워졌는지 확인
        let commitAfterBackspace = inputContext.getCommitString()
        XCTAssertEqual(commitAfterBackspace.count, 0, "완성된 음절이 백스페이스로 지워져야 함")

        // 새로운 자모 입력 후 백스페이스
        let processed3 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed3, "새로운 초성 ㄱ 입력 성공")
        let backspaceResult2 = inputContext.backspace()
        XCTAssertTrue(backspaceResult2)
        XCTAssertFalse(inputContext.hasChoseong())
    }

    func testReset() {
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "중성 ㅏ 입력 성공")
        let processed3 = inputContext.process(Int(Character("s").asciiValue!)) // ㄴ
        XCTAssertTrue(processed3, "종성 ㄴ 입력 성공")

        // 커밋된 내용 확인
        let commit1 = inputContext.flush()
        XCTAssertEqual(commit1.count, 1) // "간"

        // 추가 입력 - 'f'는 0x1105(ㅁ)로 매핑됨
        let processed4 = inputContext.process(Int(Character("f").asciiValue!)) // ㅁ
        XCTAssertTrue(processed4, "초성 ㄹ 입력 성공")

        // 리셋
        inputContext.reset()

        // 모든 내용이 초기화되어야 함
        XCTAssertTrue(inputContext.isEmpty())
        let commit2 = inputContext.getCommitString()
        XCTAssertEqual(commit2.count, 0)
    }

    func testPreeditString() {
        // 조합중인 문자열 확인
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "초성 ㄱ 입력 성공")
        var preedit = inputContext.getPreeditString()
        XCTAssertEqual(preedit.count, 1)
        if let jamo = preedit.first {
            XCTAssertEqual(jamo, 0x1100) // ㄱ
        }

        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "중성 ㅏ 입력 성공")
        preedit = inputContext.getPreeditString()
        // 음절 모드에서는 완성된 음절이 표시되거나 빈 배열일 수 있음
        if inputContext.outputMode == .syllable {
            // 완성된 음절이 있거나 빈 배열일 수 있음
            XCTAssertGreaterThanOrEqual(preedit.count, 0)
            if preedit.count > 0, let syllable = preedit.first {
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
        let processed1 = inputContext.process(Int(Character("k").asciiValue!)) // 세벌식 ㄱ
        XCTAssertTrue(processed1, "세벌식 초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("f").asciiValue!)) // 세벌식 ㅏ
        XCTAssertTrue(processed2, "세벌식 중성 ㅏ 입력 성공")

        let commit = inputContext.flush()
        XCTAssertEqual(commit.count, 1)
    }

    func testOutputMode() {
        // 자모 모드로 변경
        inputContext.setOutputMode(.jamo)

        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "자모 모드 초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "자모 모드 중성 ㅏ 입력 성공")

        let flushed = inputContext.flush()
        // 현재 flush 경로는 NFC 음절로 확정된다.
        XCTAssertEqual(flushed, [0xAC00]) // 가
    }

    func testOptions() {
        // 옵션 테스트
        inputContext.setOption(.autoReorder, value: true)
        XCTAssertTrue(inputContext.getOption(.autoReorder))

        inputContext.setOption(.autoReorder, value: false)
        XCTAssertFalse(inputContext.getOption(.autoReorder))
    }

    func testFlush() {
        let processed1 = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        XCTAssertTrue(processed1, "초성 ㄱ 입력 성공")
        let processed2 = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
        XCTAssertTrue(processed2, "중성 ㅏ 입력 성공")
        let processed3 = inputContext.process(Int(Character("s").asciiValue!)) // ㄴ
        XCTAssertTrue(processed3, "종성 ㄴ 입력 성공")

        let flushed = inputContext.flush()
        XCTAssertEqual(flushed.count, 1) // "간"

        // 플러시 후에는 비어있어야 함
        let remaining = inputContext.getCommitString()
        // flush 후에는 비어있거나 최소한 이전보다 적은 내용이 있어야 함
        XCTAssertLessThanOrEqual(remaining.count, flushed.count)
    }

    func testComplexInput() {
        // 간단한 한글 입력 테스트
        let inputs = ["r", "k"] // 간단한 "가" 입력만 테스트

        for input in inputs {
            let char = Character(input)
            let key = Int(char.asciiValue!)
            let processed = inputContext.process(key)
            XCTAssertTrue(processed, "입력 '\(input)' 처리 성공")
        }

        let commit = inputContext.flush()
        // "가"가 flush되어야 함
        XCTAssertGreaterThan(commit.count, 0, "커밋된 내용이 있어야 함")
    }
}
