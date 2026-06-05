//
//  HangulCombination.swift
//  LibHangul
//
//  자모 결합 규칙 테이블 (libhangul combination XML 대응)
//

import Foundation

/// 자모 결합 규칙 테이블.
///
/// `first + second → result` 형태의 일반 조합 규칙을 담는다. 현대 한글의 겹받침·이중모음뿐
/// 아니라, `hangul-combination-full.xml`의 옛한글 임의 자모 클러스터(예: ㄱ+ㄷ→ᄓ)까지
/// 동일한 메커니즘으로 표현한다. 불변(immutable) 테이블이므로 `Sendable`이다.
public final class HangulCombination: Sendable {
    /// (first << 32 | second) → result
    private let table: [UInt64: UCSChar]

    /// 규칙 배열로 초기화
    public init(rules: [(first: UCSChar, second: UCSChar, result: UCSChar)] = []) {
        var t = [UInt64: UCSChar](minimumCapacity: rules.count)
        for r in rules {
            t[Self.key(r.first, r.second)] = r.result
        }
        self.table = t
    }

    @inline(__always)
    private static func key(_ first: UCSChar, _ second: UCSChar) -> UInt64 {
        (UInt64(first) << 32) | UInt64(second)
    }

    /// 두 자모를 결합한 결과를 반환 (규칙이 없으면 nil)
    public func combine(_ first: UCSChar, _ second: UCSChar) -> UCSChar? {
        table[Self.key(first, second)]
    }

    /// 규칙 개수
    public var count: Int { table.count }

    /// 비어있는지 여부
    public var isEmpty: Bool { table.isEmpty }
}

// MARK: - XML 파싱

extension HangulCombination {
    /// combination XML 문자열에서 조합 규칙을 파싱한다.
    ///
    /// 형식: `<item first="0x1100" second="0x1100" result="0x1101"/>`
    public static func parse(xml: String) -> HangulCombination {
        let pattern = #"<item\s+first="([^"]+)"\s+second="([^"]+)"\s+result="([^"]+)"\s*/?>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return HangulCombination()
        }
        let ns = xml as NSString
        var rules: [(first: UCSChar, second: UCSChar, result: UCSChar)] = []
        regex.enumerateMatches(in: xml, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4,
                  let f = HangulXML.parseScalar(ns.substring(with: match.range(at: 1))),
                  let s = HangulXML.parseScalar(ns.substring(with: match.range(at: 2))),
                  let r = HangulXML.parseScalar(ns.substring(with: match.range(at: 3))) else {
                return
            }
            rules.append((f, s, r))
        }
        return HangulCombination(rules: rules)
    }
}

// MARK: - XML 공용 헬퍼

/// libhangul XML 데이터 파싱 공용 유틸리티
public enum HangulXML {
    /// "0x1100" / "1100" / "65" 형태의 문자열을 UCSChar로 변환한다.
    public static func parseScalar(_ string: String) -> UCSChar? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("0x") {
            return UCSChar(trimmed.dropFirst(2), radix: 16)
        }
        return UCSChar(trimmed)
    }

    /// 특정 속성 값을 추출한다. 예: attribute("type", in: "<hangul-keyboard id=\"2\" type=\"jamo\">")
    public static func attribute(_ name: String, in text: String) -> String? {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: name) + "\\s*=\\s*\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges == 2 else { return nil }
        return ns.substring(with: match.range(at: 1))
    }
}
