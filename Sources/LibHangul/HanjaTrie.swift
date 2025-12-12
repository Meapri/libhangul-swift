//
//  HanjaTrie.swift
//  LibHangul
//
//  Hanja Trie 최적화 - Sorted Array + Binary Search
//

import Foundation

/// 자식 노드 엔트리 (단일 배열을 위한 구조체)
/// 두 개의 배열 대신 하나의 구조체 배열로 힙 할당 횟수 절반으로 감소
@usableFromInline
struct TrieChildEntry: Comparable {
    @usableFromInline let key: Character
    @usableFromInline let index: Int
    
    @usableFromInline
    init(key: Character, index: Int) {
        self.key = key
        self.index = index
    }
    
    @inlinable
    static func < (lhs: TrieChildEntry, rhs: TrieChildEntry) -> Bool {
        lhs.key < rhs.key
    }
}

/// Trie Node structure using Single Sorted Array
/// 
/// **최적화 설명**:
/// - `childKeys`와 `childIndices` 두 배열을 `children: [TrieChildEntry]` 단일 배열로 통합
/// - 노드당 2번의 힙 할당을 1번으로 감소
/// - 더 나은 캐시 지역성 (key와 index가 인접)
struct HanjaTrieNode {
    /// Hanja entries indices in the value storage
    var valueIndices: [Int] = []
    
    /// 자식 노드 (정렬됨) - 단일 배열로 힙 할당 최소화
    var children: [TrieChildEntry] = []
    
    /// Binary search로 자식 찾기
    @inlinable
    func findChild(_ char: Character) -> Int? {
        var low = 0
        var high = children.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let midKey = children[mid].key
            
            if midKey == char {
                return children[mid].index
            } else if midKey < char {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return nil
    }
    
    /// 자식 추가 (정렬 유지)
    @inlinable
    mutating func addChild(_ char: Character, nodeIndex: Int) {
        // 삽입 위치 찾기 (이진 탐색)
        var low = 0
        var high = children.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            if children[mid].key < char {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        children.insert(TrieChildEntry(key: char, index: nodeIndex), at: low)
    }
}

/// A specialized Trie data structure for storing and retrieving Hanja entries.
///
/// **Optimization Note**:
/// - **Sorted Array + Binary Search**: No hashing overhead.
/// - **Single Child Array**: `TrieChildEntry` struct merges key/index into one array.
/// - **Reduced Heap Allocations**: From 2N to N allocations per node.
public final class HanjaTrie {
    /// Flat storage for all nodes. Index 0 is root.
    private var nodes: [HanjaTrieNode] = []
    
    /// Centralized storage for all Hanja values (nodes store indices only)
    private var allHanjaValues: [Hanja] = []
    
    /// The root node is always at index 0.
    public init() {
        nodes.append(HanjaTrieNode())
    }
    
    /// Insert a Hanja entry into the Trie
    public func insert(_ hanja: Hanja) {
        var currentNodeIndex = 0
        
        for char in hanja.key {
            if let childIndex = nodes[currentNodeIndex].findChild(char) {
                currentNodeIndex = childIndex
            } else {
                let newNodeIndex = nodes.count
                nodes.append(HanjaTrieNode())
                nodes[currentNodeIndex].addChild(char, nodeIndex: newNodeIndex)
                currentNodeIndex = newNodeIndex
            }
        }
        
        let valueIndex = allHanjaValues.count
        allHanjaValues.append(hanja)
        nodes[currentNodeIndex].valueIndices.append(valueIndex)
    }
    
    /// Search for exact match
    public func search(key: String) -> [Hanja]? {
        guard let nodeIndex = findNodeIndex(key: key) else { return nil }
        
        let indices = nodes[nodeIndex].valueIndices
        if indices.isEmpty { return nil }
        
        return indices.map { allHanjaValues[$0] }
    }
    
    /// Search for all entries matching the prefix
    public func searchPrefixes(for key: String) -> [Hanja] {
        var results: [Hanja] = []
        var currentNodeIndex = 0
        
        for char in key {
            guard let childIndex = nodes[currentNodeIndex].findChild(char) else {
                break
            }
            currentNodeIndex = childIndex
            
            let indices = nodes[currentNodeIndex].valueIndices
            if !indices.isEmpty {
                results.append(contentsOf: indices.map { allHanjaValues[$0] })
            }
        }
        
        return results
    }
    
    private func findNodeIndex(key: String) -> Int? {
        var currentNodeIndex = 0
        for char in key {
            guard let childIndex = nodes[currentNodeIndex].findChild(char) else {
                return nil
            }
            currentNodeIndex = childIndex
        }
        return currentNodeIndex
    }
    
    /// Clears the Trie
    public func clear() {
        nodes.removeAll(keepingCapacity: false)
        allHanjaValues.removeAll(keepingCapacity: false)
        nodes.append(HanjaTrieNode())
    }
    
    public var isEmpty: Bool {
        nodes[0].children.isEmpty
    }
}
