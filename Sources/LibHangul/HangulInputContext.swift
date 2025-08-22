//
//  HangulInputContext.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  한글 입력 컨텍스트 - 한글 입력 상태 관리
//

import Foundation

/// 입력 컨텍스트 옵션
public enum HangulInputContextOption: Int {
    case autoReorder = 0              // 자동 재정렬
    case combinationOnDoubleStroke = 1 // 두 번 입력시 결합
    case nonChoseongCombination = 2    // 초성 결합 허용
}

/// 출력 모드
public enum HangulOutputMode: Int {
    case syllable = 0  // 음절 단위 출력
    case jamo = 1      // 자모 단위 출력
}

/// 한글 입력 컨텍스트의 델리게이트 프로토콜
public protocol HangulInputContextDelegate: AnyObject {
    /// 키 입력이 처리될 때 호출
    func hangulInputContext(_ context: HangulInputContext, didProcess key: Int, result: Bool)

    /// 전환 이벤트가 발생할 때 호출
    func hangulInputContext(_ context: HangulInputContext, didTransition character: UCSChar, preedit: [UCSChar])
}

/// 한글 입력 컨텍스트
/// C 코드의 struct _HangulInputContext에 대응
public final class HangulInputContext {

    // MARK: - Properties

    /// 키보드 관리자
    private let keyboardManager: HangulKeyboardManager

    /// 현재 키보드
    public private(set) var keyboard: HangulKeyboard?

    /// 입력 버퍼
    private let buffer: HangulBuffer

    /// 사전 편집 문자열 (조합중인 문자열)
    private var preeditString: [UCSChar] = []

    /// 커밋된 문자열
    private var commitString: [UCSChar] = []

    /// 출력 모드
    public private(set) var outputMode: HangulOutputMode = .syllable

    /// 옵션 설정
    private var options: Set<HangulInputContextOption> = [.autoReorder]

    /// 델리게이트
    public weak var delegate: HangulInputContextDelegate?

    // MARK: - Initialization

    /// 기본 생성자
    public init(keyboard: String = "2") {
        self.keyboardManager = HangulKeyboardManager()
        self.buffer = HangulBuffer()
        setKeyboard(with: keyboard)
    }

    /// 키보드 지정 생성자
    public init(keyboard: HangulKeyboard) {
        self.keyboardManager = HangulKeyboardManager()
        self.buffer = HangulBuffer()
        self.keyboard = keyboard
    }

    // MARK: - Public Methods

    /// 키 입력 처리
    /// - Parameter key: ASCII 키 코드
    /// - Returns: 키가 처리되었으면 true
    public func process(_ key: Int) -> Bool {
        guard let keyboard = keyboard else { return false }

        // 백스페이스 처리
        if key == 8 || key == 0x7F { // Backspace or Delete
            let result = backspace()
            delegate?.hangulInputContext(self, didProcess: key, result: result)
            return result
        }

        // 키 매핑
        let jamo = keyboard.mapKey(key)
        if jamo == 0 {
            // 매핑되지 않은 키는 그대로 통과
            delegate?.hangulInputContext(self, didProcess: key, result: false)
            return false
        }

        // 한글 자모가 아닌 경우 (영어, 숫자, 기호 등)
        if !HangulCharacter.isJamo(jamo) {
            flush()
            commitString.append(jamo)
            delegate?.hangulInputContext(self, didProcess: key, result: true)
            return true
        }

        // 한글 자모 처리
        let result = processJamo(jamo)
        updatePreeditString()
        delegate?.hangulInputContext(self, didProcess: key, result: result)
        return result
    }

    /// 백스페이스 처리
    /// - Returns: 처리되었으면 true
    public func backspace() -> Bool {
        if !buffer.isEmpty {
            let removed = buffer.pop()
            if removed != 0 {
                updatePreeditString()
                return true
            }
        }
        return false
    }

    /// 버퍼 초기화
    public func reset() {
        buffer.clear()
        preeditString.removeAll()
        commitString.removeAll()
    }

    /// 현재 사전 편집 문자열 반환
    /// - Returns: 사전 편집 문자열
    public func getPreeditString() -> [UCSChar] {
        preeditString
    }

    /// 커밋된 문자열 반환 및 초기화
    /// - Returns: 커밋된 문자열
    public func getCommitString() -> [UCSChar] {
        let result = commitString
        commitString.removeAll()
        return result
    }

    /// 모든 내용을 커밋
    /// - Returns: 커밋된 문자열
    public func flush() -> [UCSChar] {
        var result = commitString

        if !buffer.isEmpty {
            if outputMode == .syllable {
                            let syllable = buffer.buildSyllable()
            if syllable != 0 {
                result.append(syllable)
            } else {
                    result.append(contentsOf: buffer.getJamoString())
                }
            } else {
                result.append(contentsOf: buffer.getJamoString())
            }
            buffer.clear()
            preeditString.removeAll()
        }

        commitString = result
        return result
    }

    /// 키보드 설정
    /// - Parameter keyboard: 키보드 식별자
    public func setKeyboard(with identifier: String) {
        keyboard = keyboardManager.keyboard(for: identifier)
    }

    /// 키보드 설정
    /// - Parameter keyboard: 키보드 객체
    public func setKeyboard(_ keyboard: HangulKeyboard) {
        self.keyboard = keyboard
    }

    /// 출력 모드 설정
    /// - Parameter mode: 출력 모드
    public func setOutputMode(_ mode: HangulOutputMode) {
        outputMode = mode
    }

    /// 옵션 설정
    /// - Parameters:
    ///   - option: 옵션
    ///   - value: 설정값
    public func setOption(_ option: HangulInputContextOption, value: Bool) {
        if value {
            options.insert(option)
        } else {
            options.remove(option)
        }
    }

    /// 옵션 확인
    /// - Parameter option: 확인할 옵션
    /// - Returns: 옵션이 설정되어 있으면 true
    public func getOption(_ option: HangulInputContextOption) -> Bool {
        options.contains(option)
    }

    /// 버퍼가 비어있는지 확인
    /// - Returns: 비어있으면 true
    public func isEmpty() -> Bool {
        buffer.isEmpty && commitString.isEmpty
    }

    /// 초성이 있는지 확인
    /// - Returns: 초성이 있으면 true
    public func hasChoseong() -> Bool {
        buffer.choseong != 0
    }

    /// 중성이 있는지 확인
    /// - Returns: 중성이 있으면 true
    public func hasJungseong() -> Bool {
        buffer.jungseong != 0
    }

    /// 종성이 있는지 확인
    /// - Returns: 종성이 있으면 true
    public func hasJongseong() -> Bool {
        buffer.jongseong != 0
    }

    // MARK: - Private Methods

    private func processJamo(_ jamo: UCSChar) -> Bool {
        // 버퍼가 가득 찼는지 확인
        if buffer.getJamoString().count >= 12 {
            flush()
        }

        // 자모를 버퍼에 추가
        let success = buffer.push(jamo)
        if success {
            updatePreeditString()
        }

        return success
    }

    private func updatePreeditString() {
        preeditString = buffer.getJamoString()

        // 음절 모드이고 완성된 음절이 있으면 음절로 변환
        if outputMode == .syllable && !buffer.isEmpty {
            let syllable = buffer.buildSyllable()
            if syllable != 0 {
                preeditString = [syllable]
            }
        }
    }
}

// MARK: - Convenience Extensions

extension HangulInputContext {
    /// 문자열을 한글 입력 컨텍스트에 입력
    /// - Parameter string: 입력할 문자열
    /// - Returns: 처리 결과
    public func process(_ string: String) -> Bool {
        var success = false
        for char in string.unicodeScalars {
            let key = Int(char.value)
            if process(key) {
                success = true
            }
        }
        return success
    }

    /// 현재 상태를 문자열로 반환
    /// - Returns: 현재 상태를 나타내는 문자열
    public func currentStateDescription() -> String {
        var description = ""

        if hasChoseong() {
            description += "초성: \(HangulCharacter.jamoToCJamo(buffer.choseong))\n"
        }
        if hasJungseong() {
            description += "중성: \(HangulCharacter.jamoToCJamo(buffer.jungseong))\n"
        }
        if hasJongseong() {
            description += "종성: \(HangulCharacter.jamoToCJamo(buffer.jongseong))\n"
        }

        if !preeditString.isEmpty {
            let preeditText = preeditString.compactMap { UnicodeScalar($0) }.map { Character($0) }
            description += "조합중: \(preeditText)\n"
        }

        if !commitString.isEmpty {
            let commitText = commitString.compactMap { UnicodeScalar($0) }.map { Character($0) }
            description += "완성됨: \(commitText)\n"
        }

        return description.isEmpty ? "비어있음" : description
    }
}
