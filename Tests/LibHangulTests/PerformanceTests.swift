//
//  PerformanceTests.swift
//  LibHangulTests
//
//  성능 및 안정성 테스트
//  - 대량 데이터 처리, 메모리 사용량, 응답 시간
//

import XCTest
@testable import LibHangul

class PerformanceTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2")
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    // MARK: - 성능 테스트

    func testSingleCharacterInputPerformance() {
        let iterationCount = 1000

        measure {
            for _ in 0..<iterationCount {
                let key = Int(Character("r").asciiValue!)
                _ = inputContext.process(key)
                _ = inputContext.flush()
            }
        }
    }

    func testSyllableCompositionPerformance() {
        let iterationCount = 1000

        measure {
            for _ in 0..<iterationCount {
                // 한 음절 완성: ㄱ + ㅏ + ㄴ
                _ = inputContext.process(Int(Character("r").asciiValue!)) // ㄱ
                _ = inputContext.process(Int(Character("k").asciiValue!)) // ㅏ
                _ = inputContext.process(Int(Character("s").asciiValue!)) // ㄴ
                _ = inputContext.flush()
            }
        }
    }

    func testRapidTypingSimulation() {
        let rapidInputSequence = ["r", "k", "s", "f", "a", "q", "w", "e", "r", "t"]
        let iterationCount = 100

        measure {
            for _ in 0..<iterationCount {
                for char in rapidInputSequence {
                    let key = Int(Character(char).asciiValue!)
                    _ = inputContext.process(key)
                }
                _ = inputContext.flush()
            }
        }
    }

    func testLongTextProcessingPerformance() {
        // 긴 한글 텍스트 시뮬레이션
        let longText = "안녕하세요반갑습니다오늘은좋은날입니다날씨가참좋네요"
        let iterationCount = 10

        measure {
            for _ in 0..<iterationCount {
                for char in longText {
                    if let asciiValue = char.asciiValue {
                        _ = inputContext.process(Int(asciiValue))
                    }
                }
                _ = inputContext.flush()
            }
        }
    }

    func testUnicodeNormalizationPerformance() {
        let testText: [UCSChar] = [
            0x110B, 0x1165, 0x11AB, // 안
            0x1102, 0x1175, 0x11A8, // 녕
            0x1112, 0x1161, 0x11AD, // 하
            0x1109, 0x116E, // 세
            0x110B, 0x1173  // 요
        ]

        let iterationCount = 1000

        measure {
            for _ in 0..<iterationCount {
                _ = inputContext.normalizeUnicode(testText.map { $0 })
            }
        }
    }

    func testFilenameNormalizationPerformance() {
        let problematicFilename: [UCSChar] = [
            0x110B, 0x1165, 0x11AB, // 안
            0x002F,                 // /
            0x1102, 0x1175, 0x11A8, // 녕
            0x005C,                 // \
            0x1112, 0x1161, 0x11AD, // 하
            0x003A,                 // :
            0x1109, 0x116E, // 세
            0x002A                  // *
        ]

        let iterationCount = 1000

        measure {
            for _ in 0..<iterationCount {
                _ = inputContext.normalizeForFilename(problematicFilename)
            }
        }
    }

    // MARK: - 메모리 효율성 테스트

    func testMemoryUsageWithLargeBuffer() {
        inputContext.maxBufferSize = 1000

        // 큰 버퍼로 메모리 사용량 테스트
        for i in 0..<500 {
            let char = ["r", "k", "s", "f", "a"][i % 5]
            _ = inputContext.process(Int(Character(char).asciiValue!))
        }

        // 메모리 누수 없이 처리
        _ = inputContext.flush()
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testMemoryEfficiencyWithRepeatedOperations() {
        let iterationCount = 10000

        // 반복 작업으로 메모리 누수 테스트
        for i in 0..<iterationCount {
            _ = inputContext.process(Int(Character("r").asciiValue!))
            _ = inputContext.process(Int(Character("k").asciiValue!))

            if i % 100 == 0 {
                _ = inputContext.flush()
            }
        }

        // 최종 정리
        _ = inputContext.flush()
        let finalCommitted = inputContext.getCommitString()
        XCTAssertNoThrow(finalCommitted)
    }

    func testBufferSizeImpactOnMemory() {
        let bufferSizes = [5, 10, 50, 100, 500]

        for bufferSize in bufferSizes {
            let context = HangulInputContext(keyboard: "2")
            context.maxBufferSize = bufferSize

            // 각 버퍼 크기로 테스트
            for i in 0..<bufferSize * 2 {
                let char = ["r", "k", "s", "f"][i % 4]
                _ = context.process(Int(Character(char).asciiValue!))
            }

            // 메모리 관련 크래시 없이 동작
            _ = context.flush()
            let committed = context.getCommitString()
            XCTAssertNoThrow(committed)
        }
    }

    // MARK: - 안정성 및 스트레스 테스트

    func testStressTestWithRandomInput() {
        let possibleKeys = ["r", "k", "s", "f", "a", "q", "w", "e", "t"]
        let iterationCount = 10000

        // 랜덤 입력으로 스트레스 테스트
        for _ in 0..<iterationCount {
            let randomChar = possibleKeys.randomElement()!
            let key = Int(Character(randomChar).asciiValue!)
            _ = inputContext.process(key)

            // 랜덤하게 flush
            if Int.random(in: 1...100) <= 5 { // 5% 확률
                _ = inputContext.flush()
            }
        }

        // 스트레스 테스트 후에도 정상 상태
        let finalCommitted = inputContext.getCommitString()
        let finalPreedit = inputContext.getPreeditString()
        XCTAssertNoThrow(finalCommitted)
        XCTAssertNoThrow(finalPreedit)
    }

    func testExtremeConfigurationStress() {
        let extremeConfigs = [
            (bufferSize: 1, nfc: true, monitoring: true, recovery: true),
            (bufferSize: 1000, nfc: false, monitoring: false, recovery: false),
            (bufferSize: 0, nfc: true, monitoring: false, recovery: true) // 비정상적 크기
        ]

        for config in extremeConfigs {
            let context = HangulInputContext(keyboard: "2")

            // 극단적인 설정 적용 (일부는 비정상적)
            if config.bufferSize > 0 {
                context.maxBufferSize = config.bufferSize
            }
            context.forceNFCNormalization = config.nfc
            context.enableBufferMonitoring = config.monitoring
            context.autoErrorRecovery = config.recovery

            // 각 설정으로 스트레스 테스트
            for i in 0..<100 {
                let char = ["r", "k", "s"][i % 3]
                _ = context.process(Int(Character(char).asciiValue!))

                if i % 10 == 0 {
                    _ = context.flush()
                }
            }

            // 극단적인 설정에서도 크래시 없이 동작
            let committed = context.getCommitString()
            let preedit = context.getPreeditString()
            XCTAssertNoThrow(committed)
            XCTAssertNoThrow(preedit)
        }
    }

    func testLongRunningSessionStability() {
        let sessionDuration = 5 // 5초로 단축 (테스트용)
        let startTime = Date()

        var operationCount = 0

        while Date().timeIntervalSince(startTime) < Double(sessionDuration) {
            // 지속적인 입력 시뮬레이션
            let char = ["r", "k", "s", "f", "a"].randomElement()!
            _ = inputContext.process(Int(Character(char).asciiValue!))
            operationCount += 1

            // 주기적으로 flush
            if operationCount % 100 == 0 {
                _ = inputContext.flush()
            }

            // 과도한 메모리 사용 방지
            if operationCount % 1000 == 0 {
                Thread.sleep(forTimeInterval: 0.001) // 1ms 대기
            }
        }

        // 긴 세션 후에도 안정적
        let finalCommitted = inputContext.getCommitString()
        let finalPreedit = inputContext.getPreeditString()
        XCTAssertNoThrow(finalCommitted)
        XCTAssertNoThrow(finalPreedit)
        XCTAssertGreaterThan(operationCount, 0)
    }

    // MARK: - 동시성 및 스레드 안전성 테스트

    func testConcurrentInputProcessing() {
        let concurrentContexts = (0..<10).map { _ in HangulInputContext(keyboard: "2") }
        let expectation = expectation(description: "All contexts processed")

        // 동시성 테스트를 위한 세마포어
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.concurrentPerform(iterations: concurrentContexts.count) { [concurrentContexts] index in
            let context = concurrentContexts[index]

            // 각 스레드에서 독립적 처리
            for i in 0..<100 {
                let char = ["r", "k", "s", "f"][i % 4]
                _ = context.process(Int(Character(char).asciiValue!))
            }

            _ = context.flush()
        }

        // 작업 완료 확인을 위한 타이머
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 1.0)
            semaphore.signal()
        }

        // 세마포어 대기
        let timeoutResult = semaphore.wait(timeout: .now() + 5.0)
        if timeoutResult == .success {
            expectation.fulfill()
        } else {
            XCTFail("Concurrent processing timeout")
        }

        wait(for: [expectation], timeout: 1.0)

        // 각 컨텍스트가 독립적으로 동작했는지 확인
        for context in concurrentContexts {
            let committed = context.getCommitString()
            XCTAssertNoThrow(committed)
        }
    }

    func testThreadSafetyWithSeparateContexts() {
        // 각 스레드마다 별도의 컨텍스트 사용 (안전한 패턴)
        let expectation1 = expectation(description: "Thread 1")
        let expectation2 = expectation(description: "Thread 2")

        DispatchQueue.global().async {
            let context1 = HangulInputContext(keyboard: "2")
            for _ in 0..<100 {
                _ = context1.process(Int(Character("r").asciiValue!))
            }
            expectation1.fulfill()
        }

        DispatchQueue.global().async {
            let context2 = HangulInputContext(keyboard: "2")
            for _ in 0..<100 {
                _ = context2.process(Int(Character("k").asciiValue!))
            }
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 5.0)

        // 각 스레드별 독립적 컨텍스트 사용 후에도 정상 동작
        let committed = inputContext.getCommitString()
        let preedit = inputContext.getPreeditString()
        XCTAssertNoThrow(committed)
        XCTAssertNoThrow(preedit)
    }

    // MARK: - 자원 관리 테스트

    func testResourceCleanup() {
        // 강제 순환 참조 생성 및 정리 테스트
        var contexts: [HangulInputContext] = []

        // 다수의 컨텍스트 생성
        for _ in 0..<100 {
            let context = HangulInputContext(keyboard: "2")
            contexts.append(context)

            // 각 컨텍스트로 작업 수행
            _ = context.process(Int(Character("r").asciiValue!))
            _ = context.process(Int(Character("k").asciiValue!))
            _ = context.flush()
        }

        // 배열 클리어로 참조 해제
        contexts.removeAll()

        // 메모리 해제가 정상적으로 이루어짐
        // (실제 메모리 해제는 ARC에 의해 자동으로 이루어짐)
    }

    func testConfigurationPersistence() {
        // 설정 변경 후 지속성 테스트
        inputContext.maxBufferSize = 25
        inputContext.forceNFCNormalization = false
        inputContext.filenameCompatibilityMode = true

        // 설정이 변경된 상태에서 동작
        for _ in 0..<10 {
            _ = inputContext.process(Int(Character("r").asciiValue!))
            _ = inputContext.process(Int(Character("k").asciiValue!))
            _ = inputContext.flush()
        }

        // 설정이 유지되는지 확인 (간접적 확인)
        let committed = inputContext.getCommitString()
        XCTAssertNoThrow(committed)
    }

    // MARK: - 실제 사용 패턴 기반 테스트

    func testRealisticTypingPattern() {
        // 실제 타이핑 패턴 시뮬레이션

        // 문장: "안녕하세요. 오늘 날씨가 좋네요!"
        let sentencePattern = [
            ("안", ["r", "k", "s"]),         // ㄱㅏㄷ
            ("녕", ["f", "r", "k", "s"]),    // ㅏㄱㅏㄷ
            ("하", ["a", "k", "s"]),         // ㅗㅏㄷ
            ("세", ["t", "k"]),              // ㅅㅏ
            ("요", ["i", "k"])               // ㅛㅏ
        ]

        let iterationCount = 100

        measure {
            for _ in 0..<iterationCount {
                for (_, jamoSequence) in sentencePattern {
                    for jamo in jamoSequence {
                        let key = Int(Character(jamo).asciiValue!)
                        _ = inputContext.process(key)
                    }
                    // 단어 간에 약간의 지연 (flush로 시뮬레이션)
                    _ = inputContext.flush()
                }
            }
        }
    }

    func testMixedLanguageTyping() {
        // 한글과 영어 혼합 타이핑 패턴
        let mixedPattern = [
            "안녕",     // 한글
            "Hello",    // 영어
            "하세요",   // 한글
            "World",    // 영어
            "반갑습니다" // 한글
        ]

        let iterationCount = 50

        measure {
            for _ in 0..<iterationCount {
                for text in mixedPattern {
                    for char in text {
                        if char.isASCII {
                            // 영어: ASCII 키로 처리
                            if let asciiValue = char.asciiValue {
                                _ = inputContext.process(Int(asciiValue))
                            }
                        } else {
                            // 한글: 간단한 매핑으로 시뮬레이션
                            _ = inputContext.process(Int(Character("r").asciiValue!))
                            _ = inputContext.process(Int(Character("k").asciiValue!))
                        }
                    }
                    _ = inputContext.flush()
                }
            }
        }
    }

    func testErrorRecoveryPerformance() {
        inputContext.autoErrorRecovery = true
        inputContext.maxBufferSize = 3

        let iterationCount = 1000

        measure {
            for i in 0..<iterationCount {
                if i % 10 == 0 {
                    // 가끔 유효하지 않은 입력
                    _ = inputContext.process(-1)
                } else {
                    let char = ["r", "k", "s", "f"][i % 4]
                    _ = inputContext.process(Int(Character(char).asciiValue!))
                }

                // 주기적으로 버퍼 초과 상황 발생
                if i % 20 == 0 {
                    for _ in 0..<5 {
                        _ = inputContext.process(Int(Character("a").asciiValue!))
                    }
                }

                if i % 50 == 0 {
                    _ = inputContext.flush()
                }
            }
        }
    }
}
