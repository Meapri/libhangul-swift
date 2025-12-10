//
//  Logging.swift
//  LibHangul
//
//  구조화된 로깅 시스템 - OSLog 기반
//

import Foundation
import OSLog

// MARK: - Logger Extensions

/// LibHangul 전용 로거
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension Logger {
    /// 한글 입력 관련 로깅 (입력 처리, 버퍼 상태 등)
    static let hangulInput = Logger(subsystem: "com.libhangul", category: "input")
    
    /// 키보드 관련 로깅 (키 매핑, 키보드 전환 등)
    static let hangulKeyboard = Logger(subsystem: "com.libhangul", category: "keyboard")
    
    /// 한자 관련 로깅 (사전 로드, 검색 등)
    static let hangulHanja = Logger(subsystem: "com.libhangul", category: "hanja")
    
    /// 에러 로깅
    static let hangulError = Logger(subsystem: "com.libhangul", category: "error")
    
    /// 성능 관련 로깅
    static let hangulPerformance = Logger(subsystem: "com.libhangul", category: "performance")
}

// MARK: - Log Wrapper (하위 호환성)

/// 하위 호환성을 위한 로그 레벨
public enum HangulLogLevel: Int, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4
}

/// 구조화된 로깅 유틸리티
/// OSLog가 사용 가능하면 OSLog 사용, 그렇지 않으면 무시
public struct HangulLogger: Sendable {
    public static let shared = HangulLogger()
    
    /// 현재 로그 레벨 (이 레벨 이상만 출력)
    public var minimumLevel: HangulLogLevel = .warning
    
    /// 로깅 활성화 여부
    public var isEnabled: Bool = true
    
    private init() {}
    
    /// 입력 관련 로그
    public func input(_ message: String, level: HangulLogLevel = .debug) {
        log(message, level: level, category: .input)
    }
    
    /// 키보드 관련 로그
    public func keyboard(_ message: String, level: HangulLogLevel = .debug) {
        log(message, level: level, category: .keyboard)
    }
    
    /// 에러 로그
    public func error(_ message: String) {
        log(message, level: .error, category: .error)
    }
    
    private enum Category {
        case input, keyboard, hanja, error, performance
    }
    
    private func log(_ message: String, level: HangulLogLevel, category: Category) {
        guard isEnabled, level.rawValue >= minimumLevel.rawValue else { return }
        
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            let logger: Logger
            switch category {
            case .input: logger = .hangulInput
            case .keyboard: logger = .hangulKeyboard
            case .hanja: logger = .hangulHanja
            case .error: logger = .hangulError
            case .performance: logger = .hangulPerformance
            }
            
            switch level {
            case .debug: logger.debug("\(message, privacy: .public)")
            case .info: logger.info("\(message, privacy: .public)")
            case .warning: logger.warning("\(message, privacy: .public)")
            case .error: logger.error("\(message, privacy: .public)")
            case .fault: logger.fault("\(message, privacy: .public)")
            }
        }
        // 하위 OS에서는 무시 (print 사용 안 함)
    }
}

// MARK: - Signpost for Performance

/// Instruments Signpost 지원 (성능 측정)
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct HangulSignpost {
    private static let signposter = OSSignposter(logger: .hangulPerformance)
    
    /// 성능 측정 시작
    public static func beginInterval(_ name: StaticString) -> OSSignpostIntervalState {
        signposter.beginInterval(name)
    }
    
    /// 성능 측정 종료
    public static func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }
}
