//
//  HangulScalar.swift
//  LibHangul
//
//  한글 유니코드 범위 상수 및 헬퍼 메서드
//

import Foundation

/// 한글 유니코드 스칼라 상수 네임스페이스
/// 
/// 매직 넘버를 제거하고 가독성을 높이기 위한 중앙화된 상수 정의
public enum HangulScalar {
    
    // MARK: - 한글 음절 (Hangul Syllables: U+AC00-U+D7A3)
    
    /// 한글 완성형 시작 (가)
    public static let syllableBase: UCSChar = 0xAC00
    /// 한글 완성형 끝 (힣)
    public static let syllableEnd: UCSChar = 0xD7A3
    
    // MARK: - 조합용 자모 (Hangul Jamo: U+1100-U+11FF)
    
    /// 초성 시작
    public static let choseongBase: UCSChar = 0x1100
    /// 초성 끝
    public static let choseongEnd: UCSChar = 0x115F
    /// 중성 시작
    public static let jungseongBase: UCSChar = 0x1161
    /// 중성 끝
    public static let jungseongEnd: UCSChar = 0x11A7
    /// 종성 시작
    public static let jongseongBase: UCSChar = 0x11A8
    /// 종성 끝
    public static let jongseongEnd: UCSChar = 0x11FF
    
    // MARK: - 호환 자모 (Hangul Compatibility Jamo: U+3131-U+318E)
    
    /// 호환 자모 시작 (ㄱ)
    public static let compatJamoBase: UCSChar = 0x3131
    /// 호환 자모 끝 (ㆎ)
    public static let compatJamoEnd: UCSChar = 0x318E
    
    // MARK: - 필러 (Fillers)
    
    /// 초성 필러
    public static let choseongFiller: UCSChar = 0x115F
    /// 중성 필러
    public static let jungseongFiller: UCSChar = 0x1160
    
    // MARK: - 음절 계산 상수
    
    /// 중성 개수
    public static let jungseongCount = 21
    /// 종성 개수 (종성 없음 포함)
    public static let jongseongCount = 28
    
    // MARK: - 범위 검증 메서드
    
    /// 한글 완성형 음절인지 확인
    @inlinable
    public static func isSyllable(_ c: UCSChar) -> Bool {
        c >= syllableBase && c <= syllableEnd
    }
    
    /// 조합용 초성인지 확인
    @inlinable
    public static func isChoseong(_ c: UCSChar) -> Bool {
        c >= choseongBase && c <= choseongEnd
    }
    
    /// 조합용 중성인지 확인
    @inlinable
    public static func isJungseong(_ c: UCSChar) -> Bool {
        c >= jungseongBase && c <= jungseongEnd
    }
    
    /// 조합용 종성인지 확인
    @inlinable
    public static func isJongseong(_ c: UCSChar) -> Bool {
        c >= jongseongBase && c <= jongseongEnd
    }
    
    /// 호환 자모인지 확인
    @inlinable
    public static func isCompatJamo(_ c: UCSChar) -> Bool {
        c >= compatJamoBase && c <= compatJamoEnd
    }
    
    /// 조합용 자모(초/중/종성)인지 확인
    @inlinable
    public static func isComposingJamo(_ c: UCSChar) -> Bool {
        c >= choseongBase && c <= jongseongEnd
    }
    
    /// ASCII 문자인지 확인
    @inlinable
    public static func isASCII(_ c: UCSChar) -> Bool {
        c <= 0x7F
    }
    
    /// NFC 정규화가 필요 없는 문자인지 확인 (이미 정규화된 상태)
    @inlinable
    public static func isAlreadyNormalized(_ c: UCSChar) -> Bool {
        isASCII(c) || isSyllable(c) || isCompatJamo(c)
    }
}
