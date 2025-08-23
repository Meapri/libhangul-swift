//
//  HangulInputContext.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  한글 입력 컨텍스트 - 한글 입력 상태 관리
//

import Foundation

/// 한글 입력 오류 타입
enum HangulInputError: Error {
    case bufferOverflow
    case invalidJamo(UCSChar)
    case inconsistentBufferState
    case unicodeNormalizationFailed
}

/// 입력 컨텍스트 옵션
public enum HangulInputContextOption: Int {
    case autoReorder = 0              // 자동 재정렬
    case combinationOnDoubleStroke = 1 // 두 번 입력시 결합
    case nonChoseongCombination = 2    // 초성 결합 허용
}

/// 출력 모드
public enum HangulOutputMode: Int, Sendable {
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

    /// 라이브러리 설정
    public private(set) var configuration: HangulInputConfiguration

    /// 최대 버퍼 크기 (설정에서 가져옴)
    public var maxBufferSize: Int {
        get { configuration.maxBufferSize }
        set { configuration.maxBufferSize = newValue }
    }

    /// NFC 정규화 강제 사용
    public var forceNFCNormalization: Bool {
        get { configuration.forceNFCNormalization }
        set { configuration.forceNFCNormalization = newValue }
    }

    /// 관용 입력 모드 활성화 여부 (초성 ㄷ → 종성 ㄴ 자동 변환)
    public var enableIdiomaticInput: Bool = true

    /// 버퍼 상태 모니터링 활성화
    public var enableBufferMonitoring: Bool {
        get { configuration.enableBufferMonitoring }
        set { configuration.enableBufferMonitoring = newValue }
    }

    /// 자동 오류 복구
    public var autoErrorRecovery: Bool {
        get { configuration.autoErrorRecovery }
        set { configuration.autoErrorRecovery = newValue }
    }

    /// 파일명 호환성 모드
    public var filenameCompatibilityMode: Bool {
        get { configuration.filenameCompatibilityMode }
        set { configuration.filenameCompatibilityMode = newValue }
    }

    /// 델리게이트
    public weak var delegate: HangulInputContextDelegate?

    // MARK: - Initialization

    /// 기본 생성자
    public init(keyboard: String? = nil, configuration: HangulInputConfiguration = .default) {
        self.configuration = configuration
        self.keyboardManager = HangulKeyboardManager()
        self.buffer = HangulBuffer(maxStackSize: configuration.maxBufferSize)
        let keyboardId = keyboard ?? configuration.defaultKeyboard
        setKeyboard(with: keyboardId)
        setOutputMode(configuration.outputMode)
    }

    /// 키보드 지정 생성자
    public init(keyboard: HangulKeyboard, configuration: HangulInputConfiguration = .default) {
        self.configuration = configuration
        self.keyboardManager = HangulKeyboardManager()
        self.buffer = HangulBuffer(maxStackSize: configuration.maxBufferSize)
        self.keyboard = keyboard
        setOutputMode(configuration.outputMode)
    }

    /// 설정으로만 초기화
    public init(configuration: HangulInputConfiguration = .default) {
        self.configuration = configuration
        self.keyboardManager = HangulKeyboardManager()
        self.buffer = HangulBuffer(maxStackSize: configuration.maxBufferSize)
        setKeyboard(with: configuration.defaultKeyboard)
        setOutputMode(configuration.outputMode)
    }

    // MARK: - Public Methods

    /// 키 입력 처리
    /// - Parameter key: ASCII 키 코드
    /// - Returns: 키가 처리되었으면 true
    public func process(_ key: Int) -> Bool {
        do {
            guard let keyboard = keyboard else { return false }

            // 키 코드 유효성 검증 (음수 방지)
            guard key >= 0 && key <= 0x10FFFF else {
                delegate?.hangulInputContext(self, didProcess: key, result: false)
                return false
            }

            // 키 매핑
            let jamo = keyboard.mapKey(key)

            // 백스페이스 처리
            if key == 8 || key == 0x7F { // Backspace or Delete
                let result = backspace()
                delegate?.hangulInputContext(self, didProcess: key, result: result)
                return result
            }
            if jamo == 0 {
                // NULL 문자는 유효하지 않은 입력으로 처리
                if key == 0 {
                    delegate?.hangulInputContext(self, didProcess: key, result: false)
                    return false
                }

                // 매핑되지 않은 키는 영어/기호로 처리하여 바로 커밋
                // 이전 내용이 있다면 flush (영어 입력 시에는 보통 비어있음)
                if !buffer.isEmpty {
                    let _ = safeFlush() // 안전하게 이전 내용 flush 처리
                }
                let charValue = UCSChar(key)
                commitString.append(charValue)
                delegate?.hangulInputContext(self, didProcess: key, result: true)
                return true
            }

            // 한글 자모가 아닌 경우 (영어, 숫자, 기호 등) - 하지만 이 케이스는 jamo == 0에서 처리됨
            if !HangulCharacter.isJamo(jamo) {
                let _ = safeFlush() // 안전하게 이전 내용 flush 처리
                commitString.append(jamo)
                delegate?.hangulInputContext(self, didProcess: key, result: true)
                return true
            }

            // 한글 자모 처리
            let result = try processJamoWithValidation(jamo)
            updatePreeditString()
            delegate?.hangulInputContext(self, didProcess: key, result: result)
            return result

        } catch {
            // 입력 처리 오류 발생 시 복구
            recoverFromError()
            delegate?.hangulInputContext(self, didProcess: key, result: false)
            return false
        }
    }

    /// 검증을 포함한 자모 처리
    private func processJamoWithValidation(_ jamo: UCSChar) throws -> Bool {
        // 입력 자모 유효성 검증
        guard validateJamo(jamo) else {
            throw HangulInputError.invalidJamo(jamo)
        }

        // 버퍼가 가득 찼는지 확인
        if buffer.getJamoString().count >= maxBufferSize {
            let _ = safeFlush() // 안전하게 flush
        }

        // 입력 전 버퍼 상태 저장 (완성된 음절 감지용)
        let beforePush = buffer.buildSyllable()

        // 관용 입력 모드: 초성 ㄷ → 종성 ㄴ 자동 변환
        var processedJamo = jamo
        if enableIdiomaticInput && HangulCharacter.isChoseong(jamo) && jamo == 0x1102 { // ㄷ
            // 이전 입력이 초성이고 현재가 ㄷ인 경우, 종성 ㄴ으로 변환 고려
            if !buffer.isEmpty && buffer.choseong != 0 && buffer.jungseong == 0 {
                processedJamo = 0x11AB // 종성 ㄴ
            }
        }

        // 추가: 초성 매핑을 종성으로 변환 (특정 키에 대한)
        if jamo == 0x1102 && !buffer.isEmpty && buffer.choseong != 0 && buffer.jungseong != 0 {
            // 초성 ㄷ이 입력되었고, 이미 초성과 중성이 있는 경우 종성 ㄴ으로 변환
            processedJamo = 0x11AB // 종성 ㄴ
        }

        // 자모를 버퍼에 추가
        let success = buffer.push(processedJamo)
        if success {
            updatePreeditString()

            // 완성된 음절이 있는지 확인하고 커밋
            let afterPush = buffer.buildSyllable()
            print("DEBUG: buffer.push success, beforePush: 0x\(String(format: "%04X", beforePush)), afterPush: 0x\(String(format: "%04X", afterPush))")

            if beforePush != 0 && afterPush != 0 && beforePush != afterPush {
                // 이전 음절이 완성되었으므로 커밋
                commitString.append(beforePush)
                print("DEBUG: committed beforePush: 0x\(String(format: "%04X", beforePush))")

                // 현재 완성된 음절이 있으면 다시 커밋
                if afterPush != 0 {
                    commitString.append(afterPush)
                    print("DEBUG: committed afterPush: 0x\(String(format: "%04X", afterPush))")
                    // 버퍼 초기화 (현재 음절 처리 완료)
                    buffer.clear()
                }
            } else if afterPush != 0 {
                // 완성된 음절이 있으면 커밋
                commitString.append(afterPush)
                print("DEBUG: committed afterPush: 0x\(String(format: "%04X", afterPush))")
                // 버퍼 초기화 - 하지만 종성 입력 시에는 초기화하지 않음
                if !HangulCharacter.isJongseong(processedJamo) {
                    buffer.clear()
                }
            } else {
                print("DEBUG: no syllable to commit")
            }


        }

        return success
    }

    /// 백스페이스 처리
    /// - Returns: 처리되었으면 true
    public func backspace() -> Bool {
        // 1. 먼저 버퍼에서 제거 시도
        if !buffer.isEmpty {
            let removed = buffer.pop()
            if removed != 0 {
                updatePreeditString()
                return true
            }
        }

        // 2. 버퍼가 비어있고, 조합중인 입력이 없는 경우에만 커밋된 문자열에서 제거
        // (완성된 음절은 백스페이스로 지울 수 없음)
        if !commitString.isEmpty && buffer.isEmpty {
            // 최근 커밋된 내용이 완성된 음절인지 확인
            let lastCommitted = commitString.last
            if let lastChar = lastCommitted, HangulCharacter.isSyllable(lastChar) {
                // 완성된 음절인 경우 지우지 않음
                return false
            } else {
                // 일반 문자인 경우 지움
                _ = commitString.removeLast()
                delegate?.hangulInputContext(self, didProcess: 8, result: true)
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

    /// 디버그용: 버퍼 상태 확인
    /// - Returns: 버퍼의 초성, 중성, 종성 값
    internal func debugBufferState() -> (choseong: UCSChar, jungseong: UCSChar, jongseong: UCSChar) {
        print("debugBufferState: buffer address = \(Unmanaged.passUnretained(buffer).toOpaque())")
        print("debugBufferState: choseong = 0x\(String(format: "%04X", buffer.choseong)), jungseong = 0x\(String(format: "%04X", buffer.jungseong)), jongseong = 0x\(String(format: "%04X", buffer.jongseong))")
        return (buffer.choseong, buffer.jungseong, buffer.jongseong)
    }

    /// 모든 내용을 커밋 (안전한 버전)
    /// - Returns: 커밋된 문자열
    public func flush() -> [UCSChar] {
        let result = safeFlush()
        return ensureCrossPlatformCompatibility(result)
    }

    /// 기존 flush 메서드 (하위 호환성)
    public func legacyFlush() -> [UCSChar] {
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
        return normalizeUnicode(result)
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

    /// 유니코드 정규화된 문자열 반환
    /// - Parameter text: 정규화할 텍스트
    /// - Returns: NFC 정규화된 문자열
    internal func normalizeUnicode(_ text: [UCSChar]) -> [UCSChar] {
        if !forceNFCNormalization {
            return text
        }

        let characters = text.compactMap { UnicodeScalar($0) }.map { Character($0) }
        let string = String(characters)
        let normalized = string.precomposedStringWithCanonicalMapping
        return normalized.unicodeScalars.map { $0.value }
    }

    /// 입력 처리 전 검증
    /// - Parameter jamo: 검증할 자모
    /// - Returns: 유효하면 true
    private func validateJamo(_ jamo: UCSChar) -> Bool {
        // 유니코드 한글 자모 범위 확인
        let isValidRange = (0x1100...0x11FF).contains(jamo) || // 결합 자모
                          (0x3131...0x318E).contains(jamo)    // 호환 자모
        return isValidRange
    }

    /// 안전한 버퍼 플러시
    private func safeFlush() -> [UCSChar] {
        do {
            let result = try flushWithValidation()
            return normalizeUnicode(result)
        } catch {
            // 오류 복구 시도
            recoverFromError()

            // 최소한의 데이터라도 보존
            let preservedData = commitString
            commitString.removeAll()

            return normalizeUnicode(preservedData)
        }
    }

    /// 검증을 포함한 flush
    private func flushWithValidation() throws -> [UCSChar] {
        guard !buffer.isEmpty else {
            return []
        }

        // 버퍼 상태 검증
        if enableBufferMonitoring {
            try validateBufferState()
        }

        var result: [UCSChar] = []

        if !buffer.isEmpty {
            if outputMode == .syllable {
                let syllable = buffer.buildSyllable()
                if syllable != 0 {
                    result.append(syllable)
                } else {
                    // 완성되지 않은 음절 처리
                    let jamos = buffer.getJamoString()
                    // 완성되지 않은 초성만 있는 경우는 처리하지 않음 (버퍼 비움)
                    if jamos.count == 1 && HangulCharacter.isChoseong(jamos[0]) && buffer.jungseong == 0 {
                        // 초성만 있고 중성이 없는 경우는 처리하지 않음
                        // 실제 한글 입력기에서는 이 상태로 남겨두지 않음
                    } else {
                        // 다른 경우는 기존 로직 적용
                        for jamo in jamos {
                            if HangulCharacter.isChoseong(jamo) && buffer.jungseong == 0 {
                                result.append(HangulCharacter.compatibilityJamoToJamo(jamo, as: .choseong))
                            } else {
                                result.append(jamo)
                            }
                        }
                    }
                }
            } else {
                result.append(contentsOf: buffer.getJamoString())
            }
        }

        // 상태 초기화 (버퍼만 비우고, 커밋된 문자열은 그대로 유지)
        buffer.clear()
        preeditString.removeAll()
        // commitString은 그대로 유지 - flush는 버퍼의 내용만 flush

        return result
    }

    /// 버퍼 상태 검증
    private func validateBufferState() throws {
        let jamoString = buffer.getJamoString()

        // 버퍼 크기 검증
        guard jamoString.count <= maxBufferSize else {
            throw HangulInputError.bufferOverflow
        }

        // 자모 유효성 검증
        for jamo in jamoString {
            guard validateJamo(jamo) else {
                throw HangulInputError.invalidJamo(jamo)
            }
        }

        // 버퍼 일관성 검증 - 간단한 크기 기반 검증
        if jamoString.count > 0 && jamoString.count <= 3 {
            // 유효한 조합 상태로 간주
        } else if jamoString.count > 3 {
            throw HangulInputError.bufferOverflow
        }
    }

    /// 오류 복구
    private func recoverFromError() {
        guard autoErrorRecovery else { return }

        // 안전한 상태로 복구
        buffer.clear()
        preeditString.removeAll()
        commitString.removeAll()

        // 델리게이트에 오류 알림
        delegate?.hangulInputContext(self, didTransition: 0, preedit: [])
    }

    /// 파일명용 정규화 (강제 NFC)
    /// - Parameter text: 정규화할 텍스트
    /// - Returns: 파일명 호환성을 위한 NFC 정규화된 텍스트
    public func normalizeForFilename(_ text: [UCSChar]) -> [UCSChar] {
        let characters = text.compactMap { UnicodeScalar($0) }.map { Character($0) }
        let string = String(characters)
        let normalized = string.precomposedStringWithCanonicalMapping

        // 파일명에 부적합한 문자들 제거/교체
        let filenameSafe = normalized
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")

        return filenameSafe.unicodeScalars.map { $0.value }
    }

    /// 크로스플랫폼 호환성을 위한 변환
    /// - Parameter text: 변환할 텍스트
    /// - Returns: 플랫폼 호환성을 보장한 텍스트
    public func ensureCrossPlatformCompatibility(_ text: [UCSChar]) -> [UCSChar] {
        if filenameCompatibilityMode {
            return normalizeForFilename(text)
        } else {
            return normalizeUnicode(text)
        }
    }

    /// NFD 텍스트를 NFC로 변환 (macOS ↔ Windows 호환성)
    /// - Parameter text: NFD 텍스트
    /// - Returns: NFC 변환된 텍스트
    public static func convertNFDToNFC(_ text: String) -> String {
        return text.precomposedStringWithCanonicalMapping
    }

    /// 텍스트의 유니코드 정규화 형태 확인
    /// - Parameter text: 확인할 텍스트
    /// - Returns: 정규화 형태 정보
    public static func analyzeUnicodeNormalization(_ text: String) -> (form: String, isNFC: Bool, isNFD: Bool) {
        let nfc = text.precomposedStringWithCanonicalMapping
        let nfd = text.decomposedStringWithCanonicalMapping

        // 유니코드 스칼라 수준에서 비교
        let textScalars = Array(text.unicodeScalars)
        let nfcScalars = Array(nfc.unicodeScalars)
        let nfdScalars = Array(nfd.unicodeScalars)

        if textScalars.elementsEqual(nfcScalars) {
            return ("NFC", true, false)
        } else if textScalars.elementsEqual(nfdScalars) {
            return ("NFD", false, true)
        } else {
            return ("Other/Mixed", false, false)
        }
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
        // 입력 자모 유효성 검증
        guard validateJamo(jamo) else {
            return false
        }

        // 버퍼가 가득 찼는지 확인
        if buffer.getJamoString().count >= maxBufferSize {
            let _ = safeFlush() // 안전하게 flush
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

        // 유니코드 정규화 적용
        preeditString = normalizeUnicode(preeditString)
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
