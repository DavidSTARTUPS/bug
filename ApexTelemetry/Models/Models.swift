import Foundation

// MARK: - Subject Taxonomy
public enum Subject: String, Codable, CaseIterable, Identifiable {
    case matematica = "Matematica"
    case informatica = "Informatica"
    case romana = "Romana"
    case fizica = "Fizica"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .matematica: return "Matematică"
        case .informatica: return "Informatică"
        case .romana: return "Română"
        case .fizica: return "Fizică"
        }
    }
    
    public var iconName: String {
        switch self {
        case .matematica: return "function"
        case .informatica: return "chevron.left.forwardslash.chevron.right"
        case .romana: return "text.book.closed.fill"
        case .fizica: return "atom"
        }
    }
    
    public var subCategories: [String] {
        switch self {
        case .matematica:
            return [
                "Analiză Matematică (Derivate, Integrale, Limite, Asimptote)",
                "Algebră (Matrici, Determinanți, Grupuri, Inele Zn, Polinoame)",
                "Geometrie & Trigonometrie (Vectori, Drepte, Ecuații Trigo)"
            ]
        case .informatica:
            return [
                "Algoritmică & Grafuri/Arbori (BFS, DFS, Arbori tați, Heap)",
                "Șiruri de Caractere (cstring, char[], funcții C)",
                "Eficiență Fișiere O(1) (Subiectul III.3 streaming)",
                "C++ Low-Level & Sintaxă (Pointeri, Stivă, Operatori pe biți)"
            ]
        case .romana:
            return [
                "Subiectul I (Text la prima vedere, argumentare B)",
                "Subiectul II (Șabloane perspectivă, didascalii, idee poetică)",
                "Subiectul III (Eseu canonic, structură, formule magice)"
            ]
        case .fizica:
            return [
                "Mecanică",
                "Termodinamică",
                "Curent Continuu",
                "Optică"
            ]
        }
    }
    
    /// Returns a compact, user-friendly title for UI badges and filter chips
    public static func compactSubCategoryName(_ subCat: String) -> String {
        if let parenIndex = subCat.firstIndex(of: "(") {
            return String(subCat[..<parenIndex]).trimmingCharacters(in: .whitespaces)
        }
        return subCat
    }
}

// MARK: - Error Type Classification
public enum ErrorType: String, Codable, CaseIterable, Identifiable {
    case tipA = "Tip A" // Lacuna Teoretica (Formula / Teorema necunoscuta)
    case tipB = "Tip B" // Eroare Mecanica de Calcul (Semn, neatentie, derivare)
    case tipC = "Tip C" // Blocaj Euristic / Timp (Nerecunoasterea invariantului in 120s)
    
    public var id: String { rawValue }
    
    public var colorName: String {
        switch self {
        case .tipA: return "purple"
        case .tipB: return "amber"
        case .tipC: return "rose"
        }
    }
    
    public var label: String {
        switch self {
        case .tipA: return "Tip A • Lacună Teoretică"
        case .tipB: return "Tip B • Eroare Mecanică"
        case .tipC: return "Tip C • Blocaj Euristic"
        }
    }
    
    public var shortLabel: String {
        switch self {
        case .tipA: return "Lacună Teorie"
        case .tipB: return "Calcul Mecanic"
        case .tipC: return "Blocaj Euristic"
        }
    }
}

// MARK: - Bug Review Status
public enum BugStatus: String, Codable, CaseIterable, Identifiable {
    case pendingReview = "pending_review"
    case mastered = "mastered"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .pendingReview: return "Activ (Pending)"
        case .mastered: return "Stăpânit (Mastered)"
        }
    }
}

// MARK: - Core Bug Entry Model
public struct BugEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public var subject: Subject
    public var subCategory: String
    public var source: String // e.g. "Culegere UPB 2024 Grila 18" or "BAC 2023 Sub III.2"
    public var errorType: ErrorType
    public var bugDescription: String
    public var patch: String // Imperative mechanical rule
    public var invariant: String // Key formula or algorithmic invariant
    public var status: BugStatus
    public var reviewCount: Int
    public var lastReviewedAt: Date?
    
    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        subject: Subject,
        subCategory: String? = nil,
        source: String,
        errorType: ErrorType,
        bugDescription: String,
        patch: String,
        invariant: String,
        status: BugStatus = .pendingReview,
        reviewCount: Int = 0,
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.subject = subject
        self.subCategory = subCategory ?? (subject.subCategories.first ?? "")
        self.source = source
        self.errorType = errorType
        self.bugDescription = bugDescription
        self.patch = patch
        self.invariant = invariant
        self.status = status
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
    }
    
    public var isMastered: Bool {
        status == .mastered
    }
}

// MARK: - Telemetry Statistics
public struct TelemetryStats {
    public let totalCount: Int
    public let activeCount: Int
    public let masteredCount: Int
    public let tipACount: Int
    public let tipBCount: Int
    public let tipCCount: Int
    
    public var masteryPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return (Double(masteredCount) / Double(totalCount)) * 100.0
    }
    
    public init(entries: [BugEntry]) {
        self.totalCount = entries.count
        self.activeCount = entries.filter { $0.status == .pendingReview }.count
        self.masteredCount = entries.filter { $0.status == .mastered }.count
        self.tipACount = entries.filter { $0.errorType == .tipA }.count
        self.tipBCount = entries.filter { $0.errorType == .tipB }.count
        self.tipCCount = entries.filter { $0.errorType == .tipC }.count
    }
}
