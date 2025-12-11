//
//  HanjaTrie.swift
//  LibHangul
//
//  Created for Hanja Engine Optimization
//

import Foundation

/// Trie Node class for Hanja dictionary
final class HanjaTrieNode {
    /// Hanja entries at this node (can be multiple for the same key)
    var values: [Hanja] = []
    
    /// Child nodes mapped by character
    var children: [Character: HanjaTrieNode] = [:]
}

/// A specialized Trie data structure for storing and retrieving Hanja entries.
///
/// Advantages over Hash Map:
/// - **Prefix Search**: O(m) where m is prefix length. No need to iterate or slice strings.
/// - **Memory**: Shared prefixes reduce storage redundancy compared to storing full string keys.
public final class HanjaTrie {
    private let root = HanjaTrieNode()
    
    public init() {}
    
    /// Insert a Hanja entry into the Trie
    public func insert(_ hanja: Hanja) {
        var currentNode = root
        for char in hanja.key {
            if let child = currentNode.children[char] {
                currentNode = child
            } else {
                let newNode = HanjaTrieNode()
                currentNode.children[char] = newNode
                currentNode = newNode
            }
        }
        currentNode.values.append(hanja)
    }
    
    /// Search for exact match
    /// - Parameter key: The key to search for
    /// - Returns: List of Hanja entries or nil if not found
    public func search(key: String) -> [Hanja]? {
        guard let node = findNode(key: key) else { return nil }
        return node.values.isEmpty ? nil : node.values
    }
    
    /// Search for all entries matching the prefix
    /// - Parameter prefix: The prefix to search for
    /// - Returns: A flat list of ALL Hanja entries that start with this prefix (including exact match)
    /// - Note: In Hanja input context, "prefix match" usually means "find the longest matching prefix" logic
    ///         handled by the caller. If you literally mean "all words starting with...", this does traversal.
    ///         However, for Hanja conversion, we usually iterate backwards or scan used `HanjaTable.matchPrefix`.
    ///         Since `HanjaTable.matchPrefix` logic was "find exact matches for successively shorter prefixes",
    ///         the Trie directly supports this without string slicing by simple traversal logic.
    private func findNode(key: String) -> HanjaTrieNode? {
        var currentNode = root
        for char in key {
            guard let child = currentNode.children[char] else {
                return nil
            }
            currentNode = child
        }
        return currentNode
    }
    
    /// Optimized Prefix Matching for Hanja Conversion
    ///
    /// This replicates the behavior of `HanjaTable.matchPrefix` but excessively faster.
    /// It traverses the Trie with the key. At each step, if a valid node exists and has values,
    /// those values are candidates.
    ///
    /// - Parameter key: The full key to check
    /// - Returns: A list of ALL valid Hanja matches found along the path of the key.
    ///            (e.g. key="국제연합", finds "국", "국제", "국제연합" if they exist)
    public func searchPrefixes(for key: String) -> [Hanja] {
        var results: [Hanja] = []
        var currentNode = root
        
        // This traverses the key and collects ANY valid word formed by a prefix of the key.
        // NOTE: The original matchPrefix logic was "try full key, then drop last, try again...".
        // This is equivalent to walking down the Trie and collecting results at each node.
        
        for char in key {
            guard let child = currentNode.children[char] else {
                break // No more longer prefixes exist
            }
            currentNode = child
            if !currentNode.values.isEmpty {
                results.append(contentsOf: currentNode.values)
            }
        }
        
        return results
    }
    
    /// Clears the Trie
    public func clear() {
        root.children.removeAll()
        root.values.removeAll()
    }
    
    public var isEmpty: Bool {
        root.children.isEmpty
    }
}
