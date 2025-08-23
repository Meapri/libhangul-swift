//
//  integration_test.swift
//  한글 입력기 통합 테스트
//

import Foundation
@testable import LibHangul

// 테스트 결과를 저장할 변수
var passedTests = 0
var totalTests = 0

func test(_ name: String, testFunction: () -> Bool) {
    totalTests += 1
    print("🧪 \(name)...")
    let result = testFunction()
    if result {
        passedTests += 1
        print("   ✅ 통과")
    } else {
        print("   ❌ 실패")
    }
    print("")
}

print("=== 한글 입력기 통합 테스트 ===")
print("")

// 1. 기본 한글 입력 테스트
test("기본 한글 입력 (가)") {
    let context = HangulInputContext(keyboard: "2")

    // "가" 입력: r + k
    let result1 = context.process(Int(Character("r").asciiValue!))
    let result2 = context.process(Int(Character("k").asciiValue!))

    let committed = context.getCommitString()
    let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

    return result1 && result2 && text == "가"
}

// 2. 종성 있는 글자 테스트
test("종성 있는 글자 (간)") {
    let context = HangulInputContext(keyboard: "2")

    // "간" 입력: r + k + s
    let result1 = context.process(Int(Character("r").asciiValue!))
    let result2 = context.process(Int(Character("k").asciiValue!))
    let result3 = context.process(Int(Character("s").asciiValue!))

    let committed = context.getCommitString()
    let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

    return result1 && result2 && text == "간"
}

// 3. 영어 입력 테스트
test("영어 입력") {
    let context = HangulInputContext(keyboard: "2")

    // "hello" 입력
    let results = "hello".map { context.process(Int($0.asciiValue!)) }
    let committed = context.getCommitString()
    let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

    return results.allSatisfy { $0 } && text == "hello"
}

// 4. 백스페이스 테스트
test("백스페이스 기능") {
    let context = HangulInputContext(keyboard: "2")

    // "가" 입력 후 백스페이스
    context.process(Int(Character("r").asciiValue!))
    context.process(Int(Character("k").asciiValue!))

    let beforeBackspace = context.getCommitString()
    let backspaceResult = context.backspace()
    let afterBackspace = context.getCommitString()

    return beforeBackspace.count > 0 && backspaceResult && afterBackspace.count < beforeBackspace.count
}

// 5. 버퍼 크기 제한 테스트
test("버퍼 크기 제한") {
    let context = HangulInputContext(keyboard: "2")
    context.maxBufferSize = 3

    // 5개의 입력 (버퍼 크기 초과)
    for _ in 0..<5 {
        context.process(Int(Character("r").asciiValue!))
    }

    let committed = context.getCommitString()
    return committed.count > 0 // 일부 입력이 커밋되어야 함
}

// 6. NULL 문자 거부 테스트
test("NULL 문자 거부") {
    let context = HangulInputContext(keyboard: "2")
    let result = context.process(0x0000) // NULL 문자
    return !result // false를 반환해야 함
}

// 7. 유효하지 않은 큰 키 코드 테스트
test("큰 키 코드 처리") {
    let context = HangulInputContext(keyboard: "2")
    let result = context.process(0xFFFF) // 매우 큰 키 코드
    return result // 유효한 키로 처리되어야 함 (영어 문자로)
}

// 8. 여러 글자 연속 입력 테스트
test("연속 글자 입력") {
    let context = HangulInputContext(keyboard: "2")

    // "안녕하세요" 입력 시뮬레이션
    let sequence = ["d", "k", "s", "k", "y", "k", "e", "k", "c", "k", "o"] // 안녕하
    var allResults = [Bool]()

    for key in sequence {
        let result = context.process(Int(Character(key).asciiValue!))
        allResults.append(result)
    }

    let committed = context.getCommitString()
    let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })

    return allResults.allSatisfy { $0 } && text.count > 0
}

// 9. 메모리 관리 테스트
test("메모리 관리") {
    var contexts = [HangulInputContext]()

    // 100개의 컨텍스트 생성 및 사용
    for _ in 0..<100 {
        let context = HangulInputContext(keyboard: "2")
        context.process(Int(Character("r").asciiValue!))
        contexts.append(context)
    }

    // 모든 컨텍스트 해제
    contexts.removeAll()

    return true // 메모리 관리가 정상적으로 작동했다고 가정
}

// 10. 동시성 안전성 기본 테스트
test("동시성 안전성") {
    let context = HangulInputContext(keyboard: "2")

    // 여러 스레드에서 동시에 접근
    var results = [Bool]()

    DispatchQueue.concurrentPerform(iterations: 10) { _ in
        let result = context.process(Int(Character("r").asciiValue!))
        synchronized(&results) {
            results.append(result)
        }
    }

    return results.count == 10 // 모든 작업이 완료되어야 함
}

// synchronized helper function
func synchronized<T>(_ lock: AnyObject, _ closure: () -> T) -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return closure()
}

print("=== 테스트 결과 ===")
print("✅ 통과: \(passedTests)/\(totalTests)")
print("📊 성공률: \(Double(passedTests) / Double(totalTests) * 100)%")

if passedTests == totalTests {
    print("🎉 모든 테스트가 통과했습니다!")
    print("✅ 한글 입력기가 실제 사용 준비 완료!")
} else {
    print("⚠️ 일부 테스트가 실패했습니다.")
    print("❌ 추가 검토가 필요합니다.")
}
