//
// concurrency_solution_example.swift
// Swift 6 동시성 문제 해결 예제
//

import Foundation

// MARK: - 올바른 사용법 예제

/// Swift 6에서 안전하게 LibHangul을 사용하는 방법
func safeLibHangulUsage() async {
    print("=== Swift 6에서 안전한 LibHangul 사용법 ===")

    // 1. 각 스레드/액터에서 독립적인 컨텍스트 생성
    let context = ThreadSafeHangulInputContext(keyboard: "2y")

    // 2. 안전하게 한글 입력 처리
    let result1 = await context.processText("안녕")
    print("안전한 입력 처리 결과: \(result1)")

    // 3. 여러 작업을 순차적으로 처리
    let keys = "하세요".unicodeScalars.map { Int($0.value) }
    let results = await context.processBatch(keys)
    print("배치 처리 결과 수: \(results.count)")

    print("=== 안전한 사용법 완료 ===")
}

/// 여러 액터에서 독립적으로 사용하는 예제
actor HangulInputHandler {
    private var context: ThreadSafeHangulInputContext

    init(keyboard: String = "2y") {
        self.context = ThreadSafeHangulInputContext(keyboard: keyboard)
    }

    func processInput(_ text: String) async -> String {
        return await context.processText(text).committed
            .compactMap { UnicodeScalar($0) }
            .map { Character($0) }
            .map { String($0) }
            .joined()
    }

    func changeKeyboard(_ keyboard: String) async {
        await context.setKeyboard(with: keyboard)
    }
}

func multiActorExample() async {
    print("\n=== 여러 액터에서 독립적으로 사용 ===")

    // 각 액터가 독립적인 컨텍스트를 가짐
    let handler1 = HangulInputHandler(keyboard: "2y")
    let handler2 = HangulInputHandler(keyboard: "3y")

    // 동시에 다른 키보드로 다른 텍스트 처리 가능
    async let result1 = handler1.processInput("안녕")
    async let result2 = handler2.processInput("하세요")

    let results = await [result1, result2]
    print("독립 액터 결과: \(results)")

    print("=== 다중 액터 예제 완료 ===")
}

// MARK: - 잘못된 사용법 (Swift 6에서 오류 발생)

/// ❌ 잘못된 사용법: 공유 컨텍스트
class SharedContextManager {
    // 이 패턴은 Swift 6에서 문제가 됨
    private var sharedContext: ThreadSafeHangulInputContext?

    init() {
        sharedContext = ThreadSafeHangulInputContext()
    }

    func getContext() -> ThreadSafeHangulInputContext? {
        return sharedContext
    }
}

func problematicUsage() async {
    print("\n=== ❌ 잘못된 사용법 예제 ===")

    let manager = SharedContextManager()

    // 같은 컨텍스트를 여러 Task에서 공유하는 것은 위험
    if let context = manager.getContext() {
        async let task1 = context.processText("안")
        async let task2 = context.processText("녕") // race condition 가능성

        let results = await [task1, task2]
        print("문제 있는 공유 결과: \(results)")
    }

    print("=== 잘못된 사용법 예제 완료 ===")
}

// MARK: - Sendable한 데이터 타입 예제

/// Sendable한 한글 입력 결과
struct HangulProcessingResult: Sendable {
    let originalText: String
    let processedText: String
    let keyboard: String
    let timestamp: Date

    init(originalText: String, processedText: String, keyboard: String = "2y") {
        self.originalText = originalText
        self.processedText = processedText
        self.keyboard = keyboard
        self.timestamp = Date()
    }
}

/// Sendable한 배치 처리자
actor HangulBatchProcessor {
    private let keyboard: String

    init(keyboard: String = "2y") {
        self.keyboard = keyboard
    }

    func processBatch(_ texts: [String]) async -> [HangulProcessingResult] {
        var results: [HangulProcessingResult] = []

        for text in texts {
            let context = ThreadSafeHangulInputContext(keyboard: keyboard)
            let result = await context.processText(text)

            let processedText = result.committed
                .compactMap { UnicodeScalar($0) }
                .map { Character($0) }
                .map { String($0) }
                .joined()

            results.append(HangulProcessingResult(
                originalText: text,
                processedText: processedText,
                keyboard: keyboard
            ))
        }

        return results
    }
}

func sendableBatchProcessing() async {
    print("\n=== Sendable한 배치 처리 ===")

    let processor = HangulBatchProcessor(keyboard: "2y")
    let texts = ["안녕", "하세요", "반갑습니다", "감사합니다"]

    let results = await processor.processBatch(texts)

    for result in results {
        print("'\(result.originalText)' → '\(result.processedText)' (키보드: \(result.keyboard))")
    }

    print("=== Sendable 배치 처리 완료 ===")
}

// MARK: - 마이그레이션 가이드

/// 기존 코드를 Swift 6에 맞게 마이그레이션하는 예제
class LegacyHangulInputManager {
    // 기존 코드 (Swift 6에서 문제가 될 수 있음)
    private var context: HangulInputContext?

    init() {
        context = HangulInputContext(keyboard: "2")
    }

    func processInput(_ text: String) -> String {
        var result = ""

        for char in text.unicodeScalars {
            let key = Int(char.value)
            if context?.process(key) == true {
                if let committed = context?.getCommitString() {
                    let chars = committed.compactMap { UnicodeScalar($0) }.map { Character($0) }
                    result += String(chars)
                }
            }
        }

        return result
    }
}

/// Swift 6에 맞게 마이그레이션된 버전
actor MigratedHangulInputManager {
    private var context: ThreadSafeHangulInputContext

    init(keyboard: String = "2") {
        self.context = ThreadSafeHangulInputContext(keyboard: keyboard)
    }

    func processInput(_ text: String) async -> String {
        let result = await context.processText(text)

        return result.committed
            .compactMap { UnicodeScalar($0) }
            .map { Character($0) }
            .map { String($0) }
            .joined()
    }

    func changeKeyboard(_ keyboard: String) async {
        await context.setKeyboard(with: keyboard)
    }
}

func migrationExample() async {
    print("\n=== 마이그레이션 예제 ===")

    // 새로운 방식
    let migratedManager = MigratedHangulInputManager(keyboard: "2y")
    let result = await migratedManager.processInput("안녕하세요")

    print("마이그레이션된 결과: \(result)")

    // 키보드 변경도 안전하게 가능
    await migratedManager.changeKeyboard("3y")
    let result2 = await migratedManager.processInput("반갑습니다")

    print("키보드 변경 후 결과: \(result2)")

    print("=== 마이그레이션 예제 완료 ===")
}

// MARK: - 메인 실행

func main() async {
    await safeLibHangulUsage()
    await multiActorExample()
    await problematicUsage() // 문제 있는 예제
    await sendableBatchProcessing()
    await migrationExample()
}

await main()
