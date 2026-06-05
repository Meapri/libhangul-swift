//
//  OptionAndDelegateTests.swift
//  LibHangulTests
//
//  combinationOnDoubleStroke 옵션, 델리게이트 콜백, 자모 검증 일관성 테스트
//

import XCTest
@testable import LibHangul

final class OptionAndDelegateTests: XCTestCase {

    /// 입력을 모두 처리한 뒤 커밋 + 남은 조합(flush)을 합친 최종 문자열을 반환
    private func fullOutput(_ ctx: HangulInputContext, _ keys: String) -> String {
        var out: [UCSChar] = []
        for ch in keys {
            _ = ctx.process(ch)
            out += ctx.getCommitString()
        }
        out += ctx.flush()
        return String(out.compactMap { UnicodeScalar($0) }.map { Character($0) })
    }

    // MARK: - combinationOnDoubleStroke

    func testDoubleStrokeOffKeepsSeparateConsonants() {
        let ctx = HangulInputContext(keyboard: "2")
        ctx.setOption(.combinationOnDoubleStroke, value: false)
        // 기본 동작: ㄱㄱ는 결합하지 않고 분리 유지
        XCTAssertEqual(fullOutput(ctx, "rrk"), "ㄱ가")
        XCTAssertEqual(fullOutput(ctx, "ee"), "ㄷㄷ")
    }

    func testDoubleStrokeOnFormsTenseConsonant() {
        let cases: [(String, String)] = [
            ("rrk", "까"), // ㄱㄱ→ㄲ
            ("eek", "따"), // ㄷㄷ→ㄸ (이전에 테이블이 ㄴ→ㄷ로 잘못돼 있던 부분)
            ("qqk", "빠"), // ㅂㅂ→ㅃ
            ("ttk", "싸"), // ㅅㅅ→ㅆ
            ("wwk", "짜")  // ㅈㅈ→ㅉ
        ]
        for (keys, expected) in cases {
            let ctx = HangulInputContext(keyboard: "2")
            ctx.setOption(.combinationOnDoubleStroke, value: true)
            XCTAssertEqual(fullOutput(ctx, keys), expected, "double-stroke \(keys)")
        }
    }

    func testDoubleStrokeDoesNotCombineNonTenseConsonant() {
        // ㄴㄴ은 된소리가 없으므로 결합하지 않고 분리 유지해야 한다
        let ctx = HangulInputContext(keyboard: "2")
        ctx.setOption(.combinationOnDoubleStroke, value: true)
        XCTAssertEqual(fullOutput(ctx, "ssk"), "ㄴ나")
    }

    func testDoubleStrokeNormalInputUnaffected() {
        let ctx = HangulInputContext(keyboard: "2")
        ctx.setOption(.combinationOnDoubleStroke, value: true)
        XCTAssertEqual(fullOutput(ctx, "rk"), "가")
        XCTAssertEqual(fullOutput(ctx, "rkr"), "각")
    }

    // MARK: - Delegate

    final class DelegateSpy: HangulInputContextDelegate {
        var processed: [(key: Int, result: Bool)] = []
        var transitions: [UCSChar] = []
        func hangulInputContext(_ context: HangulInputContext, didProcess key: Int, result: Bool) {
            processed.append((key, result))
        }
        func hangulInputContext(_ context: HangulInputContext, didTransition character: UCSChar, preedit: [UCSChar]) {
            transitions.append(character)
        }
    }

    func testDelegateFiresOnEveryKey() {
        let spy = DelegateSpy()
        let ctx = HangulInputContext(keyboard: "2")
        ctx.delegate = spy
        for ch in "rkrk" { _ = ctx.process(ch) }
        // 4개의 키마다 didProcess가 호출되어야 한다
        XCTAssertEqual(spy.processed.count, 4)
        XCTAssertEqual(spy.processed.map { $0.key }, [114, 107, 114, 107])
        // 두 번째 음절 시작 시 첫 음절 "가"가 커밋되어 전환 이벤트가 발생해야 한다
        XCTAssertTrue(spy.transitions.contains(0xAC00), "Expected a transition for 가 (U+AC00)")
    }

    func testDelegateFiresOnBackspace() {
        let spy = DelegateSpy()
        let ctx = HangulInputContext(keyboard: "2")
        ctx.delegate = spy
        _ = ctx.process(Character("r"))
        spy.processed.removeAll()
        _ = ctx.backspace()
        // 백스페이스는 ASCII 8로 알림
        XCTAssertEqual(spy.processed.last?.key, 8)
        XCTAssertEqual(spy.processed.last?.result, true)
    }

    // MARK: - 자모 검증 일관성 (validateJamo가 의존하는 불변식)

    func testIsJamoAcceptsExtendedRanges() {
        // validateJamo는 이제 HangulCharacter.isJamo에 위임한다.
        // 확장(옛한글) 자모 영역이 자모로 인정되어야 검증에서 거부되지 않는다.
        XCTAssertTrue(HangulCharacter.isJamo(0xA960), "확장 초성 A")  // 옛한글 초성
        XCTAssertTrue(HangulCharacter.isJamo(0xD7B0), "확장 중성 B")  // 옛한글 중성
        XCTAssertTrue(HangulCharacter.isJamo(0xD7CB), "확장 종성 B")  // 옛한글 종성
        // 일반 영문/숫자는 자모가 아니다
        XCTAssertFalse(HangulCharacter.isJamo(UCSChar(Character("a").asciiValue!)))
    }
}
