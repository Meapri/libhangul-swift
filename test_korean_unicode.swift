import Foundation

// 실제 한글 음절들의 유니코드 값 확인
let koreanChars = ["가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타", "파", "하"]
let expectedValues: [UInt32] = [0xAC00, 0xB098, 0xB2E4, 0xB77C, 0xB9C8, 0xBC14, 0xC0AC, 0xC544, 0xC790, 0xCC28, 0xCE74, 0xD0C0, 0xD30C, 0xD558]

print("한글 음절 유니코드 값 확인:")
for (char, expected) in zip(koreanChars, expectedValues) {
    let actual = char.unicodeScalars.first!.value
    let match = actual == expected
    print("\(char): 예상=\(String(format: "0x%04X", expected)), 실제=\(String(format: "0x%04X", actual)), 일치=\(match)")
}

// "나"의 자모 분해 확인
let na = "나"
print("\n\"나\" 음절 분석:")
print("유니코드: \(String(format: "0x%04X", na.unicodeScalars.first!.value))")

// NFD 형태로 변환
let naNFD = na.decomposedStringWithCanonicalMapping
print("NFD: \(naNFD)")
for (i, scalar) in naNFD.unicodeScalars.enumerated() {
    let description = switch scalar.value {
        case 0x1102: "초성 ᄂ (ㄷ)"
        case 0x1161: "중성 ᅡ (ㅏ)"
        default: "알 수 없음"
    }
    print("  \(i): \(String(format: "0x%04X", scalar.value)) - \(description)")
}
