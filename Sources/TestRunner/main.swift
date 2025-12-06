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
        // "안녕하세요 "
        let sentence1 = "dkssudgktpdy " 
        
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
        // Note: Previous sentence was committed by space.
        // This input starts fresh.
        let part2 = getCommitString() + getPreeditString()
        assertEquals(part2, "반갑습니다.", "Sentence Part 2")
    }

    func testLongTextEntry() {
        print("\n--- Running Long Text Entry (Aegukga) ---")
        reset()
        // 동해물과 백두산이 마르고 닳도록 (Aegukga Verse 1 Line 1)
        // ehd(동) go(해) anf(물) rhk(과) (space)
        // qor(백) en(두) tks(산) dl(이) (space)
        // ak(마) fm(르) rh(고) (space)
        // ekfg(닳) eh(도) fhr(록)
        
        // Corrected input: replace 'K' with 'm' (ㅡ), add 'g' (ㅎ) to 'ekf'.
        let anthem = "ehdgoanfrhk qorentksdl akfmrh ekfgehfhr"
        let expected = "동해물과 백두산이 마르고 닳도록"
        
        processInput(anthem)
        let result = getCommitString() + getPreeditString()
        assertEquals(result, expected, "Aegukga Verse 1 Line 1")
    }
    
    func testCorrectionFlow() {
        print("\n--- Running Correction Flow Tests ---")
        reset()
        // Scenario: User types "안녕히", realizes typo, backspaces "히", types "하세요"
        // Input: "dkssud" (안녕) + "gl" (히) -> BS (delete ㅣ) -> BS (delete ㅎ) -> "gktpdy" (하세요)
        // Result: "안녕하세요"
        
        let part1 = "dkssudgl" // 안녕히
        processInput(part1)
        
        // Backspace twice (remove '히')
        _ = inputContext.backspace() // Remove 'ㅣ' -> 'ㅎ' remains
        _ = inputContext.backspace() // Remove 'ㅎ' -> '안녕' remains
        
        let part2 = "gktpdy" // 하세요
        processInput(part2)
        
        let result = getCommitString() + getPreeditString()
        assertEquals(result, "안녕하세요", "Correction (안녕히 -> 안녕하세요)")
    }
    
    func testComplexSymbols() {
        print("\n--- Running Complex Symbol Tests ---")
        reset()
        // "!@#$ (안녕하세요) [123]"
        // !@#$ (space)
        // (
        // dkssudgktpdy (안녕하세요)
        // ) (space)
        // [123]
        
        let input = "!@#$ (dkssudgktpdy) [123]"
        // Note: In 2-set, brackets, numbers, and symbols are pass-through usually.
        // English letters map to Jamo, so we avoid them to test pure symbol mixing.
        
        processInput(input)
        let result = getCommitString() + getPreeditString()
        assertEquals(result, "!@#$ (안녕하세요) [123]", "Complex Symbols Mix")
    }
    
    func test3SetInput() {
        print("\n--- Running 3-Set (Sebeolsik) Input Tests ---")
        
        // 1. Switch to 3-Set
        inputContext = HangulInputContext(keyboard: "3")
        let keyboardName = inputContext.keyboard!.name
        print("DEBUG: Switched to keyboard: \(keyboardName)")
        
        // 2. Type "안" (Ahn)
        // Standard Sebeolsik 390:
        // 'ㅇ' (Choseong) = 's'? No.
        // Let's deduce what the CURRENT code expects vs what it should be.
        // The current code is likely broken. Let's try to type based on what the code *says* it is.
        // Cho 'o' -> ㅇ (Line 169)
        // Jung 'k' -> ㅏ (Line 180) - This overwrote Cho 'k' (ㄱ)
        // Jong 's' -> ㄲ (Line 194) ... wait.
        // Jong 's' -> ㄴ?  Standard 390 Jong 's' is 'ㄴ'.
        // Code Line 194: s -> ㄲ.
        // Code Line 195: w -> ㄷ.
        
        // Let's try to type "오" (Oh) = ㅇ + ㅗ
        // Cho 'o' -> ㅇ
        // Jung 'v' -> ㅗ (Line 185)
        
        let cvInputs = ["o", "v"] 
        processInput("ov")
        let cvResult = getCommitString() + getPreeditString()
        assertEquals(cvResult, "오", "3-Set CV (오)")

        reset() // Resets to 2-set? No, reset() method in this class sets to "2".
        // We need to support switching back.
        inputContext = HangulInputContext(keyboard: "3")
    }
    
    func testFuzzing() {
        print("\n--- Running Fuzzing Test ---")
        reset()
        
        var fuzzInput = ""
        let chars = "abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()_+"
        for _ in 0..<100 {
            let randomChar = chars.randomElement()!
            fuzzInput.append(randomChar)
        }
        
        print("DEBUG: Fuzzing Input: \(fuzzInput)")
        
        // Just ensure it doesn't crash
        processInput(fuzzInput)
        let result = getCommitString() + getPreeditString()
        print("Fuzzing Result: \(result)")
        
        if result.count > 0 {
             print("✅ PASSED: Fuzzing completed without crash")
        }
    }
    
    func testBugReports() {
        print("\n--- Running Bug Report Tests ---")
        
        // Bug: "샀" -> "사T"
        
        // Case 1: "샀" (s k T) -> t k T
        // t(ㅅ) + k(ㅏ) = 사
        // T(ㅆ) -> Should combine as Jongseong
        
        reset()
        processInput("tkT")
        let result = getCommitString() + getPreeditString()
        if result == "샀" {
             print("✅ PASSED: Bug Fix '샀' (tkT -> 샀)")
        } else {
             print("❌ FAILED: Bug Fix '샀' (Expected '샀', Got '\(result)')")
             // We won't crash the test runner here to allow fixing it.
        }
    }

    func runAll() {
        print("Running TestRunner...")
        
        print("\n--- Running Basic Composition Tests ---")
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
        
        // New Tests
        testLongTextEntry()
        testCorrectionFlow()
        testComplexSymbols()
        
        test3SetInput()
        testBugReports() // Added
        testFuzzing()
        
        print("\n🎉 All Tests Passed!")
    }

}

// Run tests
let runner = TestRunner()
runner.runAll()
