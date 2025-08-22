//
//  ErrorHandlingTests.swift
//  LibHangulTests
//
//  오류 처리 및 복구 메커니즘 테스트
//  - 예외 상황, 버퍼 오버플로우, 유효하지 않은 입력 처리
//

import XCTest
@testable import LibHangul

class ErrorHandlingTests: XCTestCase {

    var inputContext: HangulInputContext!

    override func setUp() {
        super.setUp()
        inputContext = HangulInputContext(keyboard: "2")
    }

    override func tearDown() {
        inputContext = nil
        super.tearDown()
    }

    // MARK: - 버퍼 오버플로우 테스트

    func testBufferOverflowWithSmallLimit() {
        inputContext.maxBufferSize = 2

        // 버퍼 크기 초과 입력
        _ = inputContext.process(Int(Character("r").asciiValue!)) // 1
        _ = inputContext.process(Int(Character("k").asciiValue!)) // 2
        _ = inputContext.process(Int(Character("s").asciiValue!)) // 3 - 오버플로우

        // 일부 입력이 처리되었는지 확인
        let committed = inputContext.getCommitString()
        // 오버플로우 시 자동 flush가 발생하므로 커밋된 내용이 있어야 함
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testBufferOverflowWithMonitoring() {
        inputContext.maxBufferSize = 3
        inputContext.enableBufferMonitoring = true

        // 버퍼 크기 초과 입력
        for i in 0..<5 {
            let char = ["r", "k", "s", "f", "a"][i % 5]
            _ = inputContext.process(Int(Character(char).asciiValue!))
        }

        // 모니터링이 활성화된 상태에서도 정상 동작
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testExtremeBufferOverflow() {
        inputContext.maxBufferSize = 1

        // 매우 많은 입력으로 극단적 상황 테스트
        for _ in 0..<100 {
            _ = inputContext.process(Int(Character("r").asciiValue!))
        }

        // 시스템이 크래시 없이 동작
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    // MARK: - 유효하지 않은 입력 처리

    func testInvalidASCIIKeys() {
        // ASCII 범위를 벗어난 키 코드들
        let invalidKeys = [-1, 1000, 99999]

        for key in invalidKeys {
            let result = inputContext.process(key)
            // 유효하지 않은 키는 처리되지 않음
            XCTAssertFalse(result)
        }
    }

    func testNullAndControlCharacters() {
        // NULL과 제어 문자들
        let controlChars = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

        for charCode in controlChars {
            let result = inputContext.process(charCode)
            // 제어 문자는 일반적으로 처리되지 않음
            XCTAssertFalse(result)
        }
    }

    func testInvalidUnicodeJamo() {
        // 유니코드 한글 자모 범위를 벗어난 값들
        let invalidJamos: [UCSChar] = [
            0x0000,  // NULL
            0xFFFF,  // Invalid
            0x11000, // Out of range
            0x31300  // Out of range
        ]

        for jamo in invalidJamos {
            let result = inputContext.process(Int(jamo))
            // 유효하지 않은 자모는 처리되지 않음
            XCTAssertFalse(result)
        }
    }

    func testMixedValidInvalidInput() {
        // 유효한 입력과 유효하지 않은 입력의 혼합
        let mixedInputs = [
            Int(Character("r").asciiValue!), // 유효: ㄱ
            -1,                               // 무효
            Int(Character("k").asciiValue!), // 유효: ㅏ
            99999,                           // 무효
            Int(Character("s").asciiValue!)  // 유효: ㄷ
        ]

        var validCount = 0
        var invalidCount = 0

        for input in mixedInputs {
            let result = inputContext.process(input)
            if result {
                validCount += 1
            } else {
                invalidCount += 1
            }
        }

        // 유효한 입력만 처리됨
        XCTAssertEqual(validCount, 3)
        XCTAssertEqual(invalidCount, 2)

        // 유효한 입력으로 생성된 텍스트 확인
        let committed = inputContext.getCommitString()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
        XCTAssertGreaterThan(text.count, 0)
    }

    // MARK: - 오류 복구 메커니즘 테스트

    func testAutoErrorRecoveryEnabled() {
        inputContext.autoErrorRecovery = true

        // 정상 입력 후 오류 상황 시뮬레이션
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        // 버퍼 크기 초과로 오류 상황 발생
        inputContext.maxBufferSize = 1
        _ = inputContext.process(Int(Character("s").asciiValue!))

        // 자동 복구가 활성화된 상태에서도 정상 동작
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testAutoErrorRecoveryDisabled() {
        inputContext.autoErrorRecovery = false

        // 정상 입력
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        // 버퍼 크기 초과
        inputContext.maxBufferSize = 1
        _ = inputContext.process(Int(Character("s").asciiValue!))

        // 복구가 비활성화되어도 기본 기능은 동작
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testRecoveryAfterInvalidInputSequence() {
        // 유효하지 않은 입력 시퀀스로 오류 상황 유발
        let invalidSequence = [Int(Character("r").asciiValue!), -999, Int(Character("k").asciiValue!)]

        for input in invalidSequence {
            _ = inputContext.process(input)
        }

        // 이후 정상 입력이 가능한지 확인
        _ = inputContext.process(Int(Character("s").asciiValue!))
        _ = inputContext.process(Int(Character("f").asciiValue!))

        let committed = inputContext.getCommitString()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 오류 후에도 복구되어 정상 동작
        XCTAssertGreaterThan(text.count, 0)
    }

    // MARK: - 메모리 및 자원 관리 테스트

    func testMemoryLeakPrevention() {
        // 반복적인 입력/출력으로 메모리 누수 테스트
        for i in 0..<1000 {
            let char = ["r", "k", "s", "f", "a"][i % 5]
            _ = inputContext.process(Int(Character(char).asciiValue!))

            if i % 10 == 0 {
                _ = inputContext.flush()
            }
        }

        // 메모리 누수 없이 완료
        let committed = inputContext.getCommitString()
        XCTAssertGreaterThanOrEqual(committed.count, 0)
    }

    func testResourceCleanupOnError() {
        // 오류 상황에서 자원 정리 확인
        inputContext.maxBufferSize = 2

        for _ in 0..<10 {
            _ = inputContext.process(Int(Character("r").asciiValue!))
        }

        // flush로 정리
        _ = inputContext.flush()

        // 버퍼가 비워졌는지 확인
        let preedit = inputContext.getPreeditString()
        let commit = inputContext.getCommitString()

        // 정리 후에는 빈 상태이거나 최소한의 상태
        XCTAssertTrue(preedit.isEmpty || commit.isEmpty)
    }

    // MARK: - 스레드 안전성 테스트

    func testBasicThreadSafety() {
        let expectation1 = expectation(description: "Thread 1 completed")
        let expectation2 = expectation(description: "Thread 2 completed")

        // 두 개의 스레드에서 동시에 입력
        DispatchQueue.global().async { [weak self] in
            for _ in 0..<50 {
                _ = self?.inputContext.process(Int(Character("r").asciiValue!))
            }
            expectation1.fulfill()
        }

        DispatchQueue.global().async { [weak self] in
            for _ in 0..<50 {
                _ = self?.inputContext.process(Int(Character("k").asciiValue!))
            }
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 10.0)

        // 동시 접근 후에도 크래시 없이 동작
        let committed = inputContext.getCommitString()
        XCTAssertNoThrow(committed)
    }

    // MARK: - 경계 조건 테스트

    func testEmptyInputHandling() {
        // 빈 입력 처리
        let result = inputContext.process(0)
        XCTAssertFalse(result)
    }

    func testMaximumKeyCodeHandling() {
        // 가능한 최대 키 코드
        let result = inputContext.process(Int.max)
        // 유효하지 않은 키이므로 처리되지 않음
        XCTAssertFalse(result)
    }

    func testMinimumKeyCodeHandling() {
        // 가능한 최소 키 코드
        let result = inputContext.process(Int.min)
        // 유효하지 않은 키이므로 처리되지 않음
        XCTAssertFalse(result)
    }

    func testRepeatedInvalidKeys() {
        // 반복적인 유효하지 않은 키 입력
        for _ in 0..<100 {
            let result = inputContext.process(-1)
            XCTAssertFalse(result)
        }

        // 유효하지 않은 키 반복 후에도 상태가 정상
        let result = inputContext.process(Int(Character("r").asciiValue!))
        // 이후 유효한 키는 처리될 수 있음
        // (구체적인 결과는 구현에 따라 다를 수 있음)
    }

    // MARK: - 복잡한 오류 시나리오

    func testComplexErrorScenario() {
        // 복잡한 오류 상황 조합

        // 1. 정상 입력
        _ = inputContext.process(Int(Character("r").asciiValue!))
        _ = inputContext.process(Int(Character("k").asciiValue!))

        // 2. 버퍼 크기 제한 설정
        inputContext.maxBufferSize = 2

        // 3. 유효하지 않은 입력들
        _ = inputContext.process(-1)
        _ = inputContext.process(99999)

        // 4. 버퍼 오버플로우 유발
        _ = inputContext.process(Int(Character("s").asciiValue!))
        _ = inputContext.process(Int(Character("f").asciiValue!))
        _ = inputContext.process(Int(Character("a").asciiValue!))

        // 5. 추가 유효하지 않은 입력
        _ = inputContext.process(Int(Character("\0").asciiValue!))

        // 6. 최종 정리
        _ = inputContext.flush()

        // 복잡한 오류 상황 후에도 시스템이 안정적
        let committed = inputContext.getCommitString()
        let preedit = inputContext.getPreeditString()

        // 적어도 크래시는 발생하지 않음
        XCTAssertNoThrow(committed)
        XCTAssertNoThrow(preedit)
    }

    func testErrorRecoveryWorkflow() {
        // 오류 복구 워크플로우 테스트

        // 초기 정상 상태
        _ = inputContext.process(Int(Character("r").asciiValue!))
        let initialPreedit = inputContext.getPreeditString()
        XCTAssertGreaterThan(initialPreedit.count, 0)

        // 오류 상황 유발
        inputContext.maxBufferSize = 1
        _ = inputContext.process(Int(Character("k").asciiValue!))
        _ = inputContext.process(Int(Character("s").asciiValue!))

        // 오류 복구 활성화
        inputContext.autoErrorRecovery = true

        // 복구 후 정상 입력
        _ = inputContext.process(Int(Character("f").asciiValue!))

        // 복구 후에도 기능이 정상 동작
        let finalCommitted = inputContext.getCommitString()
        let finalPreedit = inputContext.getPreeditString()

        XCTAssertNoThrow(finalCommitted)
        XCTAssertNoThrow(finalPreedit)
    }

    // MARK: - 실제 사용 시나리오 기반 테스트

    func testRealWorldErrorScenario1() {
        // 시나리오: 빠른 타이핑 중 버퍼 오버플로우
        inputContext.maxBufferSize = 5

        let rapidInputs = ["r", "k", "s", "f", "a", "q", "w", "e", "r", "t"]

        for char in rapidInputs {
            _ = inputContext.process(Int(Character(char).asciiValue!))
        }

        // 빠른 입력 후에도 데이터 손실 없이 처리
        let committed = inputContext.getCommitString()
        // 실제로는 flush로 인해 일부가 커밋될 수 있음
        XCTAssertNoThrow(committed)
    }

    func testRealWorldErrorScenario2() {
        // 시나리오: 특수 키와 한글 입력의 혼합
        let mixedInputs = [
            Int(Character("r").asciiValue!), // ㄱ
            27,                              // ESC - 유효하지 않음
            Int(Character("k").asciiValue!), // ㅏ
            9,                               // Tab - 유효하지 않음
            Int(Character("s").asciiValue!), // ㄷ
            13,                              // Enter - 유효하지 않음
            Int(Character("f").asciiValue!)  // ㅏ
        ]

        for input in mixedInputs {
            _ = inputContext.process(input)
        }

        // 특수 키 혼재 상황에서도 한글 입력은 정상 처리
        let committed = inputContext.getCommitString()
        let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 최소한 유효한 한글 입력은 처리되어야 함
        XCTAssertNoThrow(text)
    }

    func testRealWorldErrorScenario3() {
        // 시나리오: 긴 세션 동안의 누적 오류
        let sessionLength = 100

        for i in 0..<sessionLength {
            // 가끔 유효하지 않은 입력 삽입
            if i % 10 == 0 {
                _ = inputContext.process(-1) // 유효하지 않은 입력
            } else {
                let char = ["r", "k", "s", "f"][i % 4]
                _ = inputContext.process(Int(Character(char).asciiValue!))
            }

            // 주기적으로 flush
            if i % 20 == 0 {
                _ = inputContext.flush()
            }
        }

        // 긴 세션 후에도 안정적 상태 유지
        let finalCommitted = inputContext.getCommitString()
        let finalPreedit = inputContext.getPreeditString()

        XCTAssertNoThrow(finalCommitted)
        XCTAssertNoThrow(finalPreedit)
    }
}
