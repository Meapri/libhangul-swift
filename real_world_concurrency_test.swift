//
// real_world_concurrency_test.swift
// 실제 프로젝트에서 LibHangul 사용 시 동시성 문제 재현
//

import Foundation

// LibHangul의 실제 구조를 모방한 클래스들
class MockHangulInputContext {
    private var buffer: [String] = []
    private var keyboard: String = "2y"
    private var outputMode: String = "syllable"

    func process(key: Int) -> Bool {
        buffer.append("\(key)")
        return true
    }

    func getPreeditString() -> [String] {
        return buffer
    }

    func flush() -> [String] {
        let result = buffer
        buffer = []
        return result
    }

    var currentKeyboard: String {
        get { keyboard }
        set { keyboard = newValue }
    }

    var currentOutputMode: String {
        get { outputMode }
        set { outputMode = newValue }
    }
}

// 실제 앱에서 발생할 수 있는 사용 패턴들
class TextInputManager {
    // 여러 스레드에서 공유되는 context - 문제의 원인!
    private var sharedContext: MockHangulInputContext?

    init() {
        sharedContext = MockHangulInputContext()
    }

    // 동시성 문제가 발생할 수 있는 메서드들
    func processUserInput(_ text: String) async -> String {
        var result = ""

        for char in text {
            if let key = char.unicodeScalars.first?.value {
                // 여러 스레드에서 동시에 접근 가능
                if sharedContext?.process(key: Int(key)) == true {
                    let preedit = sharedContext?.getPreeditString() ?? []
                    result += preedit.joined()
                }
            }
        }

        return result
    }

    func changeKeyboard(_ keyboard: String) {
        sharedContext?.currentKeyboard = keyboard
    }

    func changeOutputMode(_ mode: String) {
        sharedContext?.currentOutputMode = mode
    }

    func getContext() -> MockHangulInputContext? {
        return sharedContext
    }
}

// UI 컴포넌트 시뮬레이션
class MockTextField {
    private let manager: TextInputManager

    init(manager: TextInputManager) {
        self.manager = manager
    }

    func userTyped(_ text: String) async -> String {
        return await manager.processUserInput(text)
    }
}

// 실제 앱 시나리오 시뮬레이션
func simulateRealAppUsage() async {
    print("=== 실제 앱에서 LibHangul 사용 시 동시성 문제 시뮬레이션 ===")

    let manager = TextInputManager()

    // 1. 여러 UI 컴포넌트에서 같은 manager 사용
    let textField1 = MockTextField(manager: manager)
    let textField2 = MockTextField(manager: manager)

    // 2. 동시에 여러 입력 처리 (문제 발생 지점!)
    async let input1 = textField1.userTyped("안")
    async let input2 = textField2.userTyped("녕")

    let results = await [input1, input2]
    print("동시 입력 결과: \(results)")

    // 3. 설정 변경과 입력 처리가 동시에 발생
    let settingTask = Task {
        manager.changeKeyboard("3y")
        manager.changeOutputMode("jamo")
    }

    let inputTask = Task {
        await manager.processUserInput("하세요")
    }

    await settingTask.value
    let finalResult = await inputTask.value
    print("설정 변경 후 입력 결과: \(finalResult)")

    // 4. 직접 context 접근 (더 큰 문제!)
    if let context = manager.getContext() {
        // 다른 스레드에서 같은 context 사용
        Task {
            _ = context.process(key: 65) // 'A'
            print("다른 스레드에서 context 사용: \(context.getPreeditString())")
        }

        // 메인 스레드에서도 사용
        _ = context.process(key: 66) // 'B'
        print("메인 스레드에서 context 사용: \(context.getPreeditString())")
    }

    print("=== 시뮬레이션 완료 ===")
}

// Swift 6에서 특히 문제가 될 수 있는 패턴들
func demonstrateSwift6Issues() async {
    print("\n=== Swift 6에서 특히 문제가 될 수 있는 패턴들 ===")

    let manager = TextInputManager()

    // 1. @Sendable 클로저에서 non-Sendable 캡처
    let sendableTask: @Sendable () async -> Void = {
        // 이 클로저는 Sendable하지만 내부에서 non-Sendable을 캡처
        let context = manager.getContext()
        _ = context?.process(key: 65)
    }

    await sendableTask()

    // 2. Task.detached에서 문제
    let detachedTask = Task.detached {
        return await manager.processUserInput("테스트")
    }

    let detachedResult = await detachedTask.value
    print("Detached task result: \(detachedResult)")

    // 3. Actor에서 non-Sendable 사용 시도
    let processor = await HangulTextProcessor(manager: manager)

    let processed = await processor.process("안녕하세요")
    print("Actor 처리 결과: \(processed)")

    print("=== 패턴 데모 완료 ===")
}

// Actor를 사용한 올바른 패턴 (비교용)
actor HangulTextProcessor {
    private let manager: TextInputManager

    init(manager: TextInputManager) {
        self.manager = manager
    }

    func process(_ text: String) async -> String {
        // Actor 내부에서는 안전하게 사용 가능
        return await manager.processUserInput(text)
    }
}

// 메인 실행
func main() async {
    await simulateRealAppUsage()
    await demonstrateSwift6Issues()
}

await main()
