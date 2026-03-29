//
//  ReadHistory.swift
//  hnr-reader
//

import Foundation

@Observable
final class ReadHistory {
    static let shared = ReadHistory()

    private let key = "readStoryIDs"
    private(set) var readIDs: Set<Int>

    private init() {
        let stored = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        readIDs = Set(stored)
    }

    func markRead(_ id: Int) {
        guard !readIDs.contains(id) else { return }
        readIDs.insert(id)
        // Keep a reasonable cap to avoid unbounded growth
        if readIDs.count > 5000 {
            let sorted = readIDs.sorted()
            readIDs = Set(sorted.suffix(3000))
        }
        UserDefaults.standard.set(Array(readIDs), forKey: key)
    }

    func isRead(_ id: Int) -> Bool {
        readIDs.contains(id)
    }

    func clear() {
        readIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: key)
    }
}
