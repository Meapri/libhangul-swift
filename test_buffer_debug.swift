import Foundation

// HangulBuffer의 기본적인 동작을 테스트
let buffer = HangulBuffer(maxStackSize: 10)

print("Initial buffer state:")
print("choseong: \(buffer.choseong)")
print("jungseong: \(buffer.jungseong)")
print("jongseong: \(buffer.jongseong)")

print("\nPushing choseong 0x1100 (ㄱ)...")
let result1 = buffer.push(0x1100)
print("Push result: \(result1)")
print("Buffer state after push:")
print("choseong: \(buffer.choseong)")
print("jungseong: \(buffer.jungseong)")
print("jongseong: \(buffer.jongseong)")

print("\nPushing jungseong 0x1161 (ㅏ)...")
let result2 = buffer.push(0x1161)
print("Push result: \(result2)")
print("Buffer state after push:")
print("choseong: \(buffer.choseong)")
print("jungseong: \(buffer.jungseong)")
print("jongseong: \(buffer.jongseong)")

print("\nGetting jamo string:")
let jamoString = buffer.getJamoString()
print("Jamo string: \(jamoString)")
print("Jamo string count: \(jamoString.count)")
