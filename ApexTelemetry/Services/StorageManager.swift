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
        if entries.isEmpty {
            // Pre-seed initial high-yield example bugs if first launch
            loadSampleData()
        }
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
    
    // MARK: - High-Yield Romanian STEM Exam Sample Data
    public func loadSampleData() {
        let samples: [BugEntry] = [
            BugEntry(
                subject: .matematica,
                subCategory: "Analiză Matematică (Derivate, Integrale, Limite, Asimptote)",
                source: "UPB Admitere 2024 - Grila 14",
                errorType: .tipA,
                bugDescription: "Am aplicat direct Teorema lui L'Hopital pe o limită cu forma nedeterminată 0 * ∞ fără a o transforma într-o fracție.",
                patch: "Nu aplica L'Hopital pe produs! Rescrie f(x)*g(x) ca f(x)/(1/g(x)) pentru a obține strict 0/0 sau ∞/∞ înainte de derivare.",
                invariant: "lim_{x->a} [f(x)/g(x)] = lim_{x->a} [f'(x)/g'(x)] este validă STRICT când f, g -> 0 sau f, g -> ±∞ și g'(x) != 0 pe o vecinătate.",
                status: .pendingReview,
                reviewCount: 1,
                lastReviewedAt: Date().addingTimeInterval(-86400 * 2)
            ),
            BugEntry(
                subject: .matematica,
                subCategory: "Algebră (Matrici, Determinanți, Grupuri, Inele Zn, Polinoame)",
                source: "BAC 2023 Subiectul II.1",
                errorType: .tipB,
                bugDescription: "La calculul determinantului unei matrici de ordin 3, am greșit semnul cofactorului (-1)^{i+j} la dezvoltarea pe linia a 2-a.",
                patch: "Marchează mental tabla de șah a semnelor pentru determinanți (+ - + / - + - / + - +) înainte de a înmulți minorii complementari.",
                invariant: "det(A) = sum_{j=1}^n (-1)^{i+j} * a_{ij} * det(M_{ij}). La poziția (2,1), semnul este strict negativ (-1)^3 = -1.",
                status: .pendingReview,
                reviewCount: 0
            ),
            BugEntry(
                subject: .informatica,
                subCategory: "Eficiență Fișiere O(1) (Subiectul III.3 streaming)",
                source: "BAC 2022 Subiectul III.3",
                errorType: .tipC,
                bugDescription: "Blocaj euristic: am încercat să stochez toate cele 1.000.000 de numere dintr-un fișier într-un tablou alocat static și am depășit memoria.",
                patch: "La Subiectul III.3 eficiență memorie O(1): nu aloca vectori! Citește fluxul element cu element (while(fin >> x)) și menține doar 2-3 variabile de stare / frecvență.",
                invariant: "Complexitate memorie O(1) impune spațiu auxiliar independent de N. Orice stocare globală a secvenței de intrare primește 0 puncte pe eficiență.",
                status: .pendingReview,
                reviewCount: 2,
                lastReviewedAt: Date().addingTimeInterval(-86400)
            ),
            BugEntry(
                subject: .informatica,
                subCategory: "Șiruri de Caractere (cstring, char[], funcții C)",
                source: "Simulare BAC 2024 Subiectul II.3",
                errorType: .tipB,
                bugDescription: "Am folosit strcpy(s, s + 1) pentru a șterge primul caracter dintr-un șir, provocând comportament nedefinit (overlap de memorie).",
                patch: "Nu folosi niciodată strcpy pe zone de memorie care se suprapun! Folosește un pointer de deplasare sau memmove / buclă for manuală.",
                invariant: "strcpy presupune regiuni de memorie disjuncte (src și dest nu se pot suprapune). Suprapunerea duce la coruperea terminatorului '\\0'.",
                status: .mastered,
                reviewCount: 3,
                lastReviewedAt: Date().addingTimeInterval(-86400 * 4)
            ),
            BugEntry(
                subject: .romana,
                subCategory: "Subiectul II (Șabloane perspectivă, didascalii, idee poetică)",
                source: "BAC 2023 Subiectul II",
                errorType: .tipA,
                bugDescription: "Am confundat perspectiva narativă 'obiectivă' (dindărăt) cu perspectiva 'subiectivă' (împreună cu) din cauza prezenței dialogului.",
                patch: "Focalizarea se determină EXCLUSIV după verbele și pronumele narațiunii (vocea naratorului), NU după replicile personajelor din dialog!",
                invariant: "Perspectivă narativă obiectivă = narator omniscient, omniprezent, neimplicat, narațiune la persoana a III-a (heterodiegetic).",
                status: .mastered,
                reviewCount: 4,
                lastReviewedAt: Date().addingTimeInterval(-86400 * 5)
            ),
            BugEntry(
                subject: .fizica,
                subCategory: "Curent Continuu",
                source: "UPB Fizica 2023 - Grila 8",
                errorType: .tipB,
                bugDescription: "La scrierea teoremei a II-a a lui Kirchhoff pe ochiul de rețea, am omis rezistența internă 'r' a sursei reale.",
                patch: "Tratează orice sursă reală ca pe un dipol compus dintr-o sursă ideală E în serie cu un rezistor r: E = I * (R + r).",
                invariant: "sum_{k} E_k = sum_{j} I_j * (R_j + r_j). Tensiunea la bornele sursei în sarcină este U = E - I * r.",
                status: .pendingReview,
                reviewCount: 0
            )
        ]
        
        self.entries = samples
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
