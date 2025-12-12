//
//  HanjaTrie.swift
//  LibHangul
//
//  Hanja Trie 최적화 - Sorted Array + Binary Search
//

import Foundation

/// Trie Node structure using Sorted Arrays
/// 
/// **최적화 설명**:
/// Dictionary 대신 정렬된 배열 + 이진 탐색을 사용하여:
/// - 해싱 오버헤드 제거
/// - 더 나은 캐시 지역성 (연속 메모리)
/// - CoW 복사 비용 감소
struct HanjaTrieNode {
    /// Hanja entries indices in the value storage
    var valueIndices: [Int] = []
    
    /// 자식 노드 키 (정렬됨)
    var childKeys: [Character] = []
    /// 자식 노드 인덱스 (childKeys와 병렬)
    var childIndices: [Int] = []
    
    /// Binary search로 자식 찾기
    @inlinable
    func findChild(_ char: Character) -> Int? {
        var low = 0
        var high = childKeys.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let midChar = childKeys[mid]
            
            if midChar == char {
                return childIndices[mid]
            } else if midChar < char {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return nil
    }
    
    /// 자식 추가 (정렬 유지)
    @inlinable
    mutating func addChild(_ char: Character, index: Int) {
        // 삽입 위치 찾기 (이진 탐색)
        var insertIndex = 0
        var low = 0
        var high = childKeys.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            if childKeys[mid] < char {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        insertIndex = low
        
        childKeys.insert(char, at: insertIndex)
        childIndices.insert(index, at: insertIndex)
    }
}

/// A specialized Trie data structure for storing and retrieving Hanja entries.
///
/// **Optimization Note**:
/// This implementation uses **Sorted Arrays + Binary Search** instead of Dictionary.
/// - **No Hashing Overhead**: Direct comparison instead of hash computation.
/// - **Better Cache Locality**: Contiguous memory layout.
/// - **Reduced CoW Cost**: Smaller data structures copy faster.
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
                nodes[currentNodeIndex].addChild(char, index: newNodeIndex)
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
        nodes[0].childKeys.isEmpty
    }
}
