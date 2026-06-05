//
//  KeyboardLoadingTests.swift
//  LibHangulTests
//
//  데이터 기반 자판 로딩 및 옛한글 조합 테스트
//

import XCTest
@testable import LibHangul

final class KeyboardLoadingTests: XCTestCase {

    private func fullOutput(_ ctx: HangulInputContext, _ keys: String) -> String {
        var out: [UCSChar] = []
        for ch in keys {
            _ = ctx.process(ch)
            out += ctx.getCommitString()
        }
        out += ctx.flush()
        return String(out.compactMap { UnicodeScalar($0) }.map { Character($0) })
    }

    private func fullOutputScalars(_ ctx: HangulInputContext, _ keys: String) -> [UCSChar] {
        var out: [UCSChar] = []
        for ch in keys {
            _ = ctx.process(ch)
            out += ctx.getCommitString()
        }
        out += ctx.flush()
        return out
    }

    // MARK: - 번들 리소스 로딩

    func testAllBundledKeyboardsLoad() {
        for file in HangulResourceLoader.bundledKeyboardFiles {
            let kb = HangulResourceLoader.loadKeyboard(file: file)
            XCTAssertNotNil(kb, "자판 로드 실패: \(file)")
        }
    }

    func testCombinationTableParsing() {
        // 옛한글(full) 테이블: ㄱ+ㄷ → ᄓ(U+115A), ㄱ+ㄱ → ㄲ
        let full = HangulResourceLoader.loadKeyboard(file: "hangul-keyboard-2y.xml")?.combination
        XCTAssertNotNil(full)
        XCTAssertEqual(full?.combine(0x1100, 0x1103), 0x115A)
        XCTAssertEqual(full?.combine(0x1100, 0x1100), 0x1101)

        // 현대(default) 테이블: ㄱ+ㄷ 규칙 없음, ㄱ받침+ㅅ받침 → ㄳ
        let def = HangulResourceLoader.loadKeyboard(file: "hangul-keyboard-39.xml")?.combination
        XCTAssertNotNil(def)
        XCTAssertNil(def?.combine(0x1100, 0x1103))
        XCTAssertEqual(def?.combine(0x11A8, 0x11BA), 0x11AA)
    }

    func testNewKeyboardsRegistered() {
        let ids = LibHangul.availableKeyboards().map { $0.id }
        for id in ["2", "3", "2y", "3y", "32", "39", "3f", "3s", "ahn", "ro"] {
            XCTAssertTrue(ids.contains(id), "자판 미등록: \(id)")
        }
    }

    // MARK: - 현대 한글 (세벌식 신규 자판)

    func testSebeolsik390ModernHangul() {
        // 39: j=ㅇ, f=ㅏ, s=ㄴ → 안
        XCTAssertEqual(fullOutput(HangulInputContext(keyboard: "39"), "jfs"), "안")
    }

    // MARK: - 옛한글 조합

    func testDubeolsikYetInitialCluster() {
        // 2y: ㄱ(r) + ㄷ(e) → 초성 클러스터 ᄓ (U+115A)
        XCTAssertEqual(fullOutputScalars(HangulInputContext(keyboard: "2y"), "re"), [0x115A])
    }

    func testDubeolsikYetAraea() {
        // 2y: ㄱ(r) + ㆍ아래아(K) → 조합용 자모 U+1100 U+119E (완성형 합성 불가)
        XCTAssertEqual(fullOutputScalars(HangulInputContext(keyboard: "2y"), "rK"), [0x1100, 0x119E])
    }

    func testSebeolsikYetModernAndAraea() {
        // 3y 현대 음절: k=ㄱ, f=ㅏ, s=ㄴ → 간
        XCTAssertEqual(fullOutput(HangulInputContext(keyboard: "3y"), "kfs"), "간")
        // 3y 아래아: ㄱ(k) + ㆍ(G)
        XCTAssertEqual(fullOutputScalars(HangulInputContext(keyboard: "3y"), "kG"), [0x1100, 0x119E])
    }

    // MARK: - 회귀: 레거시 "2"는 옛한글 클러스터를 만들지 않는다

    func testLegacyDubeolsikNoCluster() {
        // 표준 두벌식 "2"에서 ㄱ+ㄷ(re)는 클러스터가 아니라 분리 (ㄱ commit, ㄷ 시작)
        let out = fullOutput(HangulInputContext(keyboard: "2"), "re")
        XCTAssertEqual(out, "ㄱㄷ")
    }
}
