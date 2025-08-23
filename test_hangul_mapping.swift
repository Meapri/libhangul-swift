import Foundation

// 한글 초성-종성 매핑 확인
let testMappings = [
    (0x1100, "ㄱ"), (0x1101, "ㄲ"), (0x1102, "ㄷ"), (0x1103, "ㄸ"),
    (0x1104, "ㄹ"), (0x1105, "ㅁ"), (0x1106, "ㅂ"), (0x1107, "ㅃ"),
    (0x1108, "ㅅ"), (0x1109, "ㅆ"), (0x110A, "ㅇ"), (0x110B, "ㅈ"),
    (0x110C, "ㅉ"), (0x110D, "ㅊ"), (0x110E, "ㅋ"), (0x110F, "ㅌ"),
    (0x1110, "ㅍ"), (0x1111, "ㅎ"), (0x1112, "ㅎ")
]

print("초성-종성 매핑 확인:")
for (choseong, name) in testMappings {
    let jongseong = HangulCharacter.choseongToJongseong(choseong)
    print("\(name) (0x\(String(format: "%04X", choseong))) -> 0x\(String(format: "%04X", jongseong))")
}

// Unicode.org에서 알려진 올바른 값들 확인
print("\nUnicode.org 한글 종성 값들:")
let correctJongseong = [
    "ㄱ": 0x11A8, "ㄲ": 0x11A9, "ㄳ": 0x11AA, "ㄴ": 0x11AB, "ㄵ": 0x11AC,
    "ㄶ": 0x11AD, "ㄷ": 0x11AE, "ㄹ": 0x11AF, "ㄺ": 0x11B0, "ㄻ": 0x11B1,
    "ㄼ": 0x11B2, "ㄽ": 0x11B3, "ㄾ": 0x11B4, "ㄿ": 0x11B5, "ㅀ": 0x11B6,
    "ㅁ": 0x11B7, "ㅂ": 0x11B8, "ㅄ": 0x11B9, "ㅅ": 0x11BA, "ㅆ": 0x11BB,
    "ㅇ": 0x11BC, "ㅈ": 0x11BD, "ㅊ": 0x11BE, "ㅋ": 0x11BF, "ㅌ": 0x11C0,
    "ㅍ": 0x11C1, "ㅎ": 0x11C2
]

for (jamo, code) in correctJongseong {
    print("\(jamo): 0x\(String(format: "%04X", code))")
}
