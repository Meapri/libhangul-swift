//
//  LibHangul.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  libhangul Swift 라이브러리의 메인 모듈
//

import Foundation

// MARK: - Public API

/// libhangul Swift 라이브러리
public enum LibHangul {

    /// 라이브러리 버전
    public static let version = "1.0.0"

    /// 새로운 한글 입력 컨텍스트 생성
    /// - Parameter keyboard: 키보드 식별자 (기본값: "2" - 두벌식)
    /// - Returns: HangulInputContext 인스턴스
    public static func createInputContext(keyboard: String = "2") -> HangulInputContext {
        HangulInputContext(keyboard: keyboard)
    }

    /// 새로운 한글 입력 컨텍스트 생성 (키보드 객체 지정)
    /// - Parameter keyboard: 키보드 객체
    /// - Returns: HangulInputContext 인스턴스
    public static func createInputContext(keyboard: HangulKeyboard) -> HangulInputContext {
        HangulInputContext(keyboard: keyboard)
    }

    /// 사용 가능한 키보드 목록 반환
    /// - Returns: 키보드 정보 배열
    public static func availableKeyboards() -> [(id: String, name: String, type: HangulKeyboardType)] {
        let manager = HangulKeyboardManager()
        return manager.allKeyboards().map { keyboard in
            (id: keyboard.identifier, name: keyboard.name, type: keyboard.type)
        }
    }

    /// 키보드 생성
    /// - Parameters:
    ///   - identifier: 키보드 식별자
    ///   - name: 키보드 이름
    ///   - type: 키보드 타입
    /// - Returns: 키보드 인스턴스
    public static func createKeyboard(identifier: String, name: String, type: HangulKeyboardType) -> HangulKeyboard {
        HangulKeyboardDefault(identifier: identifier, name: name, type: type)
    }

    /// 기본 한자 사전 로드
    /// - Parameter filename: 사전 파일 경로 (nil이면 기본 사전)
    /// - Returns: 한자 사전 테이블
    public static func loadHanjaTable(filename: String? = nil) -> HanjaTable? {
        let table = HanjaTable()
        return table.load(filename: filename) ? table : nil
    }

    /// 한자 검색 (정확 매칭)
    /// - Parameters:
    ///   - table: 한자 사전 테이블
    ///   - key: 검색 키
    /// - Returns: 검색 결과
    public static func searchHanja(table: HanjaTable, key: String) -> HanjaList? {
        table.matchExact(key: key)
    }

    /// 한자 검색 (접두사 매칭)
    /// - Parameters:
    ///   - table: 한자 사전 테이블
    ///   - key: 검색 키
    /// - Returns: 검색 결과
    public static func searchHanjaPrefix(table: HanjaTable, key: String) -> HanjaList? {
        table.matchPrefix(key: key)
    }

    /// 한자 검색 (접미사 매칭)
    /// - Parameters:
    ///   - table: 한자 사전 테이블
    ///   - key: 검색 키
    /// - Returns: 검색 결과
    public static func searchHanjaSuffix(table: HanjaTable, key: String) -> HanjaList? {
        table.matchSuffix(key: key)
    }

    /// 한자 호환성 변환
    /// - Parameters:
    ///   - hanja: 변환할 한자 문자열
    ///   - hangul: 대응되는 한글 문자열
    /// - Returns: 변환된 한자 수
    public static func convertHanjaToCompatibility(hanja: inout [UCSChar], hangul: [UCSChar]) -> Int {
        HanjaCompatibility.toCompatibilityForm(hanja: &hanja, hangul: hangul)
    }

    /// 한자 통합 형태 변환
    /// - Parameter str: 변환할 문자열
    /// - Returns: 변환된 문자 수
    public static func convertHanjaToUnified(_ str: inout [UCSChar]) -> Int {
        HanjaCompatibility.toUnifiedForm(&str)
    }

    /// 문자열이 한글 음절인지 확인
    /// - Parameter string: 확인할 문자열
    /// - Returns: 한글 음절이면 true
    public static func isHangulSyllable(_ string: String) -> Bool {
        guard string.unicodeScalars.count == 1 else { return false }
        let scalar = string.unicodeScalars.first!
        return HangulCharacter.isSyllable(UCSChar(scalar.value))
    }

    /// 문자열을 자모로 분해
    /// - Parameter string: 분해할 문자열
    /// - Returns: 자모 배열
    public static func decomposeHangul(_ string: String) -> [String] {
        string.unicodeScalars.compactMap { scalar in
            let jamo = HangulCharacter.syllableToJamo(UCSChar(scalar.value))
            guard jamo.isValid else { return nil }

            var result: [String] = []

            if jamo.choseong != 0 {
                if let scalar = UnicodeScalar(jamo.choseong) {
                    result.append(String(scalar))
                }
            }
            if jamo.jungseong != 0 {
                if let scalar = UnicodeScalar(jamo.jungseong) {
                    result.append(String(scalar))
                }
            }
            if jamo.jongseong != 0 {
                if let scalar = UnicodeScalar(jamo.jongseong) {
                    result.append(String(scalar))
                }
            }

            return result.joined()
        }
    }

    /// 자모를 음절로 결합
    /// - Parameters:
    ///   - choseong: 초성
    ///   - jungseong: 중성
    ///   - jongseong: 종성 (옵션)
    /// - Returns: 결합된 음절, 실패시 nil
    public static func composeHangul(choseong: String, jungseong: String, jongseong: String? = nil) -> String? {
        guard let cho = choseong.unicodeScalars.first,
              let jung = jungseong.unicodeScalars.first else {
            return nil
        }

        let jong: UCSChar? = jongseong?.unicodeScalars.first.map { UCSChar($0.value) }

        let syllable = HangulCharacter.jamoToSyllable(
            choseong: UCSChar(cho.value),
            jungseong: UCSChar(jung.value),
            jongseong: jong ?? 0
        )

        guard syllable != 0, let scalar = UnicodeScalar(syllable) else {
            return nil
        }

        return String(scalar)
    }
}

// MARK: - Convenience Extensions

extension String {
    /// 문자열이 한글 음절인지 확인
    public var isHangulSyllable: Bool {
        LibHangul.isHangulSyllable(self)
    }

    /// 문자열을 자모로 분해
    public var decomposedHangul: [String] {
        LibHangul.decomposeHangul(self)
    }
}

extension HangulInputContext {
    /// 간편한 키 입력 처리 (문자열)
    /// - Parameter text: 입력할 텍스트
    /// - Returns: 처리된 결과 문자열
    public func processText(_ text: String) -> String {
        var result = ""

        for char in text {
            let key = Int(char.asciiValue ?? 0)
            if process(key) {
                let commit = getCommitString()
                if !commit.isEmpty {
                    let commitText = commit.compactMap { UnicodeScalar($0) }.map { Character($0) }
                    result += commitText
                }
            }
        }

        // 남은 조합중인 문자열 처리
        let remaining = flush()
        if !remaining.isEmpty {
            let remainingText = remaining.compactMap { UnicodeScalar($0) }.map { Character($0) }
            result += remainingText
        }

        return result
    }
}
