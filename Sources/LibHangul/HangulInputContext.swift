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
public enum HangulInputError: Error, Sendable {
    case bufferOverflow(maxSize: Int)
    case invalidJamo(UCSChar)
    case invalidKeyCode(Int)
    case inconsistentBufferState(reason: String)
    case unicodeNormalizationFailed(reason: String)
    case keyboardNotFound(identifier: String)
    case configurationError(reason: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow(let maxSize):
            return "버퍼가 가득 찼습니다 (최대 크기: \(maxSize))"
        case .invalidJamo(let jamo):
            return "잘못된 자모 코드: 0x\(String(format: "%04X", jamo))"
        case .invalidKeyCode(let keyCode):
            return "잘못된 키 코드: \(keyCode)"
        case .inconsistentBufferState(let reason):
            return "버퍼 상태가 일관되지 않음: \(reason)"
        case .unicodeNormalizationFailed(let reason):
            return "유니코드 정규화 실패: \(reason)"
        case .keyboardNotFound(let identifier):
            return "키보드를 찾을 수 없음: \(identifier)"
        case .configurationError(let reason):
            return "설정 오류: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bufferOverflow:
            return "입력을 줄이거나 버퍼 크기를 늘려보세요"
        case .invalidJamo:
            return "올바른 한글 자모를 입력하세요"
        case .invalidKeyCode:
            return "올바른 키 코드를 입력하세요"
        case .inconsistentBufferState:
            return "입력 컨텍스트를 재설정해보세요"
        case .unicodeNormalizationFailed:
            return "텍스트의 유니코드 형식을 확인하세요"
        case .keyboardNotFound:
            return "지원되는 키보드 식별자를 확인하세요"
        case .configurationError:
            return "설정 값을 다시 확인하세요"
        }
    }
}

/// 입력 컨텍스트 옵션
public enum HangulInputContextOption: Int, Sendable {
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
/// ⚠️ DEPRECATED: 동시성 환경에서는 ThreadSafeHangulInputContext를 사용하세요
/// 참고: Swift 6 동시성 제한으로 인해 이 클래스는 Sendable이 아닙니다.
/// 단일 스레드 환경에서만 사용하세요.
@available(*, deprecated, message: "동시성 환경에서는 ThreadSafeHangulInputContext를 사용하세요. 단일 스레드에서만 안전합니다.")
public final class HangulInputContext {

    // MARK: - Properties

    /// 키보드 관리자
    private let keyboardManager: HangulKeyboardManager

    /// 현재 키보드
    public private(set) var keyboard: HangulKeyboard?

    /// 입력 버퍼
    private let buffer: HangulBuffer

    /// 사전 편집 문자열 (조합중인 문자열) - 효율적인 메모리 관리
    private var preeditString: [UCSChar] = []
    private var preeditStringCapacity: Int = 16

    /// 커밋된 문자열 - 효율적인 메모리 관리
    private var commitString: [UCSChar] = []
    private var commitStringCapacity: Int = 64

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
        get { configuration.forceBufferMonitoring }
        set { configuration.forceBufferMonitoring = newValue }
    }

    /// 자동 오류 복구
    public var autoErrorRecovery: Bool {
        get { configuration.forceAutoErrorRecovery }
        set { configuration.forceAutoErrorRecovery = newValue }
    }

    /// 파일명 호환성 모드
    public var filenameCompatibilityMode: Bool {
        get { configuration.forceFilenameCompatibilityMode }
        set { configuration.forceFilenameCompatibilityMode = newValue }
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
        let result = processKey(key)
        switch result {
        case .success(let processed):
            return processed
        case .failure(let error):
            handleError(error, for: key)
            return false
        }
    }

    /// Result 타입을 사용한 키 입력 처리 (내부 메서드)
    /// - Parameter key: ASCII 키 코드
    /// - Returns: 처리 결과
    private func processKey(_ key: Int) -> Result<Bool, HangulInputError> {
        guard let keyboard = keyboard else {
            return .failure(.keyboardNotFound(identifier: "nil"))
        }

        // 키 코드 유효성 검증 (음수 방지)
        guard key >= 0 && key <= 0x10FFFF else {
            return .failure(.invalidKeyCode(key))
        }

        // 키 매핑
        let jamo = keyboard.mapKey(key)

        // 백스페이스 처리
        if key == 8 || key == 0x7F { // Backspace or Delete
            let result = backspace()
            return .success(result)
        }

        if jamo == 0 {
            // NULL 문자는 유효하지 않은 입력으로 처리
            if key == 0 {
                return .success(false)
            }
            
            // 제어 문자 (ASCII 0-31, 127)는 처리하지 않음 - 시스템에서 처리하도록 반환
            // 백스페이스(8)와 Delete(127)는 위에서 이미 처리됨
            // 방향키, Tab, Escape 등은 입력기가 처리하지 않아야 함
            if key < 32 || key == 127 {
                // 버퍼가 있으면 먼저 커밋
                if !buffer.isEmpty {
                    let flushResult = safeFlush()
                    if case .success(let flushed) = flushResult {
                        commitString.append(contentsOf: flushed)
                    }
                }
                return .success(false)  // 시스템이 처리하도록 false 반환
            }

            // 매핑되지 않은 일반 문자(영어/기호)는 커밋
            if !buffer.isEmpty {
                let flushResult = safeFlush()
                switch flushResult {
                case .success(let flushed):
                    commitString.append(contentsOf: flushed)
                case .failure(let error):
                    return .failure(error)
                }
            }
            let charValue = UCSChar(key)
            commitString.append(charValue)
            return .success(true)
        }

        // 한글 자모가 아닌 경우
        if !HangulCharacter.isJamo(jamo) {
            let flushResult = safeFlush()
            switch flushResult {
            case .success(let flushed):
                commitString.append(contentsOf: flushed)
            case .failure(let error):
                return .failure(error)
            }
            commitString.append(jamo)
            return .success(true)
        }

        // 한글 자모 처리
        do {
            let result = try processJamoWithValidation(jamo)
            updatePreeditString()
            return .success(result)
        } catch let error as HangulInputError {
            return .failure(error)
        } catch {
            return .failure(.inconsistentBufferState(reason: error.localizedDescription))
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
            let flushResult = safeFlush()
            switch flushResult {
            case .success(let flushed):
                commitString.append(contentsOf: flushed)
            case .failure(let error):
                throw error
            }
        }

        // 입력 전 버퍼 상태 저장 (완성된 음절 감지용)
        let beforePush = buffer.buildSyllable()
        
        var processedJamo = jamo
        
        // Removed hardcoded 'Idiomatic Input' (0x1102 check)
        // Standardizing behavior: rely on pushChoseong logic to handle transitions.


        // [New Logic] 음절 분리 확인 (Jongseong + Jungseong -> Next Syllable)
        if HangulCharacter.isJungseong(processedJamo) && buffer.jongseong != 0 {
            let currentJongseong = buffer.jongseong
            let wasExtended = buffer.jongseongWasExtended
            
            if wasExtended {
                // 종성이 결합으로 확장됨 (ㄱ+ㄱ=ㄲ, ㄱ+ㅅ=ㄳ 등)
                // 분해하여 뒷부분만 다음 음절로 이동
                let (first, second) = HangulCharacter.decomposeJongseong(currentJongseong)
                
                if second != 0 {
                    let nextChoseong = HangulCharacter.jongseongToChoseong(second)
                    if nextChoseong != 0 {
                        // 앞부분만 남김
                        buffer.setJongseong(first, wasExtended: false)
                        
                        // 현재 음절 커밋
                        let flushResult = safeFlush()
                        if case .success(let flushed) = flushResult {
                            commitString.append(contentsOf: flushed)
                        }
                        
                        // 다음 음절 시작
                        let _ = buffer.push(nextChoseong)
                        updatePreeditString()
                    }
                }
            } else {
                // 종성이 단일 입력됨 (ㄱ, ㄲ, ㄴ 등 - 확장 없이 직접 입력)
                // 종성 전체를 다음 음절의 초성으로 이동
                let wholeAsChoseong = HangulCharacter.jongseongToChoseong(currentJongseong)
                
                if wholeAsChoseong != 0 {
                    // 버퍼에서 종성 완전히 제거
                    buffer.setJongseong(0)
                    
                    // 현재 음절 커밋
                    let flushResult = safeFlush()
                    if case .success(let flushed) = flushResult {
                        commitString.append(contentsOf: flushed)
                    }
                    
                    // 다음 음절 시작
                    let _ = buffer.push(wholeAsChoseong)
                    updatePreeditString()
                }
            }
        }

        // 자모를 버퍼에 추가
        let success = buffer.push(processedJamo)
        if success {
            updatePreeditString()

            // 배열 용량 관리
            manageArrayCapacity()

            return true
        } else {
            // 추가 실패 (결합 불가 등): 현재 버퍼를 커밋하고 새로 시작
            let flushResult = safeFlush()
            if case .success(let flushed) = flushResult {
                commitString.append(contentsOf: flushed)
            }
            
            // 다시 시도
            let retrySuccess = buffer.push(processedJamo)
            if retrySuccess {
                updatePreeditString()
                return true
            } else {
                // 재시도도 실패하면 오류
                throw HangulInputError.inconsistentBufferState(reason: "Push retry failed after flush")
            }
        }
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

        // 2. 버퍼가 비어있고, 조합중인 입력이 없는 경우 커밋된 문자열에서 제거
        // (완성된 음절도 백스페이스로 지울 수 있어야 함)
        if !commitString.isEmpty && buffer.isEmpty {
            // 최근 커밋된 내용을 지움 (완성된 음절이든 일반 문자든)
            _ = commitString.removeLast()
            delegate?.hangulInputContext(self, didProcess: 8, result: true)
            return true
        }

        return false
    }

    /// 버퍼 초기화
    public func reset() {
        buffer.clear()
        preeditString = []
        commitString = []
        // 용량 재설정 (메모리 효율성)
        preeditString.reserveCapacity(preeditStringCapacity)
        commitString.reserveCapacity(commitStringCapacity)
    }

    /// 효율적인 배열 크기 관리
    private func manageArrayCapacity() {
        // preeditString 용량 관리
        if preeditString.count > preeditStringCapacity {
            preeditStringCapacity = preeditString.count * 2
            preeditString.reserveCapacity(preeditStringCapacity)
        }

        // commitString 용량 관리
        if commitString.count > commitStringCapacity {
            commitStringCapacity = commitString.count * 2
            commitString.reserveCapacity(commitStringCapacity)
        }
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
        commitString = []
        commitString.reserveCapacity(commitStringCapacity) // 용량 유지
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
        switch result {
        case .success(let data):
            return ensureCrossPlatformCompatibility(data)
        case .failure:
            return []
        }
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

    /// 안전한 버퍼 플러시 (Result 타입 반환)
    private func safeFlush() -> Result<[UCSChar], HangulInputError> {
        do {
            let result = try flushWithValidation()
            return .success(normalizeUnicode(result))
        } catch let error as HangulInputError {
            // 오류 복구 시도
            recoverFromError()
            return .failure(error)
        } catch {
            // 예상치 못한 오류
            recoverFromError()
            return .failure(.inconsistentBufferState(reason: error.localizedDescription))
        }
    }

    /// 호환성을 위한 기존 safeFlush 메서드
    private func safeFlushLegacy() -> [UCSChar] {
        let result = safeFlush()
        switch result {
        case .success(let data):
            return data
        case .failure:
            // 오류 시 최소한의 데이터라도 보존
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
                    // 완성되지 않은 음절 처리 - 자모를 호환 자모로 변환하여 출력
                    let jamos = buffer.getJamoString()
                    for jamo in jamos {
                        // 초성/중성/종성을 호환 자모로 변환
                        let compatJamo = HangulCharacter.jamoToCJamo(jamo)
                        result.append(compatJamo)
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
            throw HangulInputError.bufferOverflow(maxSize: maxBufferSize)
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
            throw HangulInputError.bufferOverflow(maxSize: maxBufferSize)
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

    /// 에러 처리 헬퍼 메서드
    private func handleError(_ error: HangulInputError, for key: Int) {
        // 로그 기록
        print("HangulInputContext 에러: \(error.errorDescription ?? "알 수 없는 오류")")

        // 복구 제안이 있으면 로그에 기록
        if let suggestion = error.recoverySuggestion {
            print("복구 제안: \(suggestion)")
        }

        // 오류 복구
        recoverFromError()

        // 델리게이트에 오류 알림
        delegate?.hangulInputContext(self, didProcess: key, result: false)
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

