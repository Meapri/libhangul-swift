//
//  HangulCharacter.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  한글 자모 관련 타입과 기본 연산을 정의하는 모듈
//

import Foundation

/// 한글 음절의 구성 요소를 나타내는 열거형
public enum HangulSyllableComponent {
    case choseong  // 초성
    case jungseong // 중성
    case jongseong // 종성
}

/// 한글 자모의 결합 가능 여부를 나타내는 열거형
public enum HangulJamoConjoinability {
    case conjoinable     // 결합 가능
    case nonConjoinable  // 결합 불가능
}

/// 한글 음절의 완성도를 나타내는 열거형
public enum HangulSyllableCompleteness {
    case incomplete // 미완성 (자모만 있는 상태)
    case complete   // 완성 (음절 형태)
}

/// UCS-4 코드 단위의 글자 코드 값
/// libhangul의 ucschar 타입에 대응
public typealias UCSChar = UInt32

/// 한글 자모와 관련된 상수들
public enum HangulConstants {
    // 음절 구성 관련
    public static let syllableBase: UCSChar = 0xAC00
    public static let choseongBase: UCSChar = 0x1100
    public static let jungseongBase: UCSChar = 0x1161
    public static let jongseongBase: UCSChar = 0x11A7

    public static let njungseong = 21
    public static let njongseong = 28

    // 필러 문자들
    public static let choseongFiller: UCSChar = 0x115F
    public static let jungseongFiller: UCSChar = 0x1160

    // 유니코드 범위
    public static let choseongRange: ClosedRange<UCSChar> = 0x1100...0x115F
    public static let jungseongRange: ClosedRange<UCSChar> = 0x1160...0x11A7
    public static let jongseongRange: ClosedRange<UCSChar> = 0x11A8...0x11FF
    public static let syllableRange: ClosedRange<UCSChar> = 0xAC00...0xD7A3
    public static let cjamoRange: ClosedRange<UCSChar> = 0x3131...0x318E

    // 확장 영역
    public static let choseongExtARange: ClosedRange<UCSChar> = 0xA960...0xA97C
    public static let jungseongExtBRange: ClosedRange<UCSChar> = 0xD7B0...0xD7C6
    public static let jongseongExtBRange: ClosedRange<UCSChar> = 0xD7CB...0xD7FB
}

/// 한글 음절을 구성하는 자모들을 담는 구조체
public struct HangulJamoCombination {
    public var choseong: UCSChar = 0    // 초성
    public var jungseong: UCSChar = 0   // 중성
    public var jongseong: UCSChar = 0   // 종성

    public init(choseong: UCSChar = 0, jungseong: UCSChar = 0, jongseong: UCSChar = 0) {
        self.choseong = choseong
        self.jungseong = jungseong
        self.jongseong = jongseong
    }

    /// 모든 자모가 비어있는지 확인
    public var isEmpty: Bool {
        choseong == 0 && jungseong == 0 && jongseong == 0
    }

    /// 유효한 조합인지 확인
    public var isValid: Bool {
        (choseong == 0 || HangulCharacter.isChoseong(choseong)) &&
        (jungseong == 0 || HangulCharacter.isJungseong(jungseong)) &&
        (jongseong == 0 || HangulCharacter.isJongseong(jongseong))
    }
}

/// 한글 자모 관련 기능을 제공하는 클래스
public final class HangulCharacter {

    // MARK: - 자모 판별 함수들

    /// 초성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 초성이면 true
    public static func isChoseong(_ c: UCSChar) -> Bool {
        HangulConstants.choseongRange.contains(c) ||
        HangulConstants.choseongExtARange.contains(c)
    }

    /// 중성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 중성이면 true
    public static func isJungseong(_ c: UCSChar) -> Bool {
        HangulConstants.jungseongRange.contains(c) ||
        HangulConstants.jungseongExtBRange.contains(c)
    }

    /// 종성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 종성이면 true
    public static func isJongseong(_ c: UCSChar) -> Bool {
        HangulConstants.jongseongRange.contains(c) ||
        HangulConstants.jongseongExtBRange.contains(c)
    }

    /// 한글 음절인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 한글 음절이면 true
    public static func isSyllable(_ c: UCSChar) -> Bool {
        HangulConstants.syllableRange.contains(c)
    }

    /// 자모인지 확인 (초성, 중성, 종성 중 하나)
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 자모이면 true
    public static func isJamo(_ c: UCSChar) -> Bool {
        isChoseong(c) || isJungseong(c) || isJongseong(c)
    }

    /// 호환 자모인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 호환 자모이면 true
    public static func isCJamo(_ c: UCSChar) -> Bool {
        HangulConstants.cjamoRange.contains(c)
    }

    /// 결합 가능한 초성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 결합 가능하면 true
    public static func isChoseongConjoinable(_ c: UCSChar) -> Bool {
        (0x1100...0x1112).contains(c)
    }

    /// 결합 가능한 중성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 결합 가능하면 true
    public static func isJungseongConjoinable(_ c: UCSChar) -> Bool {
        (0x1161...0x1175).contains(c)
    }

    /// 결합 가능한 종성인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 결합 가능하면 true
    public static func isJongseongConjoinable(_ c: UCSChar) -> Bool {
        (0x11A7...0x11C2).contains(c)
    }

    /// 결합 가능한 자모인지 확인
    /// - Parameter c: 검사할 UCS 코드
    /// - Returns: 결합 가능하면 true
    public static func isJamoConjoinable(_ c: UCSChar) -> Bool {
        isChoseongConjoinable(c) || isJungseongConjoinable(c) || isJongseongConjoinable(c)
    }

    // MARK: - 음절 결합/분해

    /// 자모들을 음절로 결합
    /// - Parameters:
    ///   - choseong: 초성
    ///   - jungseong: 중성
    ///   - jongseong: 종성 (0이면 종성 없음)
    /// - Returns: 결합된 음절 코드, 실패시 0
    public static func jamoToSyllable(choseong: UCSChar, jungseong: UCSChar, jongseong: UCSChar = 0) -> UCSChar {
        // 종성이 0이면 Jongseong filler 사용
        let jong = jongseong == 0 ? HangulConstants.jongseongBase : jongseong

        guard isChoseongConjoinable(choseong),
              isJungseongConjoinable(jungseong),
              isJongseongConjoinable(jong) else {
            return 0
        }

        let c = choseong - HangulConstants.choseongBase
        let j = jungseong - HangulConstants.jungseongBase
        let o = jong - HangulConstants.jongseongBase

        return ((c * UInt32(HangulConstants.njungseong) + j) * UInt32(HangulConstants.njongseong) + o) + HangulConstants.syllableBase
    }

    /// 음절을 자모로 분해
    /// - Parameter syllable: 분해할 음절
    /// - Returns: 분해된 자모 조합
    public static func syllableToJamo(_ syllable: UCSChar) -> HangulJamoCombination {
        guard isSyllable(syllable) else {
            return HangulJamoCombination()
        }

        var result = HangulJamoCombination()
        var s = syllable - HangulConstants.syllableBase

        let jongseongIndex = s % UInt32(HangulConstants.njongseong)
        if jongseongIndex != 0 {
            result.jongseong = HangulConstants.jongseongBase + jongseongIndex
        }

        s /= UInt32(HangulConstants.njongseong)
        result.jungseong = HangulConstants.jungseongBase + (s % UInt32(HangulConstants.njungseong))

        s /= UInt32(HangulConstants.njungseong)
        result.choseong = HangulConstants.choseongBase + s

        return result
    }

    // MARK: - 자모 변환

    /// 자모를 호환 자모로 변환
    /// - Parameter jamo: 변환할 자모
    /// - Returns: 대응되는 호환 자모, 없으면 원본 반환
    public static func jamoToCJamo(_ jamo: UCSChar) -> UCSChar {
        // 자모 변환 테이블 (간략 버전)
        let jamoTable: [UCSChar: UCSChar] = [
            0x1100: 0x3131, 0x1101: 0x3132, 0x1102: 0x3134, 0x1103: 0x3137,
            0x1104: 0x3138, 0x1105: 0x3139, 0x1106: 0x3141, 0x1107: 0x3142,
            0x1108: 0x3143, 0x1109: 0x3145, 0x110A: 0x3146, 0x110B: 0x3147,
            0x110C: 0x3148, 0x110D: 0x3149, 0x110E: 0x314A, 0x110F: 0x314B,
            0x1110: 0x314C, 0x1111: 0x314D, 0x1112: 0x314E,
            0x1160: 0x3164,
            0x1161: 0x314F, 0x1162: 0x3150, 0x1163: 0x3151, 0x1164: 0x3152,
            0x1165: 0x3153, 0x1166: 0x3154, 0x1167: 0x3155, 0x1168: 0x3156,
            0x1169: 0x3157, 0x116A: 0x3158, 0x116B: 0x3159, 0x116C: 0x315A,
            0x116D: 0x315B, 0x116E: 0x315C, 0x116F: 0x315D, 0x1170: 0x315E,
            0x1171: 0x315F, 0x1172: 0x3160, 0x1173: 0x3161, 0x1174: 0x3162,
            0x1175: 0x3163
        ]

        return jamoTable[jamo] ?? jamo
    }
}
