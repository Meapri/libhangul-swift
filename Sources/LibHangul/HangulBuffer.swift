//
//  HangulBuffer.swift
//  LibHangul
//
//  한글 입력 버퍼 관리
//

import Foundation

/// 한글 입력 버퍼의 상태를 관리하는 클래스
/// C 코드의 struct _HangulBuffer에 대응
///
/// ## 스레드 안전성
/// 이 클래스는 내부 구현용이며, 스레드 안전하지 않습니다.
/// 외부에서 직접 사용하지 마세요. `HangulInputContext` 또는
/// `ThreadSafeHangulInputContext`를 통해 접근하세요.
internal final class HangulBuffer {
    /// 초성
    internal private(set) var choseong: UCSChar = 0

    /// 중성
    internal private(set) var jungseong: UCSChar = 0

    /// 종성
    internal private(set) var jongseong: UCSChar = 0
    
    /// 종성이 결합되어 확장되었는지 여부 (ㄱ+ㄱ=ㄲ 등)
    /// 음절 분리 시 확장된 종성은 분해되고, 원래 단일 입력은 전체 이동
    internal private(set) var jongseongWasExtended: Bool = false

    /// 같은 초성을 연속으로 입력했을 때 된소리(쌍자음)로 결합할지 여부
    /// (예: ㄱ+ㄱ→ㄲ). `HangulInputContextOption.combinationOnDoubleStroke`에 의해 제어된다.
    /// 기본값은 false로, Shift 조합으로 쌍자음을 입력하는 표준 두벌식 동작을 유지한다.
    internal var combineOnDoubleStroke: Bool = false

    private let maxStackSize: Int

    /// 최대 스택 크기
    internal var maxStackSizeValue: Int {
        maxStackSize
    }

    internal init(maxStackSize: Int = 12) {
        self.maxStackSize = maxStackSize
    }

    /// 버퍼가 비어있는지 확인
    internal var isEmpty: Bool {
        choseong == 0 && jungseong == 0 && jongseong == 0
    }

    /// 버퍼를 초기화
    internal func clear() {
        choseong = 0
        jungseong = 0
        jongseong = 0
        jongseongWasExtended = false
    }
    
    /// 종성을 직접 설정 (음절 분리 로직용)
    /// - Parameter value: 설정할 종성 값 (0이면 종성 제거)
    /// - Parameter wasExtended: 종성이 결합으로 확장되었는지 여부
    internal func setJongseong(_ value: UCSChar, wasExtended: Bool = false) {
        jongseong = value
        jongseongWasExtended = wasExtended
    }

    /// 모아치기용: 중성만 먼저 들어온 상태에서 뒤늦게 초성이 입력되면 같은 음절로 재정렬
    /// 예: ㅏ + ㄱ -> 가
    internal func reorderLeadingJungseong(with choseong: UCSChar) -> Bool {
        guard self.choseong == 0,
              jungseong != 0,
              jongseong == 0,
              HangulCharacter.isChoseongConjoinable(choseong),
              HangulCharacter.isJungseongConjoinable(jungseong) else {
            return false
        }

        self.choseong = choseong
        return true
    }

    /// 자모를 버퍼에 추가
    /// - Parameter jamo: 추가할 자모
    /// - Returns: 성공 여부
    internal func push(_ jamo: UCSChar) -> Bool {
        guard HangulCharacter.isJamo(jamo) else { return false }

        if HangulCharacter.isChoseong(jamo) {
            return pushChoseong(jamo)
        } else if HangulCharacter.isJungseong(jamo) {
            return pushJungseong(jamo)
        } else if HangulCharacter.isJongseong(jamo) {
            return pushJongseong(jamo)
        }

        return false
    }

    /// 마지막 자모를 제거하고 반환
    /// - Returns: 제거된 자모, 없으면 0
    internal func pop(fineGrained: Bool = true) -> UCSChar {
        // 스택 제거됨, 오직 현재 음절 내에서만 pop

        if jongseong != 0 {
            // 복합 종성 분해 시도
            if fineGrained {
                let (first, second) = HangulCharacter.decomposeJongseong(jongseong)
                if second != 0 {
                    jongseong = first
                    return second
                }
            }
            
            let result = jongseong
            jongseong = 0
            jongseongWasExtended = false
            return result
        } else if jungseong != 0 {
            // 복합 중성 분해 시도
            if fineGrained {
                let (first, second) = HangulCharacter.decomposeJungseong(jungseong)
                if second != 0 {
                    jungseong = first
                    return second
                }
            }

            let result = jungseong
            jungseong = 0
            return result
        } else if choseong != 0 {
            let result = choseong
            choseong = 0
            return result
        }

        return 0
    }

    /// 버퍼의 내용을 음절로 변환
    /// - Returns: 변환된 음절, 실패시 0
    internal func buildSyllable() -> UCSChar {
        guard choseong != 0 || jungseong != 0 || jongseong != 0 else { return 0 }

        return HangulCharacter.jamoToSyllable(
            choseong: choseong,
            jungseong: jungseong,
            jongseong: jongseong
        )
    }

    /// 버퍼의 내용을 자모 배열로 반환
    /// - Returns: 자모 배열
    internal func getJamoString() -> [UCSChar] {
        var result: [UCSChar] = []

        if choseong != 0 {
            result.append(choseong)
        }
        if jungseong != 0 {
            result.append(jungseong)
        }
        if jongseong != 0 {
            result.append(jongseong)
        }

        return result
    }

    // MARK: - Private Methods

    private func pushChoseong(_ jamo: UCSChar) -> Bool {
        if choseong == 0 {
            guard jungseong == 0 && jongseong == 0 else { return false }
            choseong = jamo
            return true
        } else if jungseong == 0 {
            // 초성이 있고 중성이 없는 상태에서 또 초성이 들어온 경우.
            // 기본 동작: 결합하지 않고 새 음절 시작 (ㄱ + ㄱ = ㄱㄱ, not ㄲ).
            // combineOnDoubleStroke가 켜져 있으면 같은 자음 반복 입력을 된소리로 결합한다
            // (ㄱ+ㄱ→ㄲ, ㄷ+ㄷ→ㄸ, ㅂ+ㅂ→ㅃ, ㅅ+ㅅ→ㅆ, ㅈ+ㅈ→ㅉ).
            if combineOnDoubleStroke, let combined = combineChoseong(choseong, jamo) {
                choseong = combined
                return true
            }
            return false
        } else if jongseong == 0 {
            // 초성, 중성이 있고 종성이 없으면 종성으로 변환 후 추가
            let jong = HangulCharacter.choseongToJongseong(jamo)
            if jong != 0 {
                jongseong = jong
                return true
            }
        } else {
            // 종성이 있는 경우: 복합 종성 결합 시도 (초성 코드로 들어온 입력을 종성으로 변환하여 결합 시도)
            let jong = HangulCharacter.choseongToJongseong(jamo)
            if jong != 0 {
                return pushJongseong(jong)
            }
        }

        return false
    }

    private func pushJungseong(_ jamo: UCSChar) -> Bool {
        if jungseong == 0 {
            jungseong = jamo
            return true
        } else {
            // 중성이 있으면 결합 시도
            if let combined = combineJungseong(jungseong, jamo) {
                jungseong = combined
                return true
            }
        }

        return false
    }

    private func pushJongseong(_ jamo: UCSChar) -> Bool {
        if jongseong == 0 {
            jongseong = jamo
            jongseongWasExtended = false  // 새 종성은 확장되지 않음
            return true
        } else {
            // 종성이 있으면 결합 시도
            if let combined = combineJongseong(jongseong, jamo) {
                jongseong = combined
                jongseongWasExtended = true  // 결합되어 확장됨
                return true
            }
        }

        return false
    }

    // MARK: - Optimization Tables (Static)
    
    private static let choseongCombinations: [UCSChar: [UCSChar: UCSChar]] = [
        0x1100: [0x1100: 0x1101], // ㄱ + ㄱ = ㄲ
        0x1103: [0x1103: 0x1104], // ㄷ + ㄷ = ㄸ
        0x1107: [0x1107: 0x1108], // ㅂ + ㅂ = ㅃ
        0x1109: [0x1109: 0x110A], // ㅅ + ㅅ = ㅆ
        0x110C: [0x110C: 0x110D]  // ㅈ + ㅈ = ㅉ
    ]

    private static let jungseongCombinations: [UCSChar: [UCSChar: UCSChar]] = [
        0x1169: [
            0x1161: 0x116A, 0x1162: 0x116B, 0x1175: 0x116C
        ],
        0x116E: [
            0x1165: 0x116F, 0x1166: 0x1170, 0x1175: 0x1171
        ],
        0x1173: [0x1175: 0x1174],
        0x1161: [0x1175: 0x1162],
        0x1163: [0x1175: 0x1164],
        0x1165: [0x1175: 0x1166],
        0x1167: [0x1175: 0x1168]
    ]
    
    private static let jongseongCombinations: [UCSChar: [UCSChar: UCSChar]] = [
        // ㄱ (0x11A8) -> ㄲ, ㄳ
        0x11A8: [
            0x11A8: 0x11A9, // ㄱ + ㄱ = ㄲ
            0x11BA: 0x11AA  // ㄱ + ㅅ = ㄳ
        ],
        // ㄴ (0x11AB) -> ㄵ, ㄶ
        0x11AB: [
            0x11BD: 0x11AC, // ㄴ + ㅈ = ㄵ
            0x11C2: 0x11AD  // ㄴ + ㅎ = ㄶ
        ],
        // ㄹ (0x11AF) -> ㄺ, ㄻ, ㄼ, ㄽ, ㄾ, ㄿ, ㅀ
        0x11AF: [
            0x11A8: 0x11B0, // ㄹ + ㄱ = ㄺ
            0x11B7: 0x11B1, // ㄹ + ㅁ = ㄻ
            0x11B8: 0x11B2, // ㄹ + ㅂ = ㄼ
            0x11BA: 0x11B3, // ㄹ + ㅅ = ㄽ
            0x11C0: 0x11B4, // ㄹ + ㅌ = ㄾ
            0x11C1: 0x11B5, // ㄹ + ㅍ = ㄿ
            0x11C2: 0x11B6  // ㄹ + ㅎ = ㅀ
        ],
        // ㅂ (0x11B8) -> ㅄ
        0x11B8: [
            0x11BA: 0x11B9  // ㅂ + ㅅ = ㅄ
        ],
         // ㅅ (0x11BA) -> ㅆ
        0x11BA: [
            0x11BA: 0x11BB  // ㅅ + ㅅ = ㅆ
        ]
    ]

    private func combineChoseong(_ a: UCSChar, _ b: UCSChar) -> UCSChar? {
        return Self.choseongCombinations[a]?[b]
    }

    private func combineJungseong(_ a: UCSChar, _ b: UCSChar) -> UCSChar? {
        return Self.jungseongCombinations[a]?[b]
    }

    private func combineJongseong(_ a: UCSChar, _ b: UCSChar) -> UCSChar? {
        return Self.jongseongCombinations[a]?[b]
    }
}
