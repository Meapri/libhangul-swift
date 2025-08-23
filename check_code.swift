let code: UInt32 = 0xb140
if let scalar = UnicodeScalar(code) {
    print("0xb140: '\(String(scalar))'")
} else {
    print("0xb140: invalid")
}

// "녀"의 실제 코드 확인
let nyeo = "녀"
for scalar in nyeo.unicodeScalars {
    print("녀: 0x\(String(scalar.value, radix: 16))")
}

// "녕"의 실제 코드 확인
let nyeong = "녕"
for scalar in nyeong.unicodeScalars {
    print("녕: 0x\(String(scalar.value, radix: 16))")
}