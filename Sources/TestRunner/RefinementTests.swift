import Foundation
import LibHangul

class RefinementTestRunner {
    
    func run() {
        print("Running RefinementTestRunner...")
        testDoubleStrokeOption()
        testDelegateCallbacks()
        testFuzzingExtra()
        testThreadSafetyStress()
    }

    /// 입력을 모두 처리한 뒤 커밋 + 남은 조합(flush)을 합친 최종 문자열
    private func fullOutput(_ ctx: HangulInputContext, _ keys: String) -> String {
        var out: [UCSChar] = []
        for ch in keys {
            _ = ctx.process(ch)
            out += ctx.getCommitString()
        }
        out += ctx.flush()
        return String(out.compactMap { UnicodeScalar($0) }.map { Character($0) })
    }

    func testDoubleStrokeOption() {
        print("\n--- Running combinationOnDoubleStroke Tests ---")

        // OFF (기본): 분리 유지
        let off = HangulInputContext(keyboard: "2")
        off.setOption(.combinationOnDoubleStroke, value: false)
        assertEquals(fullOutput(off, "rrk"), "ㄱ가", "double-stroke OFF: rrk -> ㄱ가")

        // ON: 된소리 결합 (ㄷㄷ→ㄸ는 이전 테이블 버그가 있던 부분)
        let cases: [(String, String)] = [
            ("rrk", "까"), ("eek", "따"), ("qqk", "빠"), ("ttk", "싸"), ("wwk", "짜")
        ]
        for (keys, expected) in cases {
            let ctx = HangulInputContext(keyboard: "2")
            ctx.setOption(.combinationOnDoubleStroke, value: true)
            assertEquals(fullOutput(ctx, keys), expected, "double-stroke ON: \(keys) -> \(expected)")
        }

        // ㄴㄴ은 된소리가 없으므로 결합하지 않음
        let nn = HangulInputContext(keyboard: "2")
        nn.setOption(.combinationOnDoubleStroke, value: true)
        assertEquals(fullOutput(nn, "ssk"), "ㄴ나", "double-stroke ON: ssk -> ㄴ나 (no ㄴㄴ tense form)")

        // 일반 입력은 영향 없음
        let normal = HangulInputContext(keyboard: "2")
        normal.setOption(.combinationOnDoubleStroke, value: true)
        assertEquals(fullOutput(normal, "rkr"), "각", "double-stroke ON: rkr -> 각 (normal unaffected)")
    }

    func testDelegateCallbacks() {
        print("\n--- Running Delegate Callback Tests ---")

        final class Spy: HangulInputContextDelegate {
            var processed: [(key: Int, result: Bool)] = []
            var transitions: [UCSChar] = []
            func hangulInputContext(_ c: HangulInputContext, didProcess key: Int, result: Bool) {
                processed.append((key, result))
            }
            func hangulInputContext(_ c: HangulInputContext, didTransition character: UCSChar, preedit: [UCSChar]) {
                transitions.append(character)
            }
        }

        let spy = Spy()
        let ctx = HangulInputContext(keyboard: "2")
        ctx.delegate = spy
        for ch in "rkrk" { _ = ctx.process(ch) }

        assertEquals(spy.processed.count, 4, "delegate didProcess fires for every key (rkrk)")
        assertEquals(spy.processed.map { $0.key }, [114, 107, 114, 107], "delegate didProcess key codes")
        assertEquals(spy.transitions.contains(0xAC00), true, "delegate didTransition for committed 가")

        spy.processed.removeAll()
        _ = ctx.backspace()
        assertEquals(spy.processed.last?.key, 8, "delegate didProcess(8) on backspace")
    }
    
    func testFuzzingExtra() {
        print("\n--- Running Extended Fuzzing Tests (Refinement) ---")
        
        let context = HangulInputContext(keyboard: "2")
        // Extended character set including symbols
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()_+`~[]{}\\|;':\",./<>?"
        
        for i in 0..<5 {
            print("Fuzzing run #\(i+1)")
            var fuzzInput = ""
            for _ in 0..<1000 {
                let randomChar = chars.randomElement()!
                fuzzInput.append(randomChar)
            }
            
            // Validate: Should not crash
            for char in fuzzInput {
                let _ = context.process(char)
            }
            
            _ = context.flush()
            context.reset()
        }
        print("✅ PASSED: Extended Fuzzing completed")
    }
    
    func testThreadSafetyStress() {
         print("\n--- Running Thread Safety Stress Test (High Load) ---")
         
         let context = ThreadSafeHangulInputContext(keyboard: "2")
         let threadCount = 20 
         let opsPerThread = 1000
         let group = DispatchGroup()
         
         for _ in 0..<threadCount {
             group.enter()
             DispatchQueue.global().async {
                 for _ in 0..<opsPerThread {
                      let op = Int.random(in: 0...10)
                      if op < 6 {
                          // Input
                          let char = "rkskekfkabcdefg".randomElement()!
                          let _ = context.process(char)
                      } else if op < 8 {
                          // Backspace
                          let _ = context.backspace()
                      } else if op < 9 {
                          // Flush
                          let _ = context.flush()
                      } else {
                          // Property access
                          let _ = context.getPreeditString()
                      }
                 }
                 group.leave()
             }
         }
         
         let result = group.wait(timeout: .now() + 20)
         if result == .success {
             print("✅ PASSED: Thread Safety Stress Test")
         } else {
             print("❌ FAILED: Thread Safety Stress Test (Timed out)")
             exit(1)
         }
    }
}
