import Foundation
@testable import LibHangul

print("r ascii:", Int(Character("r").asciiValue!))
print("k ascii:", Int(Character("k").asciiValue!))

// HangulInputContext로 키 매핑 테스트
let inputContext = HangulInputContext(keyboard: "2")

let testKeys = ["r", "k", "s", "f", "a", "q"]

for key in testKeys {
    let keyCode = Int(Character(key).asciiValue!)
    let jamo = inputContext.keyboard?.mapKey(keyCode) ?? 0

    print("Key '\(key)' (\(keyCode)) -> Jamo: 0x\(String(format: "%04X", jamo))")
    print("  isJamo: \(HangulCharacter.isJamo(jamo))")
    print("  isChoseong: \(HangulCharacter.isChoseong(jamo))")
    print("  isJungseong: \(HangulCharacter.isJungseong(jamo))")
    print("  isJongseong: \(HangulCharacter.isJongseong(jamo))")

    let result = inputContext.process(keyCode)
    print("  process result: \(result)")
    print("  commit string: \(inputContext.getCommitString().map { String(format: "0x%04X", $0) })")
    print("---")
}
