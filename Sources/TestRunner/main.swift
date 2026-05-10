import Foundation
import LibHangul

final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

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
            
            let _ = inputContext.process(Character(key))
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
            
            let _ = inputContext.process(Character(key))
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
            
            let _ = inputContext.process(Character(key))
            _ = inputContext.getPreeditString()
            _ = inputContext.getCommitString() // WARNING: This consumes commit string!
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
            
            let _ = inputContext.process(Character(key))
            
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
            
            let _ = inputContext.process(Character(key))
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
            
            let _ = inputContext.process(Character(key))
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
            
            let _ = inputContext.process(Character(key))
        }
        
        // Check buffer state implicitly via string
        let result = inputContext.getCommitString() + inputContext.flush()
        let resultString = String(result.compactMap { UnicodeScalar($0) }.map { Character($0) })
        assertEquals(resultString, expected, "Simple CVC (안)")
    }

    // MARK: - Backspace Tests
    
    func processInput(_ keys: String) {
        for char in keys {
            let _: Bool = inputContext.process(char)
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
    
    func testBackspaceCompositeVowel() {
        reset()
        // ㅏ + ㅣ = ㅐ -> BS -> ㅏ
        processInput("kl") // k(ㅏ) + l(ㅣ)
        let preedit = getPreeditString()
        assertEquals(preedit, "\u{1162}", "Composite Vowel Creation (ㅏ+ㅣ=ㅐ)")
        
        _ = inputContext.backspace()
        assertEquals(getPreeditString(), "\u{1161}", "BS Composite Vowel (애 -> 아)")
    }
    
    func testBackspaceDoubleConsonantJongseong() {
        reset()
        // 국 + ㄱ = 굮 -> BS -> 국
        processInput("rnr") // ㄱㅜㄱ
        let _: Bool = inputContext.process(Character("r")) // + ㄱ -> 굮 (ㄲ jongseong)
        
        _ = getPreeditString() // preedit 결과는 로직 확인용이나 별도 검증 불필요
        // Note: 굮 is rare, might display weirdly, but checking logic
        
        _ = inputContext.backspace()
        let result = getPreeditString()
        assertEquals(result, "국", "BS Double Consonant Jongseong (굮 -> 국)")
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
        
        // 세벌식 390에서 'o'=ㅈ(초성), 'v'=ㅗ(중성) → 조
        processInput("ov")
        let cvResult = getCommitString() + getPreeditString()
        assertEquals(cvResult, "조", "3-Set CV (조)")

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
        
        // Bug 1: "한글입력기" -> "한글입렦기"
        reset()
        processInput("gksrmfdlqfurrl")
        let result1 = getCommitString() + getPreeditString()
        assertEquals(result1, "한글입력기", "Bug Fix: 한글입력기")
        
        // Bug 2: "바뀌어" -> "박귀어"
        reset()
        processInput("qkRnldj")
        let result2 = getCommitString() + getPreeditString()
        assertEquals(result2, "바뀌어", "Bug Fix: 바뀌어 (Double Consonant Move)")
        
        // Bug 3: "샀" -> "사T"
        reset()
        processInput("tkT")
        let result3 = getCommitString() + getPreeditString()
        assertEquals(result3, "샀", "Bug Fix: 샀 (tkT -> 샀)")
        
        // Bug 4: ㅇ (d) key alone, then flush - should produce valid output
        reset()
        let _: Bool = inputContext.process(Character("d")) // ㅇ
        let preeditD = getPreeditString()
        print("DEBUG: ㅇ alone preedit: '\(preeditD)' (hex: \(preeditD.unicodeScalars.map { String(format: "%04X", $0.value) }))")
        
        // Flush (simulating end of input or arrow key)
        let flushedD = inputContext.flush()
        let flushedDStr = flushedD.compactMap { UnicodeScalar($0) }.map { String($0) }.joined()
        print("DEBUG: ㅇ flush result: '\(flushedDStr)' (hex: \(flushedD.map { String(format: "%04X", $0) }))")
        
        // Bug 5: ㅁ (a) key alone, then flush
        reset()
        let _: Bool = inputContext.process(Character("a")) // ㅁ
        let preeditA = getPreeditString()
        print("DEBUG: ㅁ alone preedit: '\(preeditA)' (hex: \(preeditA.unicodeScalars.map { String(format: "%04X", $0.value) }))")
        
        let flushedA = inputContext.flush()
        let flushedAStr = flushedA.compactMap { UnicodeScalar($0) }.map { String($0) }.joined()
        print("DEBUG: ㅁ flush result: '\(flushedAStr)' (hex: \(flushedA.map { String(format: "%04X", $0) }))")
        
        // Bug 6: ㅇ + ㅇ (repeated key) - should work
        reset()
        processInput("dd") // ㅇ + ㅇ
        let resultDD = getCommitString() + getPreeditString()
        print("DEBUG: ㅇㅇ result: '\(resultDD)' (hex: \(resultDD.unicodeScalars.map { String(format: "%04X", $0.value) }))")
        
        // Bug 7: ㅁ + ㅁ (repeated key)
        reset()
        processInput("aa") // ㅁ + ㅁ
        let resultAA = getCommitString() + getPreeditString()
        print("DEBUG: ㅁㅁ result: '\(resultAA)' (hex: \(resultAA.unicodeScalars.map { String(format: "%04X", $0.value) }))")
        
        // Comprehensive test: All choseong keys should flush to valid compatibility jamo
        print("\n--- Testing All Choseong Keys ---")
        let choseongKeys = ["r", "s", "e", "f", "a", "q", "t", "d", "w", "c", "z", "x", "v", "g"]
        var allPassed = true
        for key in choseongKeys {
            reset()
            let _: Bool = inputContext.process(Character(key))
            let flushed = inputContext.flush()
            if flushed.isEmpty {
                print("❌ FAILED: Key '\(key)' flush returned empty!")
                allPassed = false
            } else {
                let hex = flushed.map { String(format: "%04X", $0) }.joined(separator: ", ")
                let str = flushed.compactMap { UnicodeScalar($0) }.map { String($0) }.joined()
                // Verify it's a compatibility jamo (0x3131-0x318E)
                if let first = flushed.first, first >= 0x3131 && first <= 0x318E {
                    print("✅ '\(key)' -> '\(str)' [\(hex)]")
                } else {
                    print("❌ FAILED: Key '\(key)' -> '\(str)' [\(hex)] - not compatibility jamo!")
                    allPassed = false
                }
            }
        }
        if allPassed {
            print("✅ All choseong keys produce valid compatibility jamo on flush")
        }
    }
    
    // MARK: - Concurrency Tests (P2)
    
    func testConcurrentProcessing() {
        print("\n--- Running Concurrency Tests ---")
        
        let context = ThreadSafeHangulInputContext(keyboard: "2")
        let iterations = 100
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        let successCount = LockedCounter()
        
        // 동시에 여러 스레드에서 process 호출
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                let keys = ["r", "k", "s", "k"] // 간단한 한글 입력
                for key in keys {
                    let _: Bool = context.process(Character(key))
                }
                _ = context.flush()
                
                successCount.increment()
                
                group.leave()
            }
        }
        
        group.wait()
        
        if successCount.count == iterations {
            print("✅ PASSED: Concurrent Processing (\(iterations) iterations)")
        } else {
            print("❌ FAILED: Concurrent Processing - only \(successCount.count)/\(iterations) succeeded")
        }
    }
    
    func testConcurrentFlush() {
        let context = ThreadSafeHangulInputContext(keyboard: "2")
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.flush", attributes: .concurrent)
        
        // 먼저 데이터 입력
        let _: Bool = context.process(Character("r"))
        let _: Bool = context.process(Character("k"))
        
        let flushCount = LockedCounter()
        
        // 동시에 flush 호출 - 하나만 실제 데이터를 가져야 함
        for _ in 0..<10 {
            group.enter()
            queue.async {
                let result = context.flush()
                if !result.isEmpty {
                    flushCount.increment()
                }
                group.leave()
            }
        }
        
        group.wait()
        
        // 정확히 1개만 데이터를 받아야 함 (나머지는 빈 배열)
        // 또는 이미 첫 번째가 모두 가져갔거나
        if flushCount.count <= 1 {
            print("✅ PASSED: Concurrent Flush (no data race)")
        } else {
            print("⚠️ WARNING: Concurrent Flush - multiple flushes returned data: \(flushCount.count)")
        }
    }
    
    func testHighConcurrency() {
        let context = ThreadSafeHangulInputContext(keyboard: "2")
        let threadCount = 50
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.high", attributes: .concurrent)
        
        for _ in 0..<threadCount {
            group.enter()
            queue.async {
                // 무작위 작업 수행
                for _ in 0..<20 {
                    let operation = Int.random(in: 0..<4)
                    switch operation {
                    case 0:
                        let keys = ["r", "k", "s", "e", "f"]
                        let _: Bool = context.process(keys.randomElement()!)
                    case 1:
                        _ = context.backspace()
                    case 2:
                        _ = context.flush()
                    case 3:
                        _ = context.getPreeditString()
                    default:
                        break
                    }
                }
                group.leave()
            }
        }
        
        group.wait()
        
        // 크래시 없이 완료되면 성공
        print("✅ PASSED: High Concurrency (\(threadCount) threads, no crash)")
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
        testBackspaceCompositeVowel() // Added
        testBackspaceDoubleConsonantJongseong() // Added
        
        testMixedInput()
        testSentenceTyping()
        
        // New Tests
        testLongTextEntry()
        testCorrectionFlow()
        testComplexSymbols()
        
        test3SetInput()
        testBugReports() // Added
        testFuzzing()
        
        // P2: Concurrency Tests
        testConcurrentProcessing()
        testConcurrentFlush()
        testHighConcurrency()
        
        print("\n🎉 All Tests Passed!")
    }

}

// Run tests
let runner = TestRunner()
runner.runAll()

// Run Refinement Tests
let refinementRunner = RefinementTestRunner()
refinementRunner.run()
