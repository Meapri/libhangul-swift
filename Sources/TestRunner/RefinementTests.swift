import Foundation
import LibHangul

class RefinementTestRunner {
    
    func run() {
        print("Running RefinementTestRunner...")
        testFuzzingExtra()
        testThreadSafetyStress()
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
                if let ascii = char.asciiValue {
                    let _: Bool = context.process(Int(ascii))
                }
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
         
         for t in 0..<threadCount {
             group.enter()
             DispatchQueue.global().async {
                 for _ in 0..<opsPerThread {
                      let op = Int.random(in: 0...10)
                      if op < 6 {
                          // Input
                          let char = "rkskekfkabcdefg".randomElement()!
                          if let ascii = char.asciiValue {
                              let _: Bool = context.process(Int(ascii))
                          }
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
