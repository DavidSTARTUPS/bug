import Foundation

// MARK: - Native Storage Manager
public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    
    private let fileName = "bug_log.json"
    private let fileManager = FileManager.default
    
    @Published public private(set) var entries: [BugEntry] = []
    
    private var fileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    public init() {
        loadEntries()
    }
    
    // MARK: - Core Persistence
    public func loadEntries() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            self.entries = []
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try jsonDecoder.decode([BugEntry].self, from: data)
            // Sort by creation date descending (newest first)
            self.entries = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("⚠️ [StorageManager] Failed to decode existing bug_log.json: \(error)")
            // Fallback attempt: lenient decoder with secondary date strategies
            if let fallbackEntries = tryFallbackDecode(from: fileURL) {
                self.entries = fallbackEntries.sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }
    
    public func saveEntries() {
        do {
            let data = try jsonEncoder.encode(entries)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ [StorageManager] Failed to write bug_log.json: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    public func addEntry(_ entry: BugEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    public func updateEntry(_ entry: BugEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    public func deleteEntry(withId id: UUID) {
        entries.removeAll(where: { $0.id == id })
        saveEntries()
    }
    
    public func toggleMastered(withId id: UUID) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            let current = entries[index].status
            entries[index].status = (current == .mastered) ? .pendingReview : .mastered
            entries[index].lastReviewedAt = Date()
            saveEntries()
        }
    }
    
    public func recordDrillResult(id: UUID, mastered: Bool) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].status = mastered ? .mastered : .pendingReview
            entries[index].reviewCount += 1
            entries[index].lastReviewedAt = Date()
            saveEntries()
        }
    }
    
    // MARK: - Export & Import
    public func exportFileURL() -> URL? {
        // Save current in-memory state before export
        saveEntries()
        return fileURL
    }
    
    public func exportRawJSON() -> String? {
        guard let data = try? jsonEncoder.encode(entries) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    public func importJSON(from sourceURL: URL, replaceExisting: Bool) throws -> Int {
        let isAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing { sourceURL.stopAccessingSecurityScopedResource() }
        }
        
        let data = try Data(contentsOf: sourceURL)
        let imported = try jsonDecoder.decode([BugEntry].self, from: data)
        
        if replaceExisting {
            self.entries = imported.sorted(by: { $0.createdAt > $1.createdAt })
        } else {
            // Merge deduplicating by ID
            var currentMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
            for item in imported {
                currentMap[item.id] = item
            }
            self.entries = Array(currentMap.values).sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        saveEntries()
        return imported.count
    }
    
    public func clearAll() {
        self.entries = []
        saveEntries()
    }
    
    // MARK: - Private Fallbacks
    private func tryFallbackDecode(from url: URL) -> [BugEntry]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let customDecoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        customDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try? customDecoder.decode([BugEntry].self, from: data)
    }
}
