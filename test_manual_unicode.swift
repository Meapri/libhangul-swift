import Foundation

// "안녕하세요"의 NFD 형태
let testText: [UInt32] = [
    0x110B, 0x1161, 0x11AB, // 안
    0x1112, 0x1161, 0x11AD, // 녕
    0x1112, 0x1161,        // 하
    0x1109, 0x116E,        // 세
    0x110B, 0x1173         // 요
]

let characters = testText.compactMap { UnicodeScalar($0) }.map { Character($0) }
let string = String(characters)
let normalized = string.precomposedStringWithCanonicalMapping

print("Original string: \(string)")
print("Original unicode scalars: \(string.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
print("Normalized: \(normalized)")
print("Normalized unicode scalars: \(normalized.unicodeScalars.map { String(format: "0x%04X", $0.value) })")

// 예상되는 결과와 비교
let expected = "안녕하세요"
print("Expected: \(expected)")
print("Expected unicode scalars: \(expected.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
print("Match: \(normalized == expected)")
