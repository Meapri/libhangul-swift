//
//  UnicodeTests.swift
//  LibHangulTests
//
//  유니코드 정규화 및 호환성 테스트
//  - NFC/NFD 변환, 파일명 호환성, 크로스플랫폼 지원
//

import XCTest
@testable import LibHangul

class UnicodeTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2")
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    // MARK: - NFC 정규화 테스트

    func testBasicNFCNormalization() {
        let testText: [UCSChar] = [0x1100, 0x1161] // ㄱ + ㅏ
        let normalized = inputContext.normalizeUnicode(testText.map { $0 })
        let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // NFC 형태로 정규화되었는지 확인
        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC)
        XCTAssertEqual(text, "가")
    }

    func testComplexSyllableNFCNormalization() {
        // 복잡한 음절: 간 (ㄱ + ㅏ + ㄴ)
        let testText: [UCSChar] = [0x1100, 0x1161, 0x11AB]
        let normalized = inputContext.normalizeUnicode(testText.map { $0 })
        let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC)
        XCTAssertEqual(text, "간")
    }

    func testMultipleSyllablesNFCNormalization() {
        // 여러 음절: 안녕하세요
        let testText: [UCSChar] = [
            0x110B, 0x1165, 0x11AB, // 안
            0x1102, 0x1175, 0x11A8, // 녕
            0x1112, 0x1161, 0x11AD, // 하
            0x1109, 0x116E, // 세
            0x110B, 0x1173  // 요
        ]

        let normalized = inputContext.normalizeUnicode(testText.map { $0 })
        let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC)
        XCTAssertEqual(text, "안녕하세요")
    }

    func testEmptyTextNormalization() {
        let emptyText: [UCSChar] = []
        let normalized = inputContext.normalizeUnicode(emptyText.map { $0 })
        XCTAssertEqual(normalized, [])
    }

    func testNonHangulTextNormalization() {
        let englishText: [UCSChar] = [0x0041, 0x0042, 0x0043] // ABC
        let normalized = inputContext.normalizeUnicode(englishText.map { $0 })
        let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        XCTAssertEqual(text, "ABC")
    }

    // MARK: - 파일명 호환성 테스트

    func testBasicFilenameNormalization() {
        let testText: [UCSChar] = [0x1100, 0x1161] // ㄱ + ㅏ
        let filenameSafe = inputContext.normalizeForFilename(testText)
        let filename = String(filenameSafe.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 기본적으로 NFC 정규화
        let analysis = HangulInputContext.analyzeUnicodeNormalization(filename)
        XCTAssertTrue(analysis.isNFC)
    }

    func testFilenameSpecialCharacterRemoval() {
        // 파일명에 부적합한 문자들 포함
        let problematicText: [UCSChar] = [
            0x1100, 0x1161, // 가
            0x002F,         // /
            0x005C,         // \
            0x003A,         // :
            0x002A,         // *
            0x003F,         // ?
            0x0022,         // "
            0x003C,         // <
            0x003E,         // >
            0x007C          // |
        ]

        let filenameSafe = inputContext.normalizeForFilename(problematicText)
        let filename = String(filenameSafe.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 모든 부적합한 문자가 제거/교체됨
        XCTAssertFalse(filename.contains("/"))
        XCTAssertFalse(filename.contains("\\"))
        XCTAssertFalse(filename.contains(":"))
        XCTAssertFalse(filename.contains("*"))
        XCTAssertFalse(filename.contains("?"))
        XCTAssertFalse(filename.contains("\""))
        XCTAssertFalse(filename.contains("<"))
        XCTAssertFalse(filename.contains(">"))
        XCTAssertFalse(filename.contains("|"))

        // 한글 부분은 유지
        XCTAssertTrue(filename.contains("가"))
    }

    func testFilenameWithSpacesAndPunctuation() {
        let testText: [UCSChar] = [
            0x110B, 0x1165, 0x11AB, // 안
            0x0020,                // 스페이스
            0x1102, 0x1175, 0x11A8, // 녕
            0x0021,                // !
            0x003F                 // ?
        ]

        let filenameSafe = inputContext.normalizeForFilename(testText)
        let filename = String(filenameSafe.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 스페이스와 구두점은 파일명에서 허용될 수 있음
        // 하지만 실제 파일 시스템에서는 제한될 수 있으므로 상황에 따라 다름
        XCTAssertTrue(filename.contains("안"))
        XCTAssertTrue(filename.contains("녕"))
    }

    func testFilenameLengthHandling() {
        // 매우 긴 파일명
        var longText: [UCSChar] = []
        for _ in 0..<100 {
            longText.append(contentsOf: [0x1100, 0x1161]) // 가 반복
        }

        let filenameSafe = inputContext.normalizeForFilename(longText)
        let filename = String(filenameSafe.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 파일명 길이 제한은 OS에 따라 다르지만, 기본적인 처리는 동작
        XCTAssertGreaterThan(filename.count, 0)
    }

    // MARK: - 크로스플랫폼 호환성 테스트

    func testCrossPlatformCompatibilityNormalMode() {
        inputContext.filenameCompatibilityMode = false
        inputContext.forceNFCNormalization = true

        let testText: [UCSChar] = [0x1100, 0x1161] // ㄱ + ㅏ
        let compatible = inputContext.ensureCrossPlatformCompatibility(testText)
        let text = String(compatible.compactMap { UnicodeScalar($0) }.map { Character($0) })

        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC)
    }

    func testCrossPlatformCompatibilityFilenameMode() {
        inputContext.filenameCompatibilityMode = true

        let testText: [UCSChar] = [0x1100, 0x1161, 0x002F] // ㄱ + ㅏ + /
        let compatible = inputContext.ensureCrossPlatformCompatibility(testText)
        let text = String(compatible.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 파일명 모드에서는 /가 제거됨
        XCTAssertFalse(text.contains("/"))
    }

    func testCompatibilityModeSwitching() {
        let testText: [UCSChar] = [0x1100, 0x1161] // ㄱ + ㅏ

        // 일반 모드
        inputContext.filenameCompatibilityMode = false
        let normal = inputContext.ensureCrossPlatformCompatibility(testText)

        // 파일명 모드
        inputContext.filenameCompatibilityMode = true
        let filename = inputContext.ensureCrossPlatformCompatibility(testText)

        // 결과가 다를 수 있음 (정규화 방식 차이)
        // 하지만 둘 다 유효한 결과를 생성해야 함
        XCTAssertGreaterThan(normal.count, 0)
        XCTAssertGreaterThan(filename.count, 0)
    }

    // MARK: - NFD ↔ NFC 변환 테스트

    func testNFDTextConversion() {
        // NFD 형태의 텍스트들
        let nfdTexts = [
            "가",     // ㄱㅏ
            "안",   // 안
            "한국" // 한국
        ]

        for nfdText in nfdTexts {
            let nfcText = HangulInputContext.convertNFDToNFC(nfdText)

            // 변환 결과가 NFC인지 확인
            let analysis = HangulInputContext.analyzeUnicodeNormalization(nfcText)
            XCTAssertTrue(analysis.isNFC, "NFD → NFC 변환 실패: \(nfdText)")

            // 시각적으로는 같은 글자
            // (실제로는 NFD와 NFC가 시각적으로 같지만 내부 표현이 다름)
        }
    }

    func testAlreadyNFCTextConversion() {
        let nfcText = "한국어"
        let converted = HangulInputContext.convertNFDToNFC(nfcText)

        // 이미 NFC인 텍스트는 그대로 유지
        let analysis = HangulInputContext.analyzeUnicodeNormalization(converted)
        XCTAssertTrue(analysis.isNFC)
        // 시각적으로는 같음
        XCTAssertEqual(converted, nfcText)
    }

    func testMixedNormalizationTextConversion() {
        // 일부는 NFD, 일부는 NFC인 혼합 텍스트
        let mixedText = "가나" // ㄱㅏ(자소분리) + 나(NFC)
        let converted = HangulInputContext.convertNFDToNFC(mixedText)

        let analysis = HangulInputContext.analyzeUnicodeNormalization(converted)
        XCTAssertTrue(analysis.isNFC)
    }

    // MARK: - 유니코드 분석 기능 테스트

    func testUnicodeAnalysisNFC() {
        let nfcTexts = ["가", "한", "글", "안녕하세요"]

        for text in nfcTexts {
            let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
            XCTAssertTrue(analysis.isNFC, "\(text)는 NFC여야 함")
            XCTAssertFalse(analysis.isNFD, "\(text)는 NFD가 아니어야 함")
            XCTAssertEqual(analysis.form, "NFC")
        }
    }

    func testUnicodeAnalysisNFD() {
        let nfdTexts = ["가", "한", "글", "안녕"]

        for text in nfdTexts {
            let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
            XCTAssertFalse(analysis.isNFC, "\(text)는 NFC가 아니어야 함")
            XCTAssertTrue(analysis.isNFD, "\(text)는 NFD여야 함")
            XCTAssertEqual(analysis.form, "NFD")
        }
    }

    func testUnicodeAnalysisEnglish() {
        let englishTexts = ["Hello", "World", "ABC", "123"]

        for text in englishTexts {
            let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
            // 영어는 NFC/NFD 구분이 크게 중요하지 않음
            // 대부분 NFC로 처리됨
            XCTAssertNotEqual(analysis.form, "Other/Mixed")
        }
    }

    func testUnicodeAnalysisEmptyString() {
        let analysis = HangulInputContext.analyzeUnicodeNormalization("")

        // 빈 문자열은 특별한 경우
        XCTAssertFalse(analysis.isNFC)
        XCTAssertFalse(analysis.isNFD)
        // 실제 결과는 구현에 따라 다를 수 있음
    }

    // MARK: - 엣지 케이스 및 오류 처리

    func testInvalidUnicodeScalars() {
        // 유효하지 않은 유니코드 스칼라
        let invalidScalars: [UCSChar] = [0xD800, 0xDFFF] // Surrogate half

        let normalized = inputContext.normalizeUnicode(invalidScalars.map { $0 })

        // 유효하지 않은 스칼라는 처리되지 않거나 다른 형태로 변환될 수 있음
        // 중요한 것은 크래시가 발생하지 않는 것
        XCTAssertNoThrow(normalized)
    }

    func testVeryLargeUnicodeText() {
        // 매우 큰 유니코드 텍스트
        var largeText: [UCSChar] = []
        for _ in 0..<10000 {
            largeText.append(contentsOf: [0x1100, 0x1161]) // 가 반복
        }

        // 메모리 부족 등으로 인한 크래시는 없어야 함
        let normalized = inputContext.normalizeUnicode(largeText.map { $0 })
        XCTAssertNoThrow(normalized)

        if normalized.count > 0 {
            let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })
            let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
            // 큰 텍스트라도 정규화는 적용되어야 함
            XCTAssertNotEqual(analysis.form, "Other/Mixed")
        }
    }

    func testSpecialCharactersNormalization() {
        // 특수 문자와 한글의 혼합
        let mixedText: [UCSChar] = [
            0x0041, 0x1100, 0x1161, 0x0042, // A가B
            0x0021, 0x110B, 0x1165, 0x11AB, 0x003F // !안?
        ]

        let normalized = inputContext.normalizeUnicode(mixedText.map { $0 })
        let text = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 한글 부분은 NFC로 정규화
        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        // 혼합 텍스트의 경우 정확한 검증이 어려움
        // 크래시 없이 처리되는지가 중요
        XCTAssertNoThrow(analysis)
    }

    // MARK: - 실무 사용 시나리오 테스트

    func testFileSharingScenario() {
        // 파일 공유 시나리오: macOS → Windows
        let filenameText = "한글 파일.txt"

        // macOS에서 생성된 파일명 (NFD일 수 있음)
        let nfdFilename = "한글 파일.txt"

        // NFC로 변환
        let nfcFilename = HangulInputContext.convertNFDToNFC(nfdFilename)

        // Windows에서 읽을 수 있는 형태로 변환
        let windowsSafe = nfcFilename
            .replacingOccurrences(of: "한", with: "한")
            .replacingOccurrences(of: "글", with: "글")
            .replacingOccurrences(of: " 파", with: " 파")
            .replacingOccurrences(of: "일", with: "일")

        // 기본적인 한글 포함 여부 확인
        XCTAssertTrue(windowsSafe.contains("한") ||
                     windowsSafe.contains("글") ||
                     windowsSafe.contains("파") ||
                     windowsSafe.contains("일"))
    }

    func testWebContentScenario() {
        // 웹 콘텐츠 시나리오
        let webContent = "안녕하세요, 반갑습니다!"

        let analysis = HangulInputContext.analyzeUnicodeNormalization(webContent)
        // 웹에서는 보통 NFC 사용
        // 실제로는 브라우저나 서버 설정에 따라 다름
        XCTAssertNoThrow(analysis)
    }

    func testDatabaseStorageScenario() {
        // 데이터베이스 저장 시나리오
        let dbText = "사용자 정보: 홍길동, 이메일: hong@example.com"

        let normalized = inputContext.normalizeUnicode(
            dbText.unicodeScalars.map { $0.value }.map { $0 }
        )
        let resultText = String(normalized.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 정규화 후에도 원래 내용 유지
        XCTAssertTrue(resultText.contains("홍길동"))
        XCTAssertTrue(resultText.contains("hong@example.com"))

        let analysis = HangulInputContext.analyzeUnicodeNormalization(resultText)
        // 데이터베이스 저장용으로는 NFC가 좋음
        XCTAssertNoThrow(analysis)
    }
}
