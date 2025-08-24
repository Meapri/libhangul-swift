//
// concurrency_test.swift
// Swift 6 동시성 제한 테스트 - 실제 문제 재현
//

import Foundation

// Sendable하지 않은 타입들 (현재 LibHangul의 문제점)
class NonSendableContext {
    var state: Int = 0

    func process(_ input: Int) -> Bool {
        state += input
        return true
    }
}

// 동시성 문제가 발생하는 코드들
func testConcurrencyProblems() async {
    print("=== Swift 6 동시성 제한 실제 문제 테스트 ===")

    // 1. Sendable하지 않은 타입을 Task 간에 공유하는 문제
    let context = NonSendableContext()

    // Task 1에서 context 사용
    let task1 = Task {
        return context.process(1)
    }

    // Task 2에서 같은 context 사용 (동시성 문제!)
    let task2 = Task {
        return context.process(2)
    }

    let result1 = await task1.value
    let result2 = await task2.value

    print("Task 1 result: \(result1), Task 2 result: \(result2)")
    print("Final state: \(context.state)") // race condition 가능성

    // 2. @Sendable 클로저에서 Sendable하지 않은 값 캡처
    var nonSendableValue = 42

    let sendableClosure: @Sendable () -> Int = {
        // Swift 6에서는 이게 오류가 될 수 있음
        return nonSendableValue
    }

    let task3 = Task {
        return sendableClosure()
    }

    let result3 = await task3.value
    print("Sendable closure result: \(result3)")

    // 3. Dictionary와 Array의 동시성 문제
    var sharedDict = ["key": NonSendableContext()]

    let task4 = Task {
        if let ctx = sharedDict["key"] {
            return ctx.process(10)
        }
        return false
    }

    let task5 = Task {
        sharedDict["key"] = NonSendableContext()
        return true
    }

    let result4 = await task4.value
    let result5 = await task5.value

    print("Dictionary concurrency test: \(result4), \(result5)")

    print("=== 테스트 완료 ===")
}

// 실제 LibHangul 사용 시 발생할 수 있는 문제 시뮬레이션
func simulateLibHangulConcurrencyIssue() async {
    print("\n=== LibHangul 실제 사용 시 동시성 문제 시뮬레이션 ===")

    // 현재 LibHangul의 구조에서 발생할 수 있는 문제들:
    // 1. HangulInputContext는 Sendable이 아님
    // 2. 여러 스레드에서 같은 context를 공유하면 race condition
    // 3. 내부 mutable state가 보호되지 않음

    let context = NonSendableContext()

    // 동시에 여러 작업에서 같은 context 사용
    async let taskA = Task {
        return context.process(1)
    }

    async let taskB = Task {
        return context.process(2)
    }

    async let taskC = Task {
        return context.process(3)
    }

    let results = await [taskA.value, taskB.value, taskC.value]
    print("Concurrent processing results: \(results)")
    print("Final shared state: \(context.state)")

    print("이것이 LibHangul에서 발생할 수 있는 문제 유형입니다.")
}

// 메인 함수
func main() async {
    await testConcurrencyProblems()
    await simulateLibHangulConcurrencyIssue()
}

// Swift 6에서 entry point로 실행
await main()
