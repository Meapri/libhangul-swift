import Foundation
import LibHangul

let inputContext = HangulInputContext(keyboard: "2")
let a_key = Int(Character("a").asciiValue!)
print("a key ASCII: \(a_key)")
if let keyboard = inputContext.keyboard {
    let mapped = keyboard.mapKey(a_key)
    print("mapped value: 0x\(String(format: "%04X", mapped))")
    print("isJamo: \(HangulCharacter.isJamo(mapped))")
} else {
    print("no keyboard")
}
