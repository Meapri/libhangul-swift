//
//  LibHangul.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  libhangul Swift 라이브러리의 메인 모듈
//

import Foundation

// MARK: - Memory Management

/// 객체 재사용을 위한 제네릭 객체 풀
public final class ObjectPool<T: AnyObject> {
    private let capacity: Int
    private var pool: [T] = []
    private let queue = DispatchQueue(label: "com.libhangul.objectpool", attributes: .concurrent)

    public init(capacity: Int) {
        self.capacity = capacity
    }

    /// 객체를 빌리거나 새로 생성
    public func borrow(_ factory: () -> T) -> T {
        queue.sync {
            if let object = pool.popLast() {
                return object
            }
            return factory()
        }
    }

    /// 객체를 반환
    public func `return`(_ object: T) {
        queue.async {
            if self.pool.count < self.capacity {
                self.pool.append(object)
            }
        }
    }

    /// 풀 비우기
    public func clear() {
        queue.sync {
            pool.removeAll()
        }
    }
}

// MARK: - Error Handling

/// 라이브러리 오류 타입
public enum HangulError: LocalizedError {
    case invalidConfiguration(String)
    case bufferOverflow(maxSize: Int)
    case invalidJamoCode(UCSChar)
    case keyboardNotFound(String)
    case unicodeConversionFailed(String)
    case memoryAllocationFailed
    case inconsistentState(String)
    case threadSafetyViolation

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "잘못된 설정: \(message)"
        case .bufferOverflow(let maxSize):
            return "버퍼 오버플로우 (최대 크기: \(maxSize))"
        case .invalidJamoCode(let code):
            return "잘못된 자모 코드: 0x\(String(format: "%X", code))"
        case .keyboardNotFound(let keyboardId):
            return "키보드를 찾을 수 없음: \(keyboardId)"
        case .unicodeConversionFailed(let reason):
            return "유니코드 변환 실패: \(reason)"
        case .memoryAllocationFailed:
            return "메모리 할당 실패"
        case .inconsistentState(let reason):
            return "일관성 없는 상태: \(reason)"
        case .threadSafetyViolation:
            return "스레드 안전성 위반"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bufferOverflow:
            return "버퍼 크기를 늘리거나 입력을 줄여보세요"
        case .invalidJamoCode:
            return "올바른 한글 자모 코드를 사용하세요"
        case .keyboardNotFound:
            return "지원되는 키보드 ID를 확인하세요"
        case .unicodeConversionFailed:
            return "입력 텍스트의 유니코드 형식을 확인하세요"
        case .memoryAllocationFailed:
            return "메모리를 확보한 후 다시 시도하세요"
        case .inconsistentState:
            return "입력 컨텍스트를 재설정해보세요"
        case .threadSafetyViolation:
            return "동시 접근을 피하거나 적절한 동기화 메커니즘을 사용하세요"
        default:
            return nil
        }
    }
}

// MARK: - Protocols

/// 한글 입력 엔진 프로토콜
public protocol HangulInputEngine {
    /// 키 입력 처리
    func process(key: Int, context: HangulInputContext) throws -> Bool

    /// 버퍼 플러시
    func flush(context: HangulInputContext) throws -> [UCSChar]

    /// 사전 편집 문자열 가져오기
    func getPreeditString(context: HangulInputContext) -> [UCSChar]

    /// 커밋 문자열 가져오기
    func getCommitString(context: HangulInputContext) -> [UCSChar]

    /// 버퍼 비우기
    func clear(context: HangulInputContext)
}

/// 한글 키보드 프로토콜
public protocol HangulKeyboardProtocol {
    var id: String { get }
    var name: String { get }
    var type: HangulKeyboardType { get }

    /// 키 코드를 자모로 변환
    func keyToJamo(key: Int, state: HangulKeyboardState) -> UCSChar

    /// 키보드 상태 업데이트
    func updateState(key: Int, state: inout HangulKeyboardState) -> Bool
}

/// 한글 버퍼 프로토콜
public protocol HangulBufferProtocol {
    /// 자모 추가
    func push(jamo: UCSChar) throws

    /// 자모 제거
    func pop() -> UCSChar

    /// 버퍼 비우기
    func clear()

    /// 버퍼가 비어있는지 확인
    var isEmpty: Bool { get }

    /// 음절로 결합
    func buildSyllable() -> UCSChar

    /// 현재 상태 복사
    func copyState() -> HangulBufferState
}

/// 버퍼 상태 구조체
public struct HangulBufferState {
    public var choseong: UCSChar = 0
    public var jungseong: UCSChar = 0
    public var jongseong: UCSChar = 0
    public var stack: [UCSChar] = []
}

/// 키보드 상태 구조체
public struct HangulKeyboardState {
    public var shift: Bool = false
    public var capsLock: Bool = false
    public var hangulMode: Bool = true
    public var hanjaMode: Bool = false
}

// MARK: - Configuration

/// 한글 입력 라이브러리 설정
public struct HangulInputConfiguration: Sendable {
    /// 최대 버퍼 크기
    public var maxBufferSize: Int

    /// NFC 정규화 강제 사용
    public var forceNFCNormalization: Bool

    /// 버퍼 상태 모니터링 활성화
    public var enableBufferMonitoring: Bool

    /// 자동 오류 복구 활성화
    public var autoErrorRecovery: Bool

    /// 파일명 호환성 모드 활성화
    public var filenameCompatibilityMode: Bool

    /// 출력 모드
    public var outputMode: HangulOutputMode

    /// 기본 키보드
    public var defaultKeyboard: String

    /// 성능 모드 (메모리 vs 속도 최적화)
    public var performanceMode: PerformanceMode

    public init(
        maxBufferSize: Int = 12,
        forceNFCNormalization: Bool = true,
        enableBufferMonitoring: Bool = true,
        autoErrorRecovery: Bool = true,
        filenameCompatibilityMode: Bool = false,
        outputMode: HangulOutputMode = .syllable,
        defaultKeyboard: String = "2",
        performanceMode: PerformanceMode = .balanced
    ) {
        self.maxBufferSize = maxBufferSize
        self.forceNFCNormalization = forceNFCNormalization
        self.enableBufferMonitoring = enableBufferMonitoring
        self.autoErrorRecovery = autoErrorRecovery
        self.filenameCompatibilityMode = filenameCompatibilityMode
        self.outputMode = outputMode
        self.defaultKeyboard = defaultKeyboard
        self.performanceMode = performanceMode
    }

    /// 성능 모드
    public enum PerformanceMode: Sendable {
        case memoryOptimized    // 메모리 사용 최적화
        case speedOptimized     // 속도 최적화
        case balanced          // 균형 모드 (기본값)
    }

    /// 사전 정의된 설정들
    public static let `default` = HangulInputConfiguration()

    public static let memoryOptimized = HangulInputConfiguration(
        maxBufferSize: 8,
        enableBufferMonitoring: false,
        performanceMode: .memoryOptimized
    )

    public static let speedOptimized = HangulInputConfiguration(
        maxBufferSize: 20,
        enableBufferMonitoring: true,
        autoErrorRecovery: true,
        performanceMode: .speedOptimized
    )

    public static let minimal = HangulInputConfiguration(
        maxBufferSize: 6,
        forceNFCNormalization: false,
        enableBufferMonitoring: false,
        autoErrorRecovery: false,
        filenameCompatibilityMode: false,
        performanceMode: .memoryOptimized
    )
}

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

        // 호환 자모를 조합형 자모로 변환 (용도별)
        let choConverted = HangulCharacter.compatibilityJamoToJamo(UCSChar(cho.value), as: .choseong)
        let jungConverted = HangulCharacter.compatibilityJamoToJamo(UCSChar(jung.value), as: .jungseong)
        let jongConverted: UCSChar? = jongseong?.unicodeScalars.first.map { HangulCharacter.compatibilityJamoToJamo(UCSChar($0.value), as: .jongseong) }

        let syllable = HangulCharacter.jamoToSyllable(
            choseong: choConverted,
            jungseong: jungConverted,
            jongseong: jongConverted ?? 0
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
