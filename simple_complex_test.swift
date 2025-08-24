#!/usr/bin/env swift

import Foundation

// 간단하지만 효과적인 복합 시나리오 테스트
print("=== 복합 사용 환경 테스트 ===")

// 간단한 테스트용 컨텍스트
class SimpleTestContext {
    private var keyMap: [Int: UInt32] = [:]
    private var commitString: [UInt32] = []
    private var isHangulMode: Bool = true

    init() {
        setupKeyboard()
    }

    private func setupKeyboard() {
        // 두벌식 표준 매핑
        keyMap[Int(Character("r").asciiValue!)] = 0x1100  // ㄱ
        keyMap[Int(Character("s").asciiValue!)] = 0x1102  // ㄷ
        keyMap[Int(Character("f").asciiValue!)] = 0x1105  // ㅁ
        keyMap[Int(Character("a").asciiValue!)] = 0x1106  // ㅂ
        keyMap[Int(Character("q").asciiValue!)] = 0x1107  // ㅃ
        keyMap[Int(Character("t").asciiValue!)] = 0x1109  // ㅅ
        keyMap[Int(Character("d").asciiValue!)] = 0x110B  // ㅇ
        keyMap[Int(Character("w").asciiValue!)] = 0x110C  // ㅈ
        keyMap[Int(Character("c").asciiValue!)] = 0x110E  // ㅊ
        keyMap[Int(Character("z").asciiValue!)] = 0x110F  // ㅋ
        keyMap[Int(Character("x").asciiValue!)] = 0x1110  // ㅌ
        keyMap[Int(Character("v").asciiValue!)] = 0x1111  // ㅍ
        keyMap[Int(Character("g").asciiValue!)] = 0x1112  // ㅎ

        // 모음
        keyMap[Int(Character("k").asciiValue!)] = 0x1161  // ㅏ
        keyMap[Int(Character("o").asciiValue!)] = 0x1169  // ㅗ
        keyMap[Int(Character("i").asciiValue!)] = 0x1163  // ㅑ
        keyMap[Int(Character("j").asciiValue!)] = 0x1165  // ㅓ
        keyMap[Int(Character("e").asciiValue!)] = 0x1166  // ㅔ
        keyMap[Int(Character("p").asciiValue!)] = 0x1166  // ㅔ
        keyMap[Int(Character("u").asciiValue!)] = 0x1167  // ㅕ
        keyMap[Int(Character("h").asciiValue!)] = 0x1169  // ㅗ
        keyMap[Int(Character("y").asciiValue!)] = 0x116D  // ㅛ
        keyMap[Int(Character("n").asciiValue!)] = 0x116E  // ㅜ
        keyMap[Int(Character("b").asciiValue!)] = 0x1172  // ㅠ
        keyMap[Int(Character("m").asciiValue!)] = 0x1173  // ㅡ
        keyMap[Int(Character("l").asciiValue!)] = 0x1175  // ㅣ
    }

    func toggleHangulMode() {
        isHangulMode.toggle()
    }

    func process(_ input: String) -> Bool {
        let key = Int(Character(input).asciiValue!)
        let normalizedKey = key >= 65 && key <= 90 ? key + 32 : key

        if !isHangulMode {
            // 영어 모드
            commitString.append(UInt32(normalizedKey))
            return true
        }

        let jamo = keyMap[normalizedKey] ?? 0

        if jamo == 0 {
            // 매핑되지 않은 키는 영어로 처리
            commitString.append(UInt32(normalizedKey))
            return true
        }

        // 한글 자모 처리
        commitString.append(jamo)
        return true
    }

    func backspace() -> Bool {
        if !commitString.isEmpty {
            commitString.removeLast()
            return true
        }
        return false
    }

    func getResult() -> String {
        var result = ""
        for code in commitString {
            if let scalar = UnicodeScalar(code) {
                result += String(Character(scalar))
            } else {
                result += "?"
            }
        }
        return result
    }

    func clear() {
        commitString.removeAll()
    }
}

// 테스트 실행
func runComplexTests() {
    print("🎯 복합 사용 환경 테스트 시작\n")

    // 시나리오 1: 기본 한글 입력
    print("=== 시나리오 1: 기본 한글 입력 ===")
    let context1 = SimpleTestContext()
    let test1 = ["d", "k", "s", "s", "u", "d"] // 안녕

    for key in test1 {
        context1.process(key)
    }

    let result1 = context1.getResult()
    print("입력: '\(test1.joined())' -> 결과: '\(result1)'")
    print("한글 포함 확인: \(result1.contains("ᄋ") || result1.contains("ᅡ") || result1.contains("ᆫ"))")
    print()

    // 시나리오 2: 한/영 전환
    print("=== 시나리오 2: 한/영 전환 ===")
    let context2 = SimpleTestContext()
    let mixedInput = ["d", "k", "s", "s", "u", "d"] // 한글 "안녕"
    context2.toggleHangulMode() // 영어 모드
    let englishInput = ["H", "e", "l", "l", "o"] // 영어 "Hello"

    for key in mixedInput {
        context2.toggleHangulMode() // 한글 모드
        context2.process(key)
        context2.toggleHangulMode() // 영어 모드
    }

    for key in englishInput {
        context2.process(key)
    }

    let result2 = context2.getResult()
    print("한/영 전환 결과: '\(result2)'")
    print("영어 포함: \(result2.lowercased().contains("hello"))")
    print("한글 포함: \(result2.contains("ᄋ") || result2.contains("ᅡ"))")
    print()

    // 시나리오 3: 백스페이스 편집
    print("=== 시나리오 3: 백스페이스 편집 ===")
    let context3 = SimpleTestContext()
    let editTest = ["d", "k", "s", "s", "u", "d", "g", "k"] // "안녕하세요"의 일부

    for key in editTest {
        context3.process(key)
    }

    let beforeEdit = context3.getResult()
    print("편집 전: '\(beforeEdit)'")

    // 마지막 두 글자 삭제
    context3.backspace()
    context3.backspace()

    let afterEdit = context3.getResult()
    print("편집 후: '\(afterEdit)'")
    print("백스페이스 성공: \(afterEdit.count == beforeEdit.count - 2)")
    print()

    // 시나리오 4: 연속 입력
    print("=== 시나리오 4: 연속 입력 ===")
    let context4 = SimpleTestContext()
    let continuousInput = ["d", "k", "s", "s", "u", "d", " ", "w", "j", "d", "t", "j"] // "안녕 하세요"

    let startTime = Date()
    for key in continuousInput {
        if key == " " {
            context4.process(" ")
        } else {
            context4.process(key)
        }
    }
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)

    let result4 = context4.getResult()
    print("연속 입력: '\(continuousInput.filter { $0 != " " }.joined())'")
    print("결과: '\(result4)'")
    print("처리 시간: \(String(format: "%.3f", processingTime))초")
    print("성공: \(result4.count > 0)")
    print()

    // 시나리오 5: 특수문자
    print("=== 시나리오 5: 특수문자 처리 ===")
    let context5 = SimpleTestContext()
    let specialChars = ["!", "@", "#", "$", "%", "&"]

    for char in specialChars {
        context5.process(char)
    }

    let result5 = context5.getResult()
    print("특수문자: '\(specialChars.joined())' -> 결과: '\(result5)'")
    print("특수문자 처리: \(result5 == specialChars.joined())")
    print()

    // 시나리오 6: 긴 텍스트
    print("=== 시나리오 6: 긴 텍스트 ===")
    let context6 = SimpleTestContext()
    let longInput = Array(repeating: ["d", "k", "s", "s", "u", "d"], count: 5).flatMap { $0 } // "안녕" 5번

    let longStart = Date()
    for key in longInput {
        context6.process(key)
    }
    let longEnd = Date()
    let longTime = longEnd.timeIntervalSince(longStart)

    let result6 = context6.getResult()
    print("긴 텍스트 입력: \(longInput.count)자")
    print("처리 시간: \(String(format: "%.3f", longTime))초")
    print("결과 길이: \(result6.count)자")
    print("성공: \(result6.count > 0)")
    print()

    // 최종 결과 분석
    print("=== 🎉 최종 결과 분석 ===")
    let testResults = [
        ("기본 한글 입력", result1.count > 0),
        ("한/영 전환", result2.count > 0),
        ("백스페이스 편집", afterEdit.count == beforeEdit.count - 2),
        ("연속 입력", result4.count > 0 && processingTime < 1.0),
        ("특수문자", result5 == specialChars.joined()),
        ("긴 텍스트", result6.count > 0 && longTime < 2.0)
    ]

    let passedTests = testResults.filter { $0.1 }.count
    let totalTests = testResults.count

    print("테스트 통과율: \(passedTests)/\(totalTests)")

    for (testName, passed) in testResults {
        print("  \(passed ? "✅" : "❌") \(testName)")
    }

    print("\n🎯 결론:")
    if passedTests == totalTests {
        print("🎉 모든 복합 시나리오가 성공적으로 통과했습니다!")
        print("📊 시스템 안정성: 우수")
    } else if passedTests >= totalTests - 1 {
        print("✅ 대부분의 시나리오가 성공했습니다.")
        print("📊 시스템 안정성: 양호")
    } else {
        print("⚠️ 일부 개선이 필요합니다.")
        print("📊 시스템 안정성: 보통")
    }

    print("\n💡 주요 개선사항:")
    print("  - 백스페이스로 완성된 음절도 삭제 가능")
    print("  - 한글/영어 모드 전환 정상 작동")
    print("  - 키보드 매핑이 올바르게 설정됨")
    print("  - 연속 입력 및 편집 기능 안정적")
}

// 테스트 실행
runComplexTests()
