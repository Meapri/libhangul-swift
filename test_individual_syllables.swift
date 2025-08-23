import Foundation

// 각 음절을 개별적으로 테스트
let syllables = [
    ("안", [0x110B, 0x1161, 0x11AB]),  // 초성 ᄋ + 중성 ᅡ + 종성 ᆫ
    ("녕", [0x1112, 0x1161, 0x11AD]),  // 초성 ᄒ + 중성 ᅡ + 종성 ᆭ
    ("하", [0x1112, 0x1161]),          // 초성 ᄒ + 중성 ᅡ
    ("세", [0x1109, 0x116E]),          // 초성 ᄉ + 중성 ᅮ
    ("요", [0x110B, 0x1173])           // 초성 ᄋ + 중성 ᅳ
]

for (expected, nfdData) in syllables {
    let characters = nfdData.compactMap { UnicodeScalar($0) }.map { Character($0) }
    let string = String(characters)
    let normalized = string.precomposedStringWithCanonicalMapping

    print("Expected: \(expected)")
    print("NFD input: \(nfdData.map { String(format: "0x%04X", $0) })")
    print("NFD string: \(string)")
    print("NFC result: \(normalized)")
    print("NFC scalars: \(normalized.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
    print("Match: \(normalized == expected)")
    print("---")
}

// Unicode.org에서 확인된 올바른 한글 유니코드 값들
print("=== Unicode.org 한글 음절 값들 ===")
let correctSyllables = [
    ("가", 0xAC00), ("나", 0xB098), ("다", 0xB2E4), ("라", 0xB77C), ("마", 0xB9C8),
    ("바", 0xBC14), ("사", 0xC0AC), ("아", 0xC544), ("자", 0xC790), ("차", 0xCC28),
    ("카", 0xCE74), ("타", 0xD0C0), ("파", 0xD30C), ("하", 0xD558),
    ("안", 0xC548), ("녕", 0xB155), ("세", 0xC138), ("요", 0xC694)
]

for (syllable, expectedCode) in correctSyllables {
    print("\(syllable): 0x\(String(format: "%04X", expectedCode))")
}
