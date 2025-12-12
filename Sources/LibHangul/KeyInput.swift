//
//  KeyInput.swift
//  LibHangul
//
//  키 입력을 명시적으로 표현하는 타입
//

import Foundation

/// 키 입력을 명시적으로 표현하는 타입
///
/// `Int` 타입의 모호함을 제거하고 Type Safety를 확보합니다.
/// 
/// ## 사용 예시
/// ```swift
/// let input = KeyInput.character("r")  // ㄱ
/// context.process(input)
/// ```
public enum KeyInput: Sendable, Equatable {
    /// ASCII 문자 입력
    case character(Character)
    
    /// 시스템 키코드 (CGKeyCode 등)
    case keyCode(UInt16)
    
    /// 백스페이스
    case backspace
    
    /// ASCII 코드에서 KeyInput 생성
    /// - Parameter ascii: ASCII 코드 값
    /// - Returns: KeyInput (유효하지 않으면 nil)
    public static func fromASCII(_ ascii: Int) -> KeyInput? {
        guard ascii >= 0 && ascii <= 127 else { return nil }
        guard let scalar = UnicodeScalar(ascii) else { return nil }
        return .character(Character(scalar))
    }
    
    /// Character로 변환 (가능한 경우)
    public var asCharacter: Character? {
        switch self {
        case .character(let char):
            return char
        case .keyCode, .backspace:
            return nil
        }
    }
    
    /// ASCII 값으로 변환 (가능한 경우)
    public var asciiValue: Int? {
        switch self {
        case .character(let char):
            return char.asciiValue.map { Int($0) }
        case .keyCode, .backspace:
            return nil
        }
    }
}
