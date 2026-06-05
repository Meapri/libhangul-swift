import Foundation
import LibHangul

class RefinementTestRunner {
    
    func run() {
        print("Running RefinementTestRunner...")
        testDataDrivenLoading()
        testNewKeyboardsAndOldHangul()
        testDoubleStrokeOption()
        testDelegateCallbacks()
        testFuzzingExtra()
        testThreadSafetyStress()
    }

    /// 최종 출력을 "U+XXXX U+XXXX" 형태의 16진수 문자열로 반환
    private func fullOutputHex(_ ctx: HangulInputContext, _ keys: String) -> String {
        var out: [UCSChar] = []
        for ch in keys {
            _ = ctx.process(ch)
            out += ctx.getCommitString()
        }
        out += ctx.flush()
        return out.map { String(format: "U+%04X", $0) }.joined(separator: " ")
    }

    func testNewKeyboardsAndOldHangul() {
        print("\n--- Running New Keyboards & Old-Hangul Tests ---")

        // 세벌식 390 (39): 현대 한글 조합 (j=ㅇ, f=ㅏ, s=ㄴ → 안)
        assertEquals(fullOutput(HangulInputContext(keyboard: "39"), "jfs"), "안",
                     "세벌식390(39): jfs -> 안")

        // 세벌식 최종 (3f) 도 로드되어 사용 가능해야 함
        assertEquals(HangulInputContext(keyboard: "3f").keyboard?.identifier, "3f",
                     "세벌식 최종(3f) 등록 확인")

        // 두벌식 옛한글 (2y): 초성 클러스터 ㄱ+ㄷ → ᄓ(U+115A)
        assertEquals(fullOutputHex(HangulInputContext(keyboard: "2y"), "re"), "U+115A",
                     "2y: ㄱ+ㄷ -> ᄓ 초성 클러스터")

        // 두벌식 옛한글: 아래아 음절 ㄱ+ㆍ → 조합용 자모 U+1100 U+119E
        assertEquals(fullOutputHex(HangulInputContext(keyboard: "2y"), "rK"), "U+1100 U+119E",
                     "2y: ㄱ+ㆍ(아래아) 조합용 자모 출력")

        // 세벌식 옛한글 (3y): 현대 음절 (k=ㄱ, f=ㅏ, s=ㄴ → 간)
        assertEquals(fullOutput(HangulInputContext(keyboard: "3y"), "kfs"), "간",
                     "3y: kfs -> 간 (현대 음절)")

        // 세벌식 옛한글: 아래아 음절 ㄱ+ㆍ
        assertEquals(fullOutputHex(HangulInputContext(keyboard: "3y"), "kG"), "U+1100 U+119E",
                     "3y: ㄱ+ㆍ 조합용 자모")

        // 현대 자판(39)에서는 옛한글 클러스터가 생기지 않아야 함 (default 테이블에 규칙 없음)
        // r→ㄹ? 39에서는 다른 매핑이므로, 클러스터 미발생만 확인: 같은 입력이 음절로 합쳐지지 않음
        print("✅ PASSED: New keyboards & old-hangul composition")
    }

    func testDataDrivenLoading() {
        print("\n--- Running Data-Driven Keyboard Loading Tests ---")

        // 번들에서 자판 로드
        for file in HangulResourceLoader.bundledKeyboardFiles {
            if let kb = HangulResourceLoader.loadKeyboard(file: file) {
                let comboCount = kb.combination?.count ?? 0
                print("  ✅ \(file) -> id=\(kb.identifier) type=\(kb.type) combo=\(comboCount)")
            } else {
                print("  ❌ \(file) -> load FAILED")
                exit(1)
            }
        }

        // 조합 규칙 파싱 검증
        if let full = HangulResourceLoader.loadKeyboard(file: "hangul-keyboard-2y.xml")?.combination {
            // ㄱ(0x1100) + ㄷ(0x1103) -> ᄓ? (full 테이블에는 0x1100+0x1103 -> 0x115a)
            assertEquals(full.combine(0x1100, 0x1103), 0x115a, "full combo: ㄱ+ㄷ -> 0x115a")
            assertEquals(full.combine(0x1100, 0x1100), 0x1101, "full combo: ㄱ+ㄱ -> ㄲ")
        } else {
            print("  ❌ 2y combination missing"); exit(1)
        }

        // default 테이블에는 ㄱ+ㄷ 규칙이 없어야 함
        if let def = HangulResourceLoader.loadKeyboard(file: "hangul-keyboard-39.xml")?.combination {
            assertEquals(def.combine(0x1100, 0x1103) == nil, true, "default combo: ㄱ+ㄷ 없음")
            assertEquals(def.combine(0x11A8, 0x11BA), 0x11AA, "default combo: ㄱ받침+ㅅ받침 -> ㄳ")
        } else {
            print("  ❌ 39 combination missing"); exit(1)
        }

        print("✅ PASSED: Data-driven keyboard loading")
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
