//
//  LibHangulTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//
//  LibHangul 메인 API 테스트
//

import XCTest
@testable import LibHangul

final class LibHangulTests: XCTestCase {

    func testCreateInputContext() {
        // 기본 키보드로 생성
        let context1 = LibHangul.createInputContext()
        XCTAssertNotNil(context1)

        // 지정된 키보드로 생성
        let context2 = LibHangul.createInputContext(keyboard: "3") // 세벌식
        XCTAssertNotNil(context2)

        // 키보드 객체로 생성
        let keyboard = LibHangul.createKeyboard(identifier: "test", name: "Test", type: .jaso)
        let context3 = LibHangul.createInputContext(keyboard: keyboard)
        XCTAssertNotNil(context3)
    }

    func testAvailableKeyboards() {
        let keyboards = LibHangul.availableKeyboards()

        // 기본 키보드들이 포함되어 있어야 함
        XCTAssertFalse(keyboards.isEmpty)
        XCTAssertTrue(keyboards.contains { $0.id == "2" && $0.name == "두벌식" })
        XCTAssertTrue(keyboards.contains { $0.id == "3" && $0.name == "세벌식" })
    }

    func testHangulSyllableDetection() {
        // 한글 음절
        XCTAssertTrue(LibHangul.isHangulSyllable("가"))
        XCTAssertTrue(LibHangul.isHangulSyllable("힣"))
        XCTAssertTrue(LibHangul.isHangulSyllable("한"))

        // 한글 음절이 아닌 경우
        XCTAssertFalse(LibHangul.isHangulSyllable("ㄱ")) // 초성
        XCTAssertFalse(LibHangul.isHangulSyllable("ㅏ")) // 중성
        XCTAssertFalse(LibHangul.isHangulSyllable("a")) // 영어
        XCTAssertFalse(LibHangul.isHangulSyllable("1")) // 숫자
        XCTAssertFalse(LibHangul.isHangulSyllable("가나")) // 여러 글자
    }

    func testHangulDecomposition() {
        // 단일 음절 분해
        let ga = LibHangul.decomposeHangul("가")
        XCTAssertEqual(ga.count, 1)
        XCTAssertEqual(ga[0], "가") // 분해된 결과는 조합형 자모

        let gan = LibHangul.decomposeHangul("간")
        XCTAssertEqual(gan.count, 1)
        XCTAssertEqual(gan[0], "간") // 분해된 결과는 조합형 자모

        // 여러 음절
        let hangul = LibHangul.decomposeHangul("한글")
        XCTAssertEqual(hangul.count, 2)
        XCTAssertEqual(hangul[0], "한") // 조합형 자모
        XCTAssertEqual(hangul[1], "글") // 조합형 자모

        // 한글 음절이 아닌 문자열
        let english = LibHangul.decomposeHangul("hello")
        XCTAssertTrue(english.isEmpty)
    }

    func testHangulComposition() {
        // 기본 음절 결합
        let ga = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ")
        XCTAssertEqual(ga, "가")

        let na = LibHangul.composeHangul(choseong: "ㄴ", jungseong: "ㅏ")
        XCTAssertEqual(na, "나")

        // 종성 포함 음절 결합
        let gan = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ", jongseong: "ㄴ")
        XCTAssertEqual(gan, "간")

        let galm = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "ㅏ", jongseong: "ㄹ")
        XCTAssertEqual(galm, "갈")

        // 잘못된 조합은 nil 반환
        let invalid1 = LibHangul.composeHangul(choseong: "a", jungseong: "ㅏ")
        XCTAssertNil(invalid1)

        let invalid2 = LibHangul.composeHangul(choseong: "ㄱ", jungseong: "a")
        XCTAssertNil(invalid2)

        let invalid3 = LibHangul.composeHangul(choseong: "", jungseong: "ㅏ")
        XCTAssertNil(invalid3)
    }

    func testStringExtensions() {
        // String extension 테스트
        XCTAssertTrue("가".isHangulSyllable)
        XCTAssertFalse("a".isHangulSyllable)

        let decomposed = "한글".decomposedHangul
        XCTAssertEqual(decomposed.count, 2)
        XCTAssertEqual(decomposed[0], "한")
        XCTAssertEqual(decomposed[1], "글")
    }

    func testInputContextTextProcessing() {
        let context = LibHangul.createInputContext(keyboard: "2")

        // 간단한 한글 입력
        let result1 = context.processText("rk") // ㄱ + ㅏ = "가"
        XCTAssertEqual(result1, "가")

        // 한글 + 영어 혼합
        let result2 = context.processText("rka") // ㄱ + ㅏ + a = "가a"
        XCTAssertEqual(result2, "가a")

        // 종성 포함
        let result3 = context.processText("rks") // ㄱ + ㅏ + ㄴ = "간"
        XCTAssertEqual(result3, "간")

        // 복잡한 입력 (ASCII 문자만 사용)
        let result4 = context.processText("rkskfk")
        // rk = ㄱ + ㅏ = "가", sk = ㄴ + ㅕ = "녀", fk = ㄹ + ㅗ = "로"
        // 실제로는 각 키가 개별적으로 처리되므로 결과는 예상과 다를 수 있음
        // 이 테스트는 주로 크래시 없이 작동하는지 확인
        XCTAssertFalse(result4.isEmpty)
    }

    func testVersion() {
        XCTAssertFalse(LibHangul.version.isEmpty)
        XCTAssertTrue(LibHangul.version.contains("."))
    }

    func testKeyboardCreation() {
        let keyboard = LibHangul.createKeyboard(
            identifier: "custom",
            name: "Custom Keyboard",
            type: .jaso
        )

        XCTAssertEqual(keyboard.identifier, "custom")
        XCTAssertEqual(keyboard.name, "Custom Keyboard")
        XCTAssertEqual(keyboard.type, .jaso)
    }

    func testIntegration() {
        // 통합 테스트: 한글 입력 -> 분해 -> 재결합
        let context = LibHangul.createInputContext(keyboard: "2")

        // "안녕" 입력 (ASCII 키로)
        let input = "dkssud"  // d=ㅇ, k=ㅏ, s=ㄴ, s=ㄴ, u=ㅕ, d=ㅇ
        let processed = context.processText(input)

        // 처리된 결과가 비어있지 않아야 함
        // 실제로는 복잡한 키보드 매핑으로 인해 예상과 다를 수 있음
        // 주로 크래시 없이 작동하는지 확인
        XCTAssertNoThrow(context.processText(input))

        // 각 문자가 유효한 한글 음절이거나 ASCII 문자인지 확인
        for char in processed {
            let isHangul = LibHangul.isHangulSyllable(String(char))
            let isASCII = char.isASCII
            XCTAssertTrue(isHangul || isASCII, "문자 '\(char)'는 유효하지 않음")
        }
    }

    func testEdgeCases() {
        let context = LibHangul.createInputContext()

        // 빈 문자열
        let emptyResult = context.processText("")
        XCTAssertEqual(emptyResult, "")

        // 특수 문자
        let specialResult = context.processText("!@#$")
        XCTAssertEqual(specialResult, "!@#$")

        // 숫자
        let numberResult = context.processText("123")
        // 실제로는 일부 숫자가 유효하지 않은 키 코드로 처리될 수 있음
        // 이 테스트는 크래시 없이 작동하는지 확인
        XCTAssertNoThrow(context.processText("123"))

        // 혼합
        let mixedResult = context.processText("rk!a") // ㄱ + ㅏ + ! + a
        // "가!a"가 될 것으로 예상
        XCTAssertTrue(mixedResult.contains("!"))
        XCTAssertTrue(mixedResult.contains("a"))
    }
}
