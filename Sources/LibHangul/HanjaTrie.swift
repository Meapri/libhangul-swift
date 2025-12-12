//
//  HanjaTrie.swift
//  LibHangul
//
//  Created for Hanja Engine Optimization
//

import Foundation

/// Trie Node structure for Flat Array Trie
/// Optimized to avoid heap allocation per node.
struct HanjaTrieNode {
    /// Hanja entries indices in the value storage
    var valueIndices: [Int] = []
    
    /// Child nodes map: Character -> Index in `nodes` array
    var children: [Character: Int] = [:]
}

/// A specialized Trie data structure for storing and retrieving Hanja entries.
///
/// **Optimization Note**:
/// This implementation uses a **Flat Array Trie** structure.
/// Instead of allocating a `class` object for every node (which causes massive heap overhead and slower ARC),
/// we store `struct` nodes in a single contiguous array.
/// - **Memory**: Significantly reduced overhead (value type vs reference type).
/// - **Performance**: Better cache locality and reduced GC/RC pressure.
public final class HanjaTrie {
    /// Flat storage for all nodes. Index 0 is root.
    private var nodes: [HanjaTrieNode] = []
    
    /// Centralized storage for all Hanja values (nodes store indices only)
    private var allHanjaValues: [Hanja] = []
    
    /// The root node is always at index 0.
    public init() {
        // Initialize with root node
        nodes.append(HanjaTrieNode())
    }
    
    /// Insert a Hanja entry into the Trie
    public func insert(_ hanja: Hanja) {
        var currentNodeIndex = 0
        
        for char in hanja.key {
            // Need to mutate the array, so we must be careful with CoW or indices.
            // Since we append to `nodes`, existing indices might ideally stay stable if we just append.
            // Accessing `nodes[currentNodeIndex]` directly.
            
            if let childIndex = nodes[currentNodeIndex].children[char] {
                currentNodeIndex = childIndex
            } else {
                // Create new node
                let newNodeIndex = nodes.count
                nodes.append(HanjaTrieNode())
                
                // Link parent to new child.
                // Note: Re-access `nodes[currentNodeIndex]` because `nodes` might have been reallocated by append.
                nodes[currentNodeIndex].children[char] = newNodeIndex
                
                currentNodeIndex = newNodeIndex
            }
        }
        
        // Add value to the leaf node
        // Store the actual Hanja in a centralized array and keep the index in the node
        let valueIndex = allHanjaValues.count
        allHanjaValues.append(hanja)
        nodes[currentNodeIndex].valueIndices.append(valueIndex)
    }
    
    /// Search for exact match
    /// - Parameter key: The key to search for
    /// - Returns: List of Hanja entries or nil if not found
    public func search(key: String) -> [Hanja]? {
        guard let nodeIndex = findNodeIndex(key: key) else { return nil }
        
        let indices = nodes[nodeIndex].valueIndices
        if indices.isEmpty { return nil }
        
        return indices.map { allHanjaValues[$0] }
    }
    
    /// Search for all entries matching the prefix
    /// Optimized for memory and lookups.
    public func searchPrefixes(for key: String) -> [Hanja] {
        var results: [Hanja] = []
        var currentNodeIndex = 0
        
        for char in key {
            guard let childIndex = nodes[currentNodeIndex].children[char] else {
                break 
            }
            currentNodeIndex = childIndex
            
            // Collect values at this node
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
            guard let childIndex = nodes[currentNodeIndex].children[char] else {
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
        // Reinstate root
        nodes.append(HanjaTrieNode())
    }
    
    public var isEmpty: Bool {
        // Root is always present, check if it has children
        nodes[0].children.isEmpty
    }
}
