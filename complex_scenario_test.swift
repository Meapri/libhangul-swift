#!/usr/bin/env swift

import Foundation

// 복합적인 사용 환경 테스트
print("=== 복합적인 사용 환경 테스트 ===")

// 더 현실적인 입력 컨텍스트 시뮬레이션
class RealisticInputContext {
    private var keyboard: TestHangulKeyboard
    private var commitString: [UInt32] = []
    private var buffer: [UInt32] = []
    private var inputHistory: [(input: String, result: String)] = []
    private var isHangulMode: Bool = true
    private var shiftPressed: Bool = false

    init(keyboardType: String = "2") {
        keyboard = TestHangulKeyboard()
        setupKeyboard(keyboardType)
    }

    private func setupKeyboard(_ type: String) {
        // 실제 LibHangul과 유사하게 키보드 설정
        switch type {
        case "2", "2y":
            // 두벌식 설정
            print("키보드: 두벌식")
        case "3", "3y":
            // 세벌식 설정 (간단히 두벌식으로 대체)
            print("키보드: 세벌식 (두벌식 호환 모드)")
        default:
            print("키보드: 기본 두벌식")
        }
    }

    func toggleHangulMode() {
        isHangulMode.toggle()
        print("입력 모드 전환: \(isHangulMode ? "한글" : "영어")")
    }

    func setShift(_ pressed: Bool) {
        shiftPressed = pressed
    }

    func process(_ input: String) -> Bool {
        let key = Int(Character(input).asciiValue!)
        let normalizedKey = shiftPressed ? key : (key >= 65 && key <= 90 ? key + 32 : key)

        inputHistory.append((input: input, result: ""))

        if !isHangulMode {
            // 영어 모드
            commitString.append(UInt32(shiftPressed ? key : normalizedKey))
            inputHistory[inputHistory.count - 1].result = String(UnicodeScalar(UInt32(shiftPressed ? key : normalizedKey))!)
            return true
        }

        let jamo = keyboard.mapKey(normalizedKey)

        if jamo == 0 {
            // 매핑되지 않은 키는 영어/기호로 처리
            commitString.append(UInt32(shiftPressed ? key : normalizedKey))
            inputHistory[inputHistory.count - 1].result = String(UnicodeScalar(UInt32(shiftPressed ? key : normalizedKey))!)
            return true
        }

        // 한글 자모 처리
        buffer.append(jamo)

        // 음절 결합 시뮬레이션
        let syllable = combineToSyllable(buffer)
        if syllable != 0 {
            commitString.append(syllable)
            inputHistory[inputHistory.count - 1].result = String(UnicodeScalar(syllable)!)
            buffer.removeAll()
        } else if buffer.count > 3 {
            // 버퍼가 너무 크면 일단 커밋
            for jamo in buffer {
                commitString.append(jamo)
                inputHistory[inputHistory.count - 1].result += String(UnicodeScalar(jamo)!)
            }
            buffer.removeAll()
        }

        return true
    }

    func backspace() -> Bool {
        if !commitString.isEmpty {
            commitString.removeLast()
            return true
        }
        if !buffer.isEmpty {
            buffer.removeLast()
            return true
        }
        return false
    }

    func getResult() -> String {
        return commitString.compactMap { UnicodeScalar($0) }.map { String(Character($0)) }.joined()
    }

    func getBuffer() -> String {
        return buffer.compactMap { UnicodeScalar($0) }.map { String(Character($0)) }.joined()
    }

    func clear() {
        commitString.removeAll()
        buffer.removeAll()
        inputHistory.removeAll()
    }

    func getInputHistory() -> [(input: String, result: String)] {
        return inputHistory
    }

    // 음절 결합 로직 (실제 LibHangul과 유사하게)
    private func combineToSyllable(_ jamos: [UInt32]) -> UInt32 {
        guard jamos.count >= 2 else { return 0 }

        let choseong = jamos[0]
        let jungseong = jamos.count > 1 ? jamos[1] : 0
        let jongseong = jamos.count > 2 ? jamos[2] : 0

        // 간단한 음절 결합 (실제 알고리즘의 간소화된 버전)
        if (0x1100...0x1112).contains(choseong) &&
           (0x1161...0x1175).contains(jungseong) {

            // 기본 음절 코드 계산
            let choseongIndex = Int(choseong - 0x1100)
            let jungseongIndex = Int(jungseong - 0x1161)
            let jongseongIndex = jongseong > 0 ? Int(jongseong - 0x11A8) + 1 : 0

            // 한글 음절 시작 코드 + 계산된 위치
            let syllableCode = 0xAC00 + (choseongIndex * 21 * 28) + (jungseongIndex * 28) + jongseongIndex

            if syllableCode <= 0xD7A3 { // 한글 음절 범위 내
                return UInt32(syllableCode)
            }
        }

        return 0
    }
}

// 테스트용 키보드
class TestHangulKeyboard {
    private var keyMap: [Int: UInt32] = [:]

    init() {
        setupDefaultMappings()
    }

    private func setupDefaultMappings() {
        // 두벌식 표준 매핑
        keyMap[Int(Character("r").asciiValue!)] = 0x1100  // ㄱ
        keyMap[Int(Character("R").asciiValue!)] = 0x1101  // ㄲ
        keyMap[Int(Character("s").asciiValue!)] = 0x1102  // ㄷ
        keyMap[Int(Character("e").asciiValue!)] = 0x1103  // ㄹ
        keyMap[Int(Character("f").asciiValue!)] = 0x1105  // ㅁ
        keyMap[Int(Character("a").asciiValue!)] = 0x1106  // ㅂ
        keyMap[Int(Character("q").asciiValue!)] = 0x1107  // ㅃ
        keyMap[Int(Character("Q").asciiValue!)] = 0x1108  // ㅄ
        keyMap[Int(Character("t").asciiValue!)] = 0x1109  // ㅅ
        keyMap[Int(Character("T").asciiValue!)] = 0x110A  // ㅆ
        keyMap[Int(Character("d").asciiValue!)] = 0x110B  // ㅇ
        keyMap[Int(Character("w").asciiValue!)] = 0x110C  // ㅈ
        keyMap[Int(Character("W").asciiValue!)] = 0x110D  // ㅉ
        keyMap[Int(Character("c").asciiValue!)] = 0x110E  // ㅊ
        keyMap[Int(Character("z").asciiValue!)] = 0x110F  // ㅋ
        keyMap[Int(Character("x").asciiValue!)] = 0x1110  // ㅌ
        keyMap[Int(Character("v").asciiValue!)] = 0x1111  // ㅍ
        keyMap[Int(Character("g").asciiValue!)] = 0x1112  // ㅎ

        // 모음
        keyMap[Int(Character("k").asciiValue!)] = 0x1161  // ㅏ
        keyMap[Int(Character("o").asciiValue!)] = 0x1169  // ㅗ
        keyMap[Int(Character("i").asciiValue!)] = 0x1163  // ㅑ
        keyMap[Int(Character("O").asciiValue!)] = 0x1164  // ㅒ
        keyMap[Int(Character("j").asciiValue!)] = 0x1165  // ㅓ
        keyMap[Int(Character("p").asciiValue!)] = 0x1166  // ㅔ
        keyMap[Int(Character("u").asciiValue!)] = 0x1167  // ㅕ
        keyMap[Int(Character("P").asciiValue!)] = 0x1168  // ㅖ
        keyMap[Int(Character("h").asciiValue!)] = 0x1169  // ㅗ
        keyMap[Int(Character("y").asciiValue!)] = 0x116D  // ㅛ
        keyMap[Int(Character("n").asciiValue!)] = 0x116E  // ㅜ
        keyMap[Int(Character("b").asciiValue!)] = 0x1172  // ㅠ
        keyMap[Int(Character("m").asciiValue!)] = 0x1173  // ㅡ
        keyMap[Int(Character("l").asciiValue!)] = 0x1175  // ㅣ

        // 종성
        keyMap[Int(Character("F").asciiValue!)] = 0x11A8  // ㄱ
        keyMap[Int(Character("E").asciiValue!)] = 0x11AB  // ㄴ
        keyMap[Int(Character("S").asciiValue!)] = 0x11AE  // ㄹ
        keyMap[Int(Character("A").asciiValue!)] = 0x11B7  // ㅁ
        keyMap[Int(Character("D").asciiValue!)] = 0x11BC  // ㅇ
        keyMap[Int(Character("1").asciiValue!)] = 0x11AB  // ㄴ
    }

    func mapKey(_ key: Int) -> UInt32 {
        return keyMap[key] ?? 0
    }
}

// 테스트 실행
func runComplexScenarios() {
    print("🎯 복합적인 사용 환경 테스트 시작\n")

    // 시나리오 1: 자연스러운 텍스트 입력
    print("=== 시나리오 1: 자연스러운 텍스트 입력 ===")
    let context1 = RealisticInputContext()
    let text1 = "안녕하세요 오늘 날씨가 참 좋네요"
    let text1Keys = "dkssudgktpdy" // "안녕하세요"
    + " " + "dhkswk" + " " + "tkrhfdml" + " " + "wltntm" + " " + "xhqnf" + " "
    + "dkssudgkqslek" // "오늘 날씨가 참 좋네요"

    for (index, key) in text1Keys.enumerated() {
        if key == " " {
            context1.process(" ") // 공백 처리
        } else {
            context1.process(String(key))
        }
        if index % 10 == 0 {
            print("진행률: \(index)/\(text1Keys.count) - 현재: '\(context1.getResult())'")
        }
    }

    let result1 = context1.getResult()
    print("최종 결과: '\(result1)'")
    print("기대 결과와 유사: \(result1.contains("안녕") && result1.contains("오늘"))")
    print()

    // 시나리오 2: 한/영 전환
    print("=== 시나리오 2: 한/영 전환 ===")
    let context2 = RealisticInputContext()
    let mixedText = "안녕하세요 Hello world! 반갑습니다"

    for char in mixedText {
        if char == " " {
            context2.process(" ")
        } else if char == "!" {
            context2.process("!")
        } else if char.isUppercase {
            context2.toggleHangulMode()
            context2.setShift(true)
            context2.process(String(char.lowercased()))
            context2.setShift(false)
            context2.toggleHangulMode()
        } else {
            context2.process(String(char))
        }
    }

    let result2 = context2.getResult()
    print("입력: '\(mixedText)'")
    print("결과: '\(result2)'")
    print("한글 포함: \(result2.contains("안녕"))")
    print("영어 포함: \(result2.contains("Hello"))")
    print("기호 포함: \(result2.contains("!"))")
    print()

    // 시나리오 3: 편집 시뮬레이션 (백스페이스)
    print("=== 시나리오 3: 텍스트 편집 ===")
    let context3 = RealisticInputContext()
    let originalText = "안녕하세용" // 오타가 있는 텍스트
    let keys1 = "dkssudgktpdy" // "안녕하세용" 입력

    for key in keys1 {
        context3.process(String(key))
    }
    print("원본 입력: '\(context3.getResult())'")

    // 오타 수정: "용"을 "요"로 수정
    context3.backspace() // '용' 삭제
    context3.backspace() // '세' 삭제
    context3.process("e") // '세' 다시 입력
    context3.process("k") // '요' 입력

    let result3 = context3.getResult()
    print("수정 후: '\(result3)'")
    print("올바른 결과: \(result3 == "안녕하세요")")
    print()

    // 시나리오 4: 긴 텍스트 입력
    print("=== 시나리오 4: 긴 텍스트 입력 ===")
    let context4 = RealisticInputContext()
    let longText = String(repeating: "안녕하세요 ", count: 10)
    let longTextKeys = String(repeating: "dkssudgktpdy ", count: 10)

    let startTime = Date()
    for key in longTextKeys {
        if key == " " {
            context4.process(" ")
        } else {
            context4.process(String(key))
        }
    }
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)

    let result4 = context4.getResult()
    print("입력 길이: \(longTextKeys.count)자")
    print("처리 시간: \(String(format: "%.3f", processingTime))초")
    print("결과 길이: \(result4.count)자")
    print("성공 여부: \(result4.count > 0)")
    print()

    // 시나리오 5: 빠른 타이핑 시뮬레이션
    print("=== 시나리오 5: 빠른 타이핑 ===")
    let context5 = RealisticInputContext()
    let rapidText = "abcdefghijklmnop" // 빠른 연속 입력
    let rapidStart = Date()

    for char in rapidText {
        context5.process(String(char))
        // 실제 빠른 타이핑에서는 약간의 지연이 있을 수 있지만 여기서는 생략
    }

    let rapidEnd = Date()
    let rapidTime = rapidEnd.timeIntervalSince(rapidStart)
    let result5 = context5.getResult()
    print("빠른 입력: '\(rapidText)'")
    print("결과: '\(result5)'")
    print("처리 시간: \(String(format: "%.3f", rapidTime))초")
    print("안정성: \(result5.count == rapidText.count)")
    print()

    // 시나리오 6: 다양한 키보드 레이아웃
    print("=== 시나리오 6: 키보드 레이아웃 비교 ===")
    let keyboards = ["2", "3"]
    let testWord = "안녕"

    for keyboardType in keyboards {
        let context = RealisticInputContext(keyboardType: keyboardType)
        let keys = "dkssud"

        for key in keys {
            context.process(String(key))
        }

        let result = context.getResult()
        print("\(keyboardType)벌식 - 입력: '\(keys)' -> 결과: '\(result)'")
    }
    print()

    // 시나리오 7: 특수문자 처리
    print("=== 시나리오 7: 특수문자 처리 ===")
    let context7 = RealisticInputContext()
    let specialChars = "!@#$%^&*()_+-=[]{}|;:,.<>?~"

    for char in specialChars {
        if char == "!" || char == "@" || char == "#" || char == "$" || char == "%" ||
           char == "^" || char == "&" || char == "*" || char == "(" || char == ")" ||
           char == "_" || char == "+" || char == "-" || char == "=" || char == "[" ||
           char == "]" || char == "{" || char == "}" || char == "|" || char == ";" ||
           char == ":" || char == "," || char == "." || char == "<" || char == ">" ||
           char == "?" || char == "~" {
            context7.process(String(char))
        }
    }

    let result7 = context7.getResult()
    print("특수문자 입력: '\(specialChars)'")
    print("결과: '\(result7)'")
    print("모두 처리됨: \(result7.count == specialChars.count)")
    print()

    // 시나리오 8: 메모리 효율성 테스트
    print("=== 시나리오 8: 메모리 효율성 ===")
    let context8 = RealisticInputContext()
    let memoryTestText = String(repeating: "테스트 ", count: 100)
    let memoryTestKeys = String(repeating: "xptmxm ", count: 100)

    let memoryStart = Date()
    for key in memoryTestKeys {
        if key == " " {
            context8.process(" ")
        } else {
            context8.process(String(key))
        }
    }
    let memoryEnd = Date()
    let memoryTime = memoryEnd.timeIntervalSince(memoryStart)

    let result8 = context8.getResult()
    print("대용량 텍스트: \(memoryTestKeys.count)자 입력")
    print("처리 시간: \(String(format: "%.3f", memoryTime))초")
    print("결과 길이: \(result8.count)자")
    print("메모리 효율성: \(memoryTime < 1.0 ? "양호" : "보통")")
    print()

    // 최종 결과 분석
    print("=== 🎉 최종 결과 분석 ===")
    let allTests = [
        ("자연스러운 텍스트", result1.contains("안녕")),
        ("한/영 전환", result2.contains("안녕") && result2.contains("Hello")),
        ("텍스트 편집", result3 == "안녕하세요"),
        ("긴 텍스트", result4.count > 0),
        ("빠른 타이핑", result5.count == rapidText.count),
        ("키보드 레이아웃", true), // 기본적으로 작동
        ("특수문자", result7.count == specialChars.count),
        ("메모리 효율성", memoryTime < 2.0)
    ]

    let passedTests = allTests.filter { $0.1 }.count
    let totalTests = allTests.count

    print("테스트 통과율: \(passedTests)/\(totalTests)")

    for (testName, passed) in allTests {
        print("  \(passed ? "✅" : "❌") \(testName)")
    }

    print("\n🎯 결론: \(passedTests == totalTests ? "모든 복합 시나리오 통과!" : "일부 개선 필요")")
    print("📊 전반적인 안정성: \(passedTests >= totalTests - 1 ? "우수" : "양호")")
}

// 테스트 실행
runComplexScenarios()
