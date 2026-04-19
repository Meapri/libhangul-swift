//
//  HangulKeyboard.swift
//  LibHangul
//
//  한글 키보드 레이아웃 관리
//

import Foundation

/// 키보드 타입 열거형
public enum HangulKeyboardType: Int, Sendable {
    case jamo = 0      // 자모 단위 입력
    case jaso = 1      // 자소 단위 입력
    case romaja = 2    // 로마자 방식
    case jamoYet = 3   // 옛한글 자모
    case jasoYet = 4   // 옛한글 자소

    /// 키보드 타입 설명
    public var description: String {
        switch self {
        case .jamo:
            return "자모 단위"
        case .jaso:
            return "자소 단위"
        case .romaja:
            return "로마자"
        case .jamoYet:
            return "옛한글 자모"
        case .jasoYet:
            return "옛한글 자소"
        }
    }
}

/// 키보드 레이아웃을 정의하는 기본 클래스
public class HangulKeyboard {
    /// 키보드 식별자
    public let identifier: String
    /// 키보드 이름
    public let name: String
    /// 키보드 타입
    public private(set) var type: HangulKeyboardType

    /// 키 매핑 테이블 (ASCII -> 자모)
    internal var keyMap: [Int: UCSChar] = [:]

    public init(identifier: String, name: String, type: HangulKeyboardType = .jaso) {
        self.identifier = identifier
        self.name = name
        self.type = type
        setupDefaultMappings()
    }

    /// 키 코드를 자모로 변환
    /// - Parameter key: ASCII 키 코드
    /// - Returns: 변환된 자모 코드, 없으면 0
    ///
    /// 대문자에 명시적 매핑이 없으면 소문자 매핑으로 폴백합니다.
    /// 이를 통해 Shift 변환이 없는 키(예: 두벌식에서 Shift+A→ㅁ)가
    /// 별도 매핑 없이도 정상 동작합니다.
    public func mapKey(_ key: Int) -> UCSChar {
        if let mapped = keyMap[key] {
            return mapped
        }
        // 대문자에 매핑이 없으면 소문자로 폴백
        if let scalar = UnicodeScalar(key) {
            let char = Character(scalar)
            if char.isUppercase {
                let lowered = char.lowercased()
                if let lowerChar = lowered.first, let ascii = lowerChar.asciiValue {
                    return keyMap[Int(ascii)] ?? 0
                }
            }
        }
        return 0
    }

    /// 키보드 타입 설정
    /// - Parameter type: 새 키보드 타입
    public func setType(_ type: HangulKeyboardType) {
        self.type = type
    }

    /// 기본 키보드 매핑 설정 (두벌식 기준)
    internal func setupDefaultMappings() {
        // 자음 - 표준 두벌식
        keyMap[Int(Character("r").asciiValue!)] = 0x1100  // ㄱ
        keyMap[Int(Character("R").asciiValue!)] = 0x1101  // ㄲ
        // 's' 키는 초성(ㄷ)으로 매핑 (종성 매핑은 유지)
        keyMap[Int(Character("s").asciiValue!)] = 0x1102  // ㄴ
        keyMap[Int(Character("E").asciiValue!)] = 0x1104  // ㄸ
        keyMap[Int(Character("f").asciiValue!)] = 0x1105  // ㄹ
        keyMap[Int(Character("a").asciiValue!)] = 0x1106  // ㅁ
        keyMap[Int(Character("q").asciiValue!)] = 0x1107  // ㅃ
        keyMap[Int(Character("Q").asciiValue!)] = 0x1108  // ㅄ
        keyMap[Int(Character("t").asciiValue!)] = 0x1109  // ㅅ
        keyMap[Int(Character("T").asciiValue!)] = 0x110A  // ㅆ (Added: Shift+T)
        keyMap[Int(Character("d").asciiValue!)] = 0x110B  // ㅇ
        keyMap[Int(Character("w").asciiValue!)] = 0x110C  // ㅈ
        keyMap[Int(Character("W").asciiValue!)] = 0x110D  // ㅉ
        keyMap[Int(Character("c").asciiValue!)] = 0x110E  // ㅊ
        keyMap[Int(Character("z").asciiValue!)] = 0x110F  // ㅋ
        keyMap[Int(Character("x").asciiValue!)] = 0x1110  // ㅌ
        keyMap[Int(Character("v").asciiValue!)] = 0x1111  // ㅍ
        keyMap[Int(Character("g").asciiValue!)] = 0x1112  // ㅎ
        keyMap[Int(Character("e").asciiValue!)] = 0x1103  // ㄷ (Moved from Vowel section)

        // 모음 - 두벌식 표준 매핑
        keyMap[Int(Character("k").asciiValue!)] = 0x1161  // ㅏ
        keyMap[Int(Character("o").asciiValue!)] = 0x1162  // ㅐ (Corrected from ㅗ)
        keyMap[Int(Character("i").asciiValue!)] = 0x1163  // ㅑ
        keyMap[Int(Character("O").asciiValue!)] = 0x1164  // ㅒ (Shift+ㅐ)
        keyMap[Int(Character("j").asciiValue!)] = 0x1165  // ㅓ
        keyMap[Int(Character("u").asciiValue!)] = 0x1167  // ㅕ (Added)
        keyMap[Int(Character("p").asciiValue!)] = 0x1166  // ㅔ (Corrected from ㅖ)
        keyMap[Int(Character("P").asciiValue!)] = 0x1168  // ㅖ (Shift+ㅔ -> ㅖ)
        
        keyMap[Int(Character("h").asciiValue!)] = 0x1169  // ㅗ
        // keyMap[Int(Character("y").asciiValue!)] = 0x116D  // ㅛ (Correct)
        keyMap[Int(Character("y").asciiValue!)] = 0x116D  // ㅛ
        keyMap[Int(Character("n").asciiValue!)] = 0x116E  // ㅜ
        keyMap[Int(Character("b").asciiValue!)] = 0x1172  // ㅠ
        keyMap[Int(Character("m").asciiValue!)] = 0x1173  // ㅡ
        keyMap[Int(Character("l").asciiValue!)] = 0x1175  // ㅣ

        // 종성 위치
        // 종성 위치 - REMOVED: 2-set uses Choseong codes which are converted to Jongseong by context
        // The previous mappings here were overwriting Choseong mappings (e.g. R, s) and adding non-standard number mappings.
        // We rely on standard Choseong mappings (Lines 72-90) and HangulBuffer's choseongToJongseong conversion.

    }
}

/// 기본 키보드 레이아웃 구현체
public final class HangulKeyboardDefault: HangulKeyboard {
    public override init(identifier: String, name: String, type: HangulKeyboardType = .jaso) {
        super.init(identifier: identifier, name: name, type: type)
        // 추가적인 키 매핑 설정
        setupAdditionalMappings()
    }

    /// 추가적인 키 매핑 설정
    private func setupAdditionalMappings() {
        // 1 키를 종성 ㄴ으로 매핑 (두벌식용) - REMOVED for Standard Compliance
        // keyMap[Int(Character("1").asciiValue!)] = 0x11AB
        // 불필요한 매핑 제거를 하지 않음
    }

    public override func mapKey(_ key: Int) -> UCSChar {
        return keyMap[key] ?? 0
    }
}

/// 세벌식 키보드 구현체
public final class HangulKeyboard3Set: HangulKeyboard {
    public override init(identifier: String, name: String, type: HangulKeyboardType = .jaso) {
        super.init(identifier: identifier, name: name, type: type)
        setup3SetMappings()
    }

    /// 세벌식 390 자판 매핑 설정
    /// 참고: https://ko.wikipedia.org/wiki/세벌식_390_자판
    private func setup3SetMappings() {
        // 세벌식 390 자판 매핑
        // 초성, 중성, 종성이 각각 다른 키에 배치됨

        // 초성 위치 (오른쪽 영역)
        keyMap[Int(Character("k").asciiValue!)] = 0x1100  // ㄱ
        keyMap[Int(Character("K").asciiValue!)] = 0x1101  // ㄲ
        keyMap[Int(Character("h").asciiValue!)] = 0x1102  // ㄴ
        keyMap[Int(Character("u").asciiValue!)] = 0x1103  // ㄷ
        keyMap[Int(Character("U").asciiValue!)] = 0x1104  // ㄸ
        keyMap[Int(Character("y").asciiValue!)] = 0x1105  // ㄹ
        keyMap[Int(Character("i").asciiValue!)] = 0x1106  // ㅁ
        keyMap[Int(Character("n").asciiValue!)] = 0x1107  // ㅂ
        keyMap[Int(Character("N").asciiValue!)] = 0x1108  // ㅃ
        keyMap[Int(Character("j").asciiValue!)] = 0x1109  // ㅅ
        keyMap[Int(Character("J").asciiValue!)] = 0x110A  // ㅆ
        keyMap[Int(Character("l").asciiValue!)] = 0x110B  // ㅇ
        keyMap[Int(Character("o").asciiValue!)] = 0x110C  // ㅈ
        keyMap[Int(Character("O").asciiValue!)] = 0x110D  // ㅉ
        keyMap[Int(Character("0").asciiValue!)] = 0x110E  // ㅊ
        keyMap[Int(Character("'").asciiValue!)] = 0x110F  // ㅋ
        keyMap[Int(Character("p").asciiValue!)] = 0x1110  // ㅌ
        keyMap[Int(Character(";").asciiValue!)] = 0x1111  // ㅍ
        keyMap[Int(Character("m").asciiValue!)] = 0x1112  // ㅎ

        // 중성 위치 (가운데 영역)
        keyMap[Int(Character("f").asciiValue!)] = 0x1161  // ㅏ
        keyMap[Int(Character("F").asciiValue!)] = 0x1162  // ㅐ
        keyMap[Int(Character("r").asciiValue!)] = 0x1163  // ㅑ
        keyMap[Int(Character("R").asciiValue!)] = 0x1164  // ㅒ
        keyMap[Int(Character("6").asciiValue!)] = 0x1165  // ㅓ
        keyMap[Int(Character("T").asciiValue!)] = 0x1166  // ㅔ
        keyMap[Int(Character("c").asciiValue!)] = 0x1167  // ㅕ
        keyMap[Int(Character("e").asciiValue!)] = 0x1168  // ㅖ
        keyMap[Int(Character("v").asciiValue!)] = 0x1169  // ㅗ
        keyMap[Int(Character("4").asciiValue!)] = 0x116D  // ㅛ
        keyMap[Int(Character("b").asciiValue!)] = 0x116E  // ㅜ
        keyMap[Int(Character("5").asciiValue!)] = 0x1172  // ㅠ
        keyMap[Int(Character("g").asciiValue!)] = 0x1173  // ㅡ
        keyMap[Int(Character("t").asciiValue!)] = 0x1175  // ㅣ

        // 종성 위치 (왼쪽 영역)
        keyMap[Int(Character("d").asciiValue!)] = 0x11A8  // ㄱ
        keyMap[Int(Character("D").asciiValue!)] = 0x11A9  // ㄲ
        keyMap[Int(Character("s").asciiValue!)] = 0x11AB  // ㄴ
        keyMap[Int(Character("w").asciiValue!)] = 0x11AE  // ㄷ
        keyMap[Int(Character("3").asciiValue!)] = 0x11AF  // ㄹ
        keyMap[Int(Character("a").asciiValue!)] = 0x11B7  // ㅁ
        keyMap[Int(Character("z").asciiValue!)] = 0x11B8  // ㅂ
        keyMap[Int(Character("x").asciiValue!)] = 0x11BA  // ㅅ
        keyMap[Int(Character("X").asciiValue!)] = 0x11BB  // ㅆ
        keyMap[Int(Character("q").asciiValue!)] = 0x11BC  // ㅇ
        keyMap[Int(Character("2").asciiValue!)] = 0x11BD  // ㅈ
        keyMap[Int(Character("1").asciiValue!)] = 0x11BE  // ㅊ
        keyMap[Int(Character("W").asciiValue!)] = 0x11BF  // ㅋ
        keyMap[Int(Character("S").asciiValue!)] = 0x11C0  // ㅌ
        keyMap[Int(Character("A").asciiValue!)] = 0x11C1  // ㅍ
        keyMap[Int(Character("Z").asciiValue!)] = 0x11C2  // ㅎ
    }

    public override func mapKey(_ key: Int) -> UCSChar {
        return keyMap[key] ?? 0
    }
}

/// 키보드 관리자
public final class HangulKeyboardManager {
    /// 등록된 키보드들
    private var keyboards: [String: HangulKeyboard] = [:]

    /// 기본 키보드들 등록
    public init() {
        registerDefaultKeyboards()
    }

    /// 키보드 등록
    /// - Parameter keyboard: 등록할 키보드
    public func registerKeyboard(_ keyboard: HangulKeyboard) {
        keyboards[keyboard.identifier] = keyboard
    }

    /// 키보드 조회
    /// - Parameter identifier: 키보드 식별자
    /// - Returns: 키보드 객체, 없으면 nil
    public func keyboard(for identifier: String) -> HangulKeyboard? {
        keyboards[identifier]
    }

    /// 등록된 모든 키보드의 식별자 목록
    /// - Returns: 키보드 식별자 배열
    public func keyboardIdentifiers() -> [String] {
        Array(keyboards.keys).sorted()
    }

    /// 등록된 모든 키보드 목록
    /// - Returns: 키보드 객체 배열
    public func allKeyboards() -> [HangulKeyboard] {
        Array(keyboards.values)
    }

    /// 기본 키보드들 등록
    private func registerDefaultKeyboards() {
        // 두벌식 키보드
        let dubeol = HangulKeyboardDefault(
            identifier: "2",
            name: "두벌식",
            type: .jaso
        )
        registerKeyboard(dubeol)

        // 세벌식 키보드
        let sebeol = HangulKeyboard3Set(
            identifier: "3",
            name: "세벌식"
        )
        registerKeyboard(sebeol)

        // 두벌식 옛한글
        let dubeolYet = HangulKeyboardDefault(
            identifier: "2y",
            name: "두벌식 옛한글",
            type: .jasoYet
        )
        registerKeyboard(dubeolYet)

        // 세벌식 옛한글
        let sebeolYet = HangulKeyboard3Set(
            identifier: "3y",
            name: "세벌식 옛한글"
        )
        registerKeyboard(sebeolYet)
    }
}