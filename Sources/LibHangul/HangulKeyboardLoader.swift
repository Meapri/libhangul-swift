//
//  HangulKeyboardLoader.swift
//  LibHangul
//
//  libhangul 자판/조합 XML을 로드하는 데이터 기반 로더
//

import Foundation

// MARK: - 키보드 타입 ↔ XML 문자열

extension HangulKeyboardType {
    /// XML `type` 속성 문자열로부터 생성 ("jamo", "jaso", "romaja", "jamo-yet", "jaso-yet")
    public init(xmlType: String) {
        switch xmlType {
        case "jamo":      self = .jamo
        case "jaso":      self = .jaso
        case "romaja":    self = .romaja
        case "jamo-yet":  self = .jamoYet
        case "jaso-yet":  self = .jasoYet
        default:          self = .jaso
        }
    }

    /// 옛한글 자판 여부 (임의 자모 결합 허용)
    public var isOldHangul: Bool {
        self == .jamoYet || self == .jasoYet
    }
}

// MARK: - 키보드 XML 파싱

extension HangulKeyboard {
    /// 키보드 XML 문자열을 파싱하여 `HangulKeyboard`를 생성한다.
    ///
    /// - Parameters:
    ///   - xml: 키보드 XML 내용
    ///   - combinationResolver: `<include file="..."/>`의 파일명을 받아 결합 규칙을 반환하는 클로저
    /// - Returns: 파싱된 키보드, 실패 시 nil
    public static func parse(xml: String,
                             combinationResolver: ((String) -> HangulCombination?)? = nil) -> HangulKeyboard? {
        // 헤더 속성 추출: <hangul-keyboard id="2" type="jamo">
        guard let headerRange = xml.range(of: "<hangul-keyboard"),
              let headerEnd = xml.range(of: ">", range: headerRange.lowerBound..<xml.endIndex) else {
            return nil
        }
        let header = String(xml[headerRange.lowerBound..<headerEnd.upperBound])
        guard let id = HangulXML.attribute("id", in: header) else { return nil }
        let typeStr = HangulXML.attribute("type", in: header) ?? "jaso"
        let type = HangulKeyboardType(xmlType: typeStr)

        // 이름: <name>...</name>
        let name = HangulXML.elementText("name", in: xml) ?? id

        // 키맵: <item key="0x.." value="0x.."/>
        var keyMap: [Int: UCSChar] = [:]
        let itemPattern = #"<item\s+key="([^"]+)"\s+value="([^"]+)"\s*/?>"#
        if let regex = try? NSRegularExpression(pattern: itemPattern) {
            let ns = xml as NSString
            regex.enumerateMatches(in: xml, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
                guard let match = match, match.numberOfRanges == 3,
                      let key = HangulXML.parseScalar(ns.substring(with: match.range(at: 1))),
                      let value = HangulXML.parseScalar(ns.substring(with: match.range(at: 2))) else {
                    return
                }
                keyMap[Int(key)] = value
            }
        }
        guard !keyMap.isEmpty else { return nil }

        // 조합 규칙: <include file="hangul-combination-xxx.xml"/>
        var combination: HangulCombination?
        if let includeFile = HangulXML.attribute("file", in: xml),
           includeFile.contains("combination") {
            combination = combinationResolver?(includeFile)
        }

        return HangulKeyboard(identifier: id, name: name, type: type,
                              keyMap: keyMap, combination: combination)
    }
}

extension HangulXML {
    /// `<tag>내용</tag>`에서 내용을 추출한다.
    public static func elementText(_ tag: String, in text: String) -> String? {
        let pattern = "<" + NSRegularExpression.escapedPattern(for: tag) + ">(.*?)</" +
                      NSRegularExpression.escapedPattern(for: tag) + ">"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges == 2 else { return nil }
        return ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 번들 리소스 로더

/// 번들된 libhangul XML 리소스를 로드하는 헬퍼.
///
/// `Bundle.module`의 `keyboards/` 하위에서 자판/조합 XML을 읽는다. 따라서 이 패키지를
/// 의존성으로 사용하는 앱에서도 작업 디렉터리에 의존하지 않고 자판 데이터를 로드할 수 있다.
public enum HangulResourceLoader {
    /// 번들에서 자판 XML 리소스 URL을 찾는다.
    static func keyboardURL(_ fileName: String) -> URL? {
        let base = (fileName as NSString).deletingPathExtension
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: base, withExtension: "xml", subdirectory: "keyboards")
        #else
        return Bundle(for: HangulInputContext.self).url(forResource: base, withExtension: "xml", subdirectory: "keyboards")
        #endif
    }

    /// 번들에서 XML 문자열을 읽는다.
    static func loadXMLString(_ fileName: String) -> String? {
        guard let url = keyboardURL(fileName) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// 조합 규칙 파일을 로드한다 (결과 캐시).
    private static let combinationCache = CombinationCache()

    static func loadCombination(_ fileName: String) -> HangulCombination? {
        if let cached = combinationCache.get(fileName) { return cached }
        guard let xml = loadXMLString(fileName) else { return nil }
        let combination = HangulCombination.parse(xml: xml)
        combinationCache.set(fileName, combination)
        return combination
    }

    /// 로드된 자판 캐시 (컨텍스트 생성마다 XML 재파싱 방지).
    /// 자판 인스턴스는 로드 후 읽기 전용으로만 사용되므로 컨텍스트 간 공유가 안전하다.
    private static let keyboardCache = KeyboardCache()

    /// 번들된 자판을 로드한다 (캐시 적용). 예: loadKeyboard(file: "hangul-keyboard-3f.xml")
    public static func loadKeyboard(file fileName: String) -> HangulKeyboard? {
        if let cached = keyboardCache.get(fileName) { return cached }
        guard let xml = loadXMLString(fileName) else { return nil }
        guard let keyboard = HangulKeyboard.parse(xml: xml, combinationResolver: { loadCombination($0) }) else {
            return nil
        }
        keyboardCache.set(fileName, keyboard)
        return keyboard
    }

    /// 번들에 포함된 모든 자판 파일명
    public static let bundledKeyboardFiles: [String] = [
        "hangul-keyboard-2.xml",
        "hangul-keyboard-2y.xml",
        "hangul-keyboard-32.xml",
        "hangul-keyboard-39.xml",
        "hangul-keyboard-3f.xml",
        "hangul-keyboard-3s.xml",
        "hangul-keyboard-3y.xml",
        "hangul-keyboard-ahn.xml",
        "hangul-keyboard-ro.xml"
    ]
}

/// 조합 규칙 캐시 (스레드 안전)
private final class CombinationCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: HangulCombination] = [:]

    func get(_ key: String) -> HangulCombination? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, _ value: HangulCombination) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }
}

/// 자판 캐시 (스레드 안전). 로드된 자판 인스턴스를 공유한다.
private final class KeyboardCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: HangulKeyboard] = [:]

    func get(_ key: String) -> HangulKeyboard? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, _ value: HangulKeyboard) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }
}
