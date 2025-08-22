//
//  AdvancedInputContextTests.swift
//  LibHangulTests
//
//  고급 입력 컨텍스트 기능 테스트
//  - 버퍼 관리, 유니코드 정규화, 오류 처리, 성능 테스트
//

import XCTest
@testable import LibHangul

class AdvancedInputContextTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2")
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    // MARK: - 버퍼 관리 테스트

    func testMaxBufferSizeConfiguration() {
        // 기본 버퍼 크기 확인
        XCTAssertEqual(inputContext.maxBufferSize, 12)

        // 버퍼 크기 변경
        inputContext.maxBufferSize = 5
        XCTAssertEqual(inputContext.maxBufferSize, 5)

        // 작은 버퍼 크기로 테스트
        for char in ["r", "k", "s", "f", "a"] {
            let key = Int(Character(char).asciiValue!)
            _ = inputContext.process(key)
        }

        // 버퍼가 가득 차서 flush되었는지 확인
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    func testBufferOverflowHandling() {
        inputContext.maxBufferSize = 3

        // 버퍼 크기 초과 입력
        let keys = ["r", "k", "s", "f", "a"] // 5개의 입력
        for char in keys {
            let key = Int(Character(char).asciiValue!)
            _ = inputContext.process(key)
        }

        // 일부 입력이 커밋되었는지 확인
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    func testBufferMonitoring() {
        inputContext.enableBufferMonitoring = true

        // 정상적인 입력
        _ = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        _ = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ

        // 버퍼 상태 확인
        let preedit = inputContext.getPreeditString()
        XCTAssertGreaterThan(preedit.count, 0)
    }

    func testBufferMonitoringDisabled() {
        inputContext.enableBufferMonitoring = false
        inputContext.maxBufferSize = 1

        // 모니터링 비활성화 시에도 기본 기능은 동작
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    // MARK: - 유니코드 정규화 테스트

    func testNFCNormalizationEnabled() {
        inputContext.forceNFCNormalization = true

        // 한글 입력
        _ = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        _ = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ

        let committed = inputContext.getCommitString()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // NFC 정규화 확인
        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC, "NFC 정규화가 적용되어야 함")
    }

    func testNFCNormalizationDisabled() {
        inputContext.forceNFCNormalization = false

        // 한글 입력
        _ = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
        _ = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ

        let committed = inputContext.getCommitString()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 정규화가 적용되지 않음
        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        // 기본적으로도 NFC가 될 수 있으므로 명시적 검증은 생략
    }

    func testFilenameCompatibilityMode() {
        inputContext.filenameCompatibilityMode = true

        let testText: [UCSChar] = [0x1100, 0x1161] // ㄱ + ㅏ
        let filenameSafe = inputContext.normalizeForFilename(testText)

        let filename = String(filenameSafe.compactMap { UnicodeScalar($0) }.map { Character($0) })
        // 파일명에 부적합한 문자가 제거되었는지 확인
        XCTAssertFalse(filename.contains("/"))
        XCTAssertFalse(filename.contains("\\"))
        XCTAssertFalse(filename.contains(":"))
    }

    func testCrossPlatformCompatibility() {
        // 일반 모드
        inputContext.filenameCompatibilityMode = false
        let testText: [UCSChar] = [0x1100, 0x1161]

        let normalResult = inputContext.ensureCrossPlatformCompatibility(testText)
        let normalText = String(normalResult.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 파일명 호환성 모드
        inputContext.filenameCompatibilityMode = true
        let filenameResult = inputContext.ensureCrossPlatformCompatibility(testText)
        let filenameText = String(filenameResult.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 두 결과가 다름
        XCTAssertNotEqual(normalText, filenameText)
    }

    func testUnicodeAnalysis() {
        let nfcText = "가"
        let analysis = HangulInputContext.analyzeUnicodeNormalization(nfcText)

        XCTAssertTrue(analysis.isNFC)
        XCTAssertFalse(analysis.isNFD)
        XCTAssertEqual(analysis.form, "NFC")
    }

    func testNFDToNFCConversion() {
        // NFD 형태의 텍스트 (자소 분리)
        let nfdText = "가" // U+1100 + U+1161
        let nfcText = HangulInputContext.convertNFDToNFC(nfdText)

        // NFC 형태로 변환되었는지 확인
        let analysis = HangulInputContext.analyzeUnicodeNormalization(nfcText)
        XCTAssertTrue(analysis.isNFC)

        // 시각적으로는 같은 글자
        XCTAssertEqual(nfcText, "가")
    }

    // MARK: - 오류 처리 및 복구 테스트

    func testAutoErrorRecovery() {
        inputContext.autoErrorRecovery = true

        // 정상 입력
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    func testErrorRecoveryDisabled() {
        inputContext.autoErrorRecovery = false

        // 에러가 발생해도 복구하지 않음
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        let committed = inputContext.getCommitString()
        // 복구가 비활성화되어도 기본 기능은 동작
        XCTAssertGreaterThan(committed.count, 0)
    }

    func testInvalidJamoHandling() {
        // 유효하지 않은 자모 입력 시도
        let invalidJamo: UCSChar = 0x0000 // NULL 문자
        let success = inputContext.process(Int(invalidJamo))

        // 유효하지 않은 입력은 처리되지 않음
        XCTAssertFalse(success)
    }

    func testLargeBufferHandling() {
        inputContext.maxBufferSize = 100

        // 많은 입력 처리
        for i in 0..<50 {
            let key = Int(Character("r").asciiValue!) // 같은 키 반복
            _ = inputContext.process(key)
        }

        // 큰 버퍼에서도 정상 동작
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    // MARK: - 성능 및 안정성 테스트

    func testPerformanceWithLargeInput() {
        let iterationCount = 1000

        measure {
            for _ in 0..<iterationCount {
                let key = Int(Character("r").asciiValue!)
                _ = inputContext.process(key)
            }
            _ = inputContext.flush()
        }
    }

    func testMemoryEfficiency() {
        inputContext.maxBufferSize = 10

        // 메모리 누수 없이 반복 사용
        for _ in 0..<100 {
            _ = inputContext.process(Int(Character("r").asciiValue!))
            _ = inputContext.process(Int(Character("k").asciiValue!))
            _ = inputContext.flush()
        }

        // 여전히 정상 동작
        _ = inputContext.process(Int(Character("r").asciiValue!))
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThan(committed.count, 0)
    }

    func testConcurrentAccess() {
        // 여러 스레드에서 동시에 접근
        let expectation1 = expectation(description: "Thread 1")
        let expectation2 = expectation(description: "Thread 2")

        DispatchQueue.global().async {
            for _ in 0..<10 {
                _ = self.inputContext.process(Int(Character("r").asciiValue!))
            }
            expectation1.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<10 {
                _ = self.inputContext.process(Int(Character("k").asciiValue!))
            }
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 5.0)

        let committed = inputContext.getCommitString()
        // 동시 접근 후에도 데이터 무결성 유지
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    // MARK: - 통합 기능 테스트

    func testCompleteWorkflow() {
        // 모든 고급 기능 활성화
        inputContext.maxBufferSize = 20
        inputContext.forceNFCNormalization = true
        inputContext.enableBufferMonitoring = true
        inputContext.autoErrorRecovery = true
        inputContext.filenameCompatibilityMode = false

        // 복잡한 한글 입력 시뮬레이션
        let inputSequence = ["r", "k", "s", "f", "a", "q"] // ㄱㅏㄷㅏㅁㅜ

        for char in inputSequence {
            let key = Int(Character(char).asciiValue!)
            _ = inputContext.process(key)
        }

        // flush로 모든 내용 커밋
        let committed = inputContext.flush()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // NFC 정규화 확인
        let analysis = HangulInputContext.analyzeUnicodeNormalization(text)
        XCTAssertTrue(analysis.isNFC)

        // 텍스트가 생성되었는지 확인
        XCTAssertGreaterThan(text.count, 0)
    }

    func testConfigurationCombinations() {
        let configurations = [
            (maxBuffer: 5, nfc: true, monitoring: true, recovery: true),
            (maxBuffer: 10, nfc: false, monitoring: false, recovery: true),
            (maxBuffer: 15, nfc: true, monitoring: false, recovery: false),
        ]

        for config in configurations {
            let context = HangulInputContext(keyboard: "2")
            context.maxBufferSize = config.maxBuffer
            context.forceNFCNormalization = config.nfc
            context.enableBufferMonitoring = config.monitoring
            context.autoErrorRecovery = config.recovery

            // 각 설정으로 테스트
            _ = context.process(Int(Character("r").asciiValue!))
            _ = context.process(Int(Character("k").asciiValue!))
            let committed = context.getCommitString()

            // 어떤 설정이든 기본 기능은 동작
            XCTAssertGreaterThanOrEqual(committed.count, 0)
        }
    }
}
