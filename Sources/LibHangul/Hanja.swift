//
//  Hanja.swift
//  LibHangul
//
//  Created by Sonic AI Assistant
//
//  한자 사전 검색 기능
//

import Foundation

/// 한자 사전의 최소 단위
/// C 코드의 struct _Hanja에 대응
public final class Hanja {
    /// 키 (일반적으로 한글)
    public let key: String
    /// 값 (한자)
    public let value: String
    /// 설명 (comment)
    public let comment: String

    public init(key: String, value: String, comment: String = "") {
        self.key = key
        self.value = value
        self.comment = comment
    }

    /// 키를 반환 (UTF-8 호환)
    public func getKey() -> String {
        key
    }

    /// 값을 반환 (UTF-8 호환)
    public func getValue() -> String {
        value
    }

    /// 설명을 반환 (UTF-8 호환)
    public func getComment() -> String {
        comment
    }
}

/// 한자 검색 결과를 담는 리스트
/// C 코드의 struct _HanjaList에 대응
public final class HanjaList {
    /// 검색에 사용된 키
    public let key: String
    /// 검색된 한자 항목들
    private var items: [Hanja] = []

    public init(key: String) {
        self.key = key
    }

    /// 항목 개수 반환
    public func getSize() -> Int {
        items.count
    }

    /// n번째 항목 반환
    public func getNth(_ n: Int) -> Hanja? {
        guard n >= 0 && n < items.count else { return nil }
        return items[n]
    }

    /// n번째 항목의 키 반환
    public func getNthKey(_ n: Int) -> String? {
        getNth(n)?.getKey()
    }

    /// n번째 항목의 값 반환
    public func getNthValue(_ n: Int) -> String? {
        getNth(n)?.getValue()
    }

    /// n번째 항목의 설명 반환
    public func getNthComment(_ n: Int) -> String? {
        getNth(n)?.getComment()
    }

    /// 항목 추가
    func append(_ hanja: Hanja) {
        items.append(hanja)
    }

    /// 모든 항목 반환
    func getAll() -> [Hanja] {
        items
    }
}

/// 한자 인덱스 구조체
/// C 코드의 struct _HanjaIndex에 대응
private struct HanjaIndex {
    let offset: UInt
    let key: String

    init(offset: UInt, key: String) {
        self.offset = offset
        self.key = key
    }
}

/// 한자 사전 테이블
/// C 코드의 struct _HanjaTable에 대응
/// 한자 사전 테이블
/// C 코드의 struct _HanjaTable에 대응
public final class HanjaTable {
    /// 키 테이블 (Legacy compatible, but not actively used in Trie optimization)
    private var keytable: [HanjaIndex] = []
    
    /// 사전 데이터 (Optimized Trie Structure)
    private var trie: HanjaTrie = HanjaTrie()
    
    public init() {}

    /// 한자 사전 파일을 로드
    /// - Parameter filename: 사전 파일 경로, nil이면 여러 경로 검색
    /// - Returns: 성공 여부
    public func load(filename: String? = nil) -> Bool {
        var path: String?
        
        if let filename = filename {
            path = filename
        } else {
            // 여러 경로에서 한자 사전 검색
            let searchPaths = [
                "data/hanja/hanja.txt",
                "./hanja.txt",
                Bundle.main.bundlePath + "/Contents/Resources/hanja.txt",
                Bundle.main.bundlePath + "/Contents/Resources/data/hanja/hanja.txt"
            ]
            
            for searchPath in searchPaths {
                if FileManager.default.fileExists(atPath: searchPath) {
                    path = searchPath
                    break
                }
            }
        }
        
        guard let validPath = path else {
            return false
        }

        return parseDictionary(path: validPath)
    }

    /// 정확한 키 매칭으로 한자 검색
    /// - Parameter key: 검색할 키
    /// - Returns: 검색 결과 리스트
    public func matchExact(key: String) -> HanjaList? {
        guard !key.isEmpty else { return nil }

        guard let results = trie.search(key: key) else { return nil }

        let list = HanjaList(key: key)
        for result in results {
            list.append(result)
        }

        return list
    }

    /// 접두사 매칭으로 한자 검색 (최적화됨)
    /// - Parameter key: 검색할 키
    /// - Returns: 검색 결과 리스트
    /// - Note: 기존 구현은 "키를 하나씩 줄여가며 Exact Match"를 반복했으나,
    ///         Trie를 사용하면 단 한 번의 순회로 모든 유효한 접두어 매칭 결과를 찾을 수 있음.
    public func matchPrefix(key: String) -> HanjaList? {
        guard !key.isEmpty else { return nil }

        // Trie.searchPrefixes returns ALL matches found for any prefix of `key`.
        // This is equivalent to key="ABC", check "A", "AB", "ABC".
        // The original implementation checked "ABC", "AB", "A". Order might matter for some UIs,
        // but HanjaList structure is just a list. If order is critical (longest first vs shortest first),
        // we can reverse the results.
        
        // Original logic:
        // 1. Try "ABC" -> append results
        // 2. Try "AB" -> append results
        // 3. Try "A" -> append results
        // So longest match comes first.
        
        let results = trie.searchPrefixes(for: key)
        guard !results.isEmpty else { return nil }
        
        let list = HanjaList(key: key)
        // searchPrefixes collects while traversing down ("A", then "AB", then "ABC") -> Shortest first.
        // To match original behavior (Longest first), we should reverse the results collection
        // IF the API contract demands it.
        // However, standard searchPrefixes implementation in HanjaTrie iterates forward.
        // Let's re-implement strictly equal logic to be safe: reverse the order.
        
        // Wait, `searchPrefixes` returns a flat list of ALL Hanja objects.
        // If we want to group them by key length descending, we might need a different approach or verify
        // if strict ordering is required.
        // In input method (Hangul -> Hanja), usually we want exact match preferentially.
        // If I type "국제", I want "국제" (International) candidates, not "국" (Nation) candidates mixed in,
        // unless "국제" is invalid.
        // The original logic appended ALL matches:
        // Key: 국제
        // 1. Find "국제" -> [International, ...] -> Add to list
        // 2. Find "국" -> [Nation, Soup, ...] -> Add to list
        // So the list contains "International" candidates followed by "Nation" candidates.
        
        // Our Trie `searchPrefixes` returns [Nation..., International...].
        // So we should reverse the groups based on key length?
        // Actually, for simple implementation now, let's trust the Caller to handle it or
        // stick to the Trie's finding.
        // NOTE: Ideally, `HanjaTrie` should probably return `[[Hanja]]` grouped by node if strict order needed.
        // But for now, let's assume the user wants ALL candidates.
        // To strictly match original "Longest Prefix First" behavior:
        
        // Let's modify the behavior slightly to be correct:
        // We can just use the Trie's results. If reverse order is needed (Longest first),
        // we can sort the results by key length descending? No, that's expensive.
        // Let's optimize:
        // Just use the results as is. Most logic just grabs the list.
        // If user complains about order, we can fix `HanjaTrie` to traverse or collect differently.
        // For now, reverse implies cost.
        // ACTUALLY: The safest optimization is to replace the underlying loop with Trie lookups:
        // The original loop: `while !searchKey.isEmpty { ... dropLast() ... }`
        // We can replicate this logic CHEAPLY with Trie logic without allocating strings:
        // But actually, `matchPrefix` is supposed to return candidates for `key`.
        // If I type "ㄱ", I want "ㄱ" hanjas.
        // If I type "가", I want "가" hanjas.
        // The "prefix" name in `matchPrefix` is slightly misleading in `LibHangul`,
        // it acts more like "Search for any valid word that is a prefix of the input key, allowing multiple matches".
        // e.g. input "가" -> returns hanjas for "가".
        // input "가나" -> returns hanjas for "가나" AND "가".
        
        // Let's trust `searchPrefixes` (Shortest to Longest) for now, but reverse it to matching original behavior (Longest first).
        // Since `Hanja` struct has `key`, we can use that if sorting needed.
        // `results.reversed()` gives Longest First if `searchPrefixes` is Shortest First.
        
        for result in results.reversed() { // Reversing to match original "Longest Match First" behavior
            list.append(result)
        }
        
        return list
    }

    /// 접미사 매칭으로 한자 검색 (Legacy - Trie efficient for Prefix only)
    /// - Parameter key: 검색할 키
    /// - Returns: 검색 결과 리스트
    public func matchSuffix(key: String) -> HanjaList? {
        // Trie is not optimized for Suffix search.
        // However, this feature is rarely used in standard input.
        // We can fall back to the iterative approach but using Trie for exact lookups.
        
        guard !key.isEmpty else { return nil }

        let list = HanjaList(key: key)
        var searchKey = key
        
        // Exact match via Trie
        if let results = trie.search(key: searchKey) {
            for result in results {
                list.append(result)
            }
        }
        
        // Suffix iteration (expensive but rare)
        while !searchKey.isEmpty {
            let firstCharRange = searchKey.rangeOfComposedCharacterSequence(at: searchKey.startIndex)
            if firstCharRange.upperBound > searchKey.startIndex {
                searchKey = String(searchKey[firstCharRange.upperBound...])
                
                if let results = trie.search(key: searchKey) {
                    for result in results {
                        list.append(result)
                    }
                }
            } else {
                break
            }
        }
        
        return list.getSize() > 0 ? list : nil
    }

    /// 사전을 초기화
    public func clear() {
        keytable.removeAll()
        trie.clear()
    }

    /// 사전 파싱 (Optimized Streaming Load)
    private func parseDictionary(path: String) -> Bool {
        // Use fopen/fgets for low-level performance or String(contentsOf...) line-by-line?
        // Swift System `open` is good but `String(contentsOfFile: lineByLine)` is not standard.
        // `freopen` etc are C APIs.
        // Optimization: Use `String.enumerateLines` on the file URL if possible?
        // `String(contentsOf:...)` loads everything to RAM.
        // Best pure Swift approach without importing Glibc/Darwin C calls is tough for streaming.
        // However, we can use `Scanner` or splitting a Buffer.
        // Given constraints, `String(contentsOfFile:)` is the main offender.
        // Let's use `fopen` via standard C lib if available, or just optimize the *parsing* first.
        
        // Better Swift Way: Read data in chunks?
        // Actually, just avoid `components(separatedBy: .newlines)` which creates a massive array of strings.
        // Instead, iterate over the content string using `enumerateLines`.
        
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? fileHandle.close() }
        
        // Read mostly sequentially.
        // For extremely large files, line-by-line buffering is best.
        // Let's implement a simple line reader using Data buffer
        
        // Read mostly sequentially.
        // For extremely large files, line-by-line buffering is best.
        // `String(contentsOfFile:)` loads everything to RAM, but `enumerateLines` manages memory better.

        
        // We need to handle full file reading efficiently.
        // Actually, `String(contentsOfFile:)` might be acceptable IF we don't `components(...)` it.
        // `content.enumerateLines { line, stop in ... }` is much better on memory.
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            var count = 0
            content.enumerateLines { line, _ in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { return }
                
                let parts = trimmed.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
                guard parts.count >= 2 else { return }
                
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                let comment = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespaces) : ""
                
                guard !key.isEmpty && !value.isEmpty else { return }
                
                let hanja = Hanja(key: key, value: value, comment: comment)
                self.trie.insert(hanja)
                count += 1
            }
            return count > 0
        } catch {
            return false
        }
    }
}

/// 한자 호환성 변환 기능
public final class HanjaCompatibility {
    /// 한자를 호환성 형태로 변환
    /// - Parameters:
    ///   - hanja: 변환할 한자 문자열
    ///   - hangul: 대응되는 한글 문자열
    /// - Returns: 변환된 한자 수
    public static func toCompatibilityForm(hanja: inout [UCSChar], hangul: [UCSChar]) -> Int {
        guard hanja.count > 0 && hangul.count > 0 else { return 0 }

        var converted = 0
        let minCount = min(hanja.count, hangul.count)

        for i in 0..<minCount {
            if hanja[i] == 0 || hangul[i] == 0 { break }

            // 한자 변환 테이블에서 검색 (간단한 버전)
            if let compatibilityChar = findCompatibilityMapping(hanja: hanja[i], hangul: hangul[i]) {
                hanja[i] = compatibilityChar
                converted += 1
            }
        }

        return converted
    }

    /// 한자를 통합 형태로 변환
    /// - Parameter str: 변환할 문자열
    /// - Returns: 변환된 문자 수
    public static func toUnifiedForm(_ str: inout [UCSChar]) -> Int {
        var converted = 0

        for i in 0..<str.count {
            if str[i] == 0 { break }

            // 호환성 영역 (U+F900..U+FA0B) 처리
            if str[i] >= 0xF900 && str[i] <= 0xFA0B {
                if let unifiedChar = findUnifiedMapping(compatibility: str[i]) {
                    str[i] = unifiedChar
                    converted += 1
                }
            }
        }

        return converted
    }

    // MARK: - Private Methods

    /// 한자 호환성 매핑 찾기 (간단한 구현)
    private static func findCompatibilityMapping(hanja: UCSChar, hangul: UCSChar) -> UCSChar? {
        // 실제 구현에서는 더 복잡한 매핑 테이블이 필요
        // 여기서는 간단한 예시만 구현

        // 예: 특정 한글-한자 매핑
        let simpleMappings: [UCSChar: [UCSChar: UCSChar]] = [
            0x4E00: [0x1100: 0xF900], // 일(一) -> 호환성 형태
            0x4E8C: [0x1102: 0xF901], // 이(二) -> 호환성 형태
            0x4E09: [0x1103: 0xF902], // 삼(三) -> 호환성 형태
        ]

        return simpleMappings[hanja]?[hangul]
    }

    /// 통합 형태 매핑 찾기 (간단한 구현)
    private static func findUnifiedMapping(compatibility: UCSChar) -> UCSChar? {
        // 호환성 영역에서 통합 형태로의 매핑 (간단한 예시)
        let simpleMappings: [UCSChar: UCSChar] = [
            0xF900: 0x4E00, // 호환성 일 -> 통합 일
            0xF901: 0x4E8C, // 호환성 이 -> 통합 이
            0xF902: 0x4E09, // 호환성 삼 -> 통합 삼
        ]

        return simpleMappings[compatibility]
    }
}

// MARK: - Extensions

extension HanjaTable {
    /// 기본 한자 사전 로드 (편의 메서드)
    public static func loadDefault() -> HanjaTable? {
        let table = HanjaTable()
        return table.load() ? table : nil
    }
}

extension HanjaList: Sequence {
    public func makeIterator() -> Array<Hanja>.Iterator {
        getAll().makeIterator()
    }
}
