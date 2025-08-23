import Foundation

let nfdTexts = ["가", "한", "글", "안녕"]

for text in nfdTexts {
    let nfc = text.precomposedStringWithCanonicalMapping
    let nfd = text.decomposedStringWithCanonicalMapping

    print("Original: \(text)")
    print("  Unicode scalars: \(text.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
    print("NFC: \(nfc)")
    print("  Unicode scalars: \(nfc.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
    print("NFD: \(nfd)")
    print("  Unicode scalars: \(nfd.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
    print("Original == NFC: \(text == nfc)")
    print("Original == NFD: \(text == nfd)")
    print("---")
}

// 추가 테스트: 실제 NFD와 NFC가 다른지 확인
let testText = "안녕하세요"
let testNFD = testText.decomposedStringWithCanonicalMapping
let testNFC = testText.precomposedStringWithCanonicalMapping

print("Test with 안녕하세요:")
print("Original: \(testText)")
print("  Unicode scalars: \(testText.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
print("NFD: \(testNFD)")
print("  Unicode scalars: \(testNFD.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
print("NFC: \(testNFC)")
print("  Unicode scalars: \(testNFC.unicodeScalars.map { String(format: "0x%04X", $0.value) })")
print("Original == NFD: \(testText == testNFD)")
print("Original == NFC: \(testText == testNFC)")
print("NFD == NFC: \(testNFD == testNFC)")
