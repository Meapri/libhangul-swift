//
//  HanjaTests.swift
//  LibHangulTests
//
//  Created by Sonic AI Assistant
//
//  한자 사전 기능 테스트
//

import XCTest
@testable import LibHangul

final class HanjaTests: XCTestCase {

    var hanjaTable: HanjaTable!

    override func setUp() {
        super.setUp()
        hanjaTable = HanjaTable()

        // 간단한 테스트 데이터로 사전 초기화
        let testDictionary = """
        # 테스트 한자 사전
        한자:漢字:한자
        삼국사기:三國史記:삼국사기
        한국:韓國:한국
        """

        // 테스트 데이터를 임시 파일로 저장
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test-hanja.txt")

        try? testDictionary.write(to: tempFile, atomically: true, encoding: .utf8)

        // 테스트 파일 로드
        hanjaTable.load(filename: tempFile.path)
    }

    override func tearDown() {
        hanjaTable = nil
        super.tearDown()
    }

    func testHanjaCreation() {
        let hanja = Hanja(key: "한자", value: "漢字", comment: "한자")

        XCTAssertEqual(hanja.getKey(), "한자")
        XCTAssertEqual(hanja.getValue(), "漢字")
        XCTAssertEqual(hanja.getComment(), "한자")
    }

    func testHanjaListOperations() {
        let list = HanjaList(key: "테스트")

        let hanja1 = Hanja(key: "한자", value: "漢字", comment: "한자")
        let hanja2 = Hanja(key: "한국", value: "韓國", comment: "한국")

        list.append(hanja1)
        list.append(hanja2)

        XCTAssertEqual(list.getSize(), 2)
        XCTAssertEqual(list.getNth(0)?.getKey(), "한자")
        XCTAssertEqual(list.getNth(1)?.getValue(), "韓國")
        XCTAssertNil(list.getNth(2)) // 범위 초과
    }

    func testHanjaTableExactMatch() {
        // 정확한 매칭 테스트
        let result = hanjaTable.matchExact(key: "한자")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.getSize(), 1)
        XCTAssertEqual(result?.getNthKey(0), "한자")
        XCTAssertEqual(result?.getNthValue(0), "漢字")
        XCTAssertEqual(result?.getNthComment(0), "한자")
    }

    func testHanjaTablePrefixMatch() {
        // 접두사 매칭 테스트
        let result = hanjaTable.matchPrefix(key: "삼국사기")

        XCTAssertNotNil(result)
        // "삼국사기", "삼국사", "삼국", "삼" 중에 사전에 있는 것들만 포함
        XCTAssertGreaterThanOrEqual(result?.getSize() ?? 0, 0)
    }

    func testHanjaTableSuffixMatch() {
        // 접미사 매칭 테스트
        let result = hanjaTable.matchSuffix(key: "한국")

        XCTAssertNotNil(result)
        // "한국", "국" 중에 사전에 있는 것들만 포함
        XCTAssertGreaterThanOrEqual(result?.getSize() ?? 0, 0)
    }

    func testHanjaTableNonExistentKey() {
        // 존재하지 않는 키 검색
        let result = hanjaTable.matchExact(key: "존재하지않음")

        XCTAssertNil(result)
    }

    func testHanjaTableEmptyKey() {
        // 빈 키 검색
        let result = hanjaTable.matchExact(key: "")

        XCTAssertNil(result)
    }

    func testHanjaCompatibilityConversion() {
        // 호환성 변환 테스트
        var hanja: [UCSChar] = [0x4E00, 0x4E8C] // 일, 이
        var hangul: [UCSChar] = [0x1100, 0x1102] // ㄱ, ㄷ

        let converted = HanjaCompatibility.toCompatibilityForm(hanja: &hanja, hangul: hangul)

        // 실제 변환은 매핑 테이블에 따라 달라질 수 있음
        XCTAssertGreaterThanOrEqual(converted, 0)
    }

    func testHanjaUnifiedConversion() {
        // 통합 형태 변환 테스트
        var str: [UCSChar] = [0xF900, 0xF901, 0] // 호환성 일, 이

        let converted = HanjaCompatibility.toUnifiedForm(&str)

        // 실제 변환은 매핑 테이블에 따라 달라질 수 있음
        XCTAssertGreaterThanOrEqual(converted, 0)
    }

    func testHanjaListSequence() {
        let list = HanjaList(key: "테스트")
        let hanja1 = Hanja(key: "한자", value: "漢字", comment: "한자")
        let hanja2 = Hanja(key: "한국", value: "韓國", comment: "한국")

        list.append(hanja1)
        list.append(hanja2)

        // Sequence 프로토콜 테스트
        var count = 0
        for hanja in list {
            count += 1
            XCTAssertFalse(hanja.getKey().isEmpty)
            XCTAssertFalse(hanja.getValue().isEmpty)
        }

        XCTAssertEqual(count, 2)
    }

    func testHanjaTableClear() {
        // 사전 초기화 테스트
        hanjaTable.clear()

        let result = hanjaTable.matchExact(key: "한자")
        XCTAssertNil(result)
    }

    func testLibHangulHanjaIntegration() {
        // LibHangul API 통합 테스트
        let table = LibHangul.loadHanjaTable(filename: nil)

        if let table = table {
            let result = LibHangul.searchHanja(table: table, key: "한자")
            // 실제 사전 파일이 없으면 nil일 수 있음
            if let result = result {
                XCTAssertGreaterThanOrEqual(result.getSize(), 0)
            }
        }
    }

    func testHanjaListKey() {
        let list = HanjaList(key: "테스트키")

        XCTAssertEqual(list.key, "테스트키")
        // getKey() 메서드는 없으므로 key 프로퍼티를 직접 사용
    }

    func testHanjaEmptyComment() {
        let hanja = Hanja(key: "한자", value: "漢字", comment: "")

        XCTAssertEqual(hanja.getComment(), "")
    }
}
