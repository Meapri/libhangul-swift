import Foundation
import LibHangul

// Simple assertion helper
func assertEquals<T: Equatable>(_ actual: T, _ expected: T, _ message: String, file: String = #file, line: Int = #line) {
    if actual != expected {
        print("❌ FAILED: \(message) - Expected: \(expected), Got: \(actual) at \(file):\(line)")
        exit(1)
    } else {
        print("✅ PASSED: \(message)")
    }
}

class TestRunner {
    var inputContext: HangulInputContext!

    init() {
        // Use legacy create method or direct init depending on what's available
        // Based on previous files, HangulInputContext init is available but might be deprecated
        // Let's use the direct init as seen in tests
        inputContext = HangulInputContext(keyboard: "2")
    }

    func reset() {
        inputContext = HangulInputContext(keyboard: "2")
    }
    
    func runAll() {
        print("--- Running Basic Composition Tests ---")
        testSimpleCv()
        testSimpleCvc()
        testSyllableSeparation()
        testDoubleConsonantInput()
        testDoubleVowelInput()
        testSimpleAn()
        
        print("\n--- Running Backspace Tests ---")
        testBackspaceJongseong()
        testBackspaceJungseong()
        testBackspaceChoseong()
        testBackspaceDoubleJongseong()
        testBackspaceDoubleJungseong()
        testBackspaceSyllableBoundary()
        testBackspaceToPreviousSyllable()
        
        testMixedInput()
        testSentenceTyping()
        
        print("\n🎉 All Tests Passed!")
    }

    // MARK: - Basic Composition Tests

    func testSimpleCv() {
        reset()
        // ㄱ + ㅏ = 가
        let inputs = ["r", "k"]
        let expected = "가"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Simple CV (가)")
    }
    
    func testSimpleCvc() {
        reset()
        // ㄱ + ㅏ + ㄱ = 각
        let inputs = ["r", "k", "r"]
        let expected = "각"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Simple CVC (각)")
    }
    
    func testSyllableSeparation() {
        reset()
        // ㄱ + ㅏ + ㄱ + ㅏ = 가가
        let inputs = ["r", "k", "r", "k"]
        let expected = "가가"
        
        print("DEBUG: Starting Syllable Separation Test")
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            let processed = inputContext.process(charCode)
            let preedit = inputContext.getPreeditString().compactMap { UnicodeScalar($0) }.map { Character($0) }
            let commit = inputContext.getCommitString() // WARNING: This consumes commit string!
            // We need to accumulate commit string for final result, but here we just print it
            // Actually, we must NOT consume it if we want the final result to be correct.
            // But inputContext.getCommitString() clears it.
            // So we should handle this carefully.
            // For debugging, let's just peek or assume we consume it and append to a local var.
            // But wait, the test below calls getCommitString() at the end.
            
            // Let's rely on currentStateDescription if available or use debugBufferState
            
            // Re-implement loop to capture state properly
        }
        
        // Let's rewrite the test method to accumulation logic
        reset()
        print("DEBUG: Starting Syllable Separation Test (Retry with logging)")
        var fullCommit = ""
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            let _ = inputContext.process(charCode)
            
            let currentCommit = inputContext.getCommitString()
            let currentCommitStr = String(currentCommit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            fullCommit += currentCommitStr
            
            let preedit = inputContext.getPreeditString()
            let preeditStr = String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) })
            
            print("Input: \(key) -> Commit: '\(currentCommitStr)', Preedit: '\(preeditStr)'")
        }
        
        let flush = inputContext.flush()
        let flushStr = String(flush.compactMap { UnicodeScalar($0) }.map { Character($0) })
        fullCommit += flushStr
        print("Final Flush: '\(flushStr)'")
        
        let resultString = fullCommit
        assertEquals(resultString, expected, "Syllable Separation (가가)")
    }
    
    func testDoubleConsonantInput() {
        reset()
        // ㄲ + ㅏ = 까 (shift + r)
        let inputs = ["R", "k"]
        let expected = "까"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Double Consonant (까)")
    }
    
    func testDoubleVowelInput() {
        reset()
        // ㅇ + ㅘ = 와 (h + k)
        // d(ㅇ) + h(ㅗ) + k(ㅏ) -> 와
        let inputs = ["d", "h", "k"]
        let expected = "와"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Double Vowel (와)")
    }

    func testSimpleAn() {
        reset()
        // d(ㅇ) + k(ㅏ) + s(ㄴ) -> 안
        let inputs = ["d", "k", "s"]
        let expected = "안"
        
        for key in inputs {
            let charCode = Int(Character(key).asciiValue!)
            _ = inputContext.process(charCode)
        }
        
        // Check buffer state implicitly via string
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Simple CVC (안)")
    }

    // MARK: - Backspace Tests
    
    func processInput(_ keys: String) {
        for char in keys {
            _ = inputContext.process(Int(char.asciiValue!))
        }
    }
    
    func getPreeditString() -> String {
        let preedit = inputContext.getPreeditString()
        return String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) })
    }
    
    func getCommitString() -> String {
        let commit = inputContext.getCommitString() // This clears commit string
        return String(commit.compactMap { UnicodeScalar($0) }.map { Character($0) })
    }

    func testBackspaceJongseong() {
        reset()
        // 각 -> 가
        processInput("rkr") // ㄱ ㅏ ㄱ = 각
        
        _ = inputContext.backspace()
        
        let result = getPreeditString()
        assertEquals(result, "가", "Backspace Jongseong (각 -> 가)")
    }
    
    func testBackspaceJungseong() {
        reset()
        // 가 -> ㄱ
        processInput("rk") // ㄱ ㅏ = 가
        
        _ = inputContext.backspace()
        
        let result = getPreeditString()
        // Expect U+1100 (Choseong Kiyeok) not U+3131 (Compatibility Kiyeok)
        assertEquals(result, "\u{1100}", "Backspace Jungseong (가 -> ㄱ)")
    }
    
    func testBackspaceChoseong() {
        reset()
        // ㄱ -> (empty)
        processInput("r") // ㄱ
        
        _ = inputContext.backspace()
        
        let result = getPreeditString()
        assertEquals(result, "", "Backspace Choseong (ㄱ -> empty)")
    }

    func testBackspaceDoubleJongseong() {
        reset()
        // 닭 -> 달
        processInput("ekfr") // ㄷ ㅏ ㄹ ㄱ = 닭
        
        _ = inputContext.backspace()
        
        let result = getPreeditString()
        // 닭(B2ED) -> 달(B2EC)
        assertEquals(result, "달", "Backspace Double Jongseong (닭 -> 달)")
    }
    
    func testBackspaceDoubleJungseong() {
        reset()
        // 와 -> 오
        processInput("dhk") // ㅇ ㅗ ㅏ = 와
        
        _ = inputContext.backspace()
        
        let result = getPreeditString()
        assertEquals(result, "오", "Backspace Double Jungseong (와 -> 오)")
    }
    
    func testBackspaceSyllableBoundary() {
        reset()
        // rksk -> 가나
        processInput("rksk") 
        
        _ = inputContext.backspace()
        
        // Expect "가ㄴ" (Ga + Choseong Nieun)
        // "가" = U+AC00
        // "ㄴ" = U+1102 (Choseong Nieun)
        let commit = getCommitString()
        let preedit = getPreeditString()
        let fullString = commit + preedit
        
        assertEquals(fullString, "가\u{1102}", "Backspace Syllable Boundary (가나 -> 간)")
    }
    
    func testBackspaceToPreviousSyllable() {
        reset()
        // 아 -> (backspace) -> ㅇ -> (backspace) -> empty
        processInput("dk") // ㅇ ㅏ
        
        _ = inputContext.backspace() // ㅇ
        assertEquals(getPreeditString(), "\u{110B}", "BS to Prev Syllable (아 -> ㅇ)")
        
        _ = inputContext.backspace() // empty
        assertEquals(getPreeditString(), "", "BS to Prev Syllable (ㅇ -> empty)")
    }

    // MARK: - New Tests
    
    func testMixedInput() {
        print("\n--- Running Mixed Input Tests ---")
        reset()
        // Test pass-through of numbers (unmapped in 2-set usually)
        // "123가나456"
        // 1 2 3 r k s k 4 5 6
        
        let inputs = "123rksk456"
        processInput(inputs)
        
        // Note: The engine might return Jamo or Compat Jamo.
        // If 1,2,3 are passed through, they are preserved.
        // rksk -> 가나
        let result = getCommitString() + getPreeditString()
        assertEquals(result, "123가나456", "Mixed Input (123가나456)") 
    }
    
    func testSentenceTyping() {
        print("\n--- Running Sentence Tests ---")
        reset()
        // "안녕하세요 반갑습니다."
        let sentence1 = "dkssudgktpdy " // 안녕ㅎㅏ세요 (space)
        print("DEBUG: Processing Sentence 1: \(sentence1)")
        
        for char in sentence1 {
            let ch = Int(char.asciiValue!)
            let ret = inputContext.process(ch)
            let commit = inputContext.getCommitString().compactMap { UnicodeScalar($0) }.map { Character($0) }
            let preedit = inputContext.getPreeditString().compactMap { UnicodeScalar($0) }.map { Character($0) }
            let bufferJamo = inputContext.getPreeditString() // peek buffer essentially
            print("Key: \(char) -> Commit: '\(String(commit))', Preedit: '\(String(preedit))', Ret: \(ret)")
        }
        
        // Output result manually constructed from logs if needed, but test assertion fails on final result.
        // We want to verify behavior.
        
        reset()
        processInput(sentence1)
        let part1 = getCommitString() + getPreeditString()
        assertEquals(part1, "안녕하세요 ", "Sentence Part 1")

        
        let sentence2 = "qksrkqtmqslek." // 반갑ㅅㅡㅂㄴㅣ다.
        // q(ㅂ)k(ㅏ)s(ㄴ) -> 반
        // r(ㄱ)k(ㅏ)q(ㅂ) -> 갑
        // t(ㅅ)m(ㅡ)q(ㅂ) -> 습
        // s(ㄴ)l(ㅣ) -> 니
        // e(ㄷ)k(ㅏ) -> 다
        // . -> .
        
        processInput(sentence2)
        
        let part2 = getCommitString() + getPreeditString()
        // Note: part2 is JUST the NEW stuff if we cleared commit string previously?
        // getCommitString() clears it. So yes.
        
        assertEquals(part2, "반갑습니다.", "Sentence Part 2")
    }

}

// Run tests
let runner = TestRunner()
runner.runAll()
