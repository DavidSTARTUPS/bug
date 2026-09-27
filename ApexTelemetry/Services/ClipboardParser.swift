import Foundation

// MARK: - Draft Model for Prefilling Manual Entry
public struct BugEntryDraft: Equatable {
    public var subject: Subject
    public var subCategory: String
    public var source: String
    public var errorType: ErrorType
    public var bugDescription: String
    public var patch: String
    public var invariant: String
    
    public init(
        subject: Subject = .matematica,
        subCategory: String? = nil,
        source: String = "",
        errorType: ErrorType = .tipA,
        bugDescription: String = "",
        patch: String = "",
        invariant: String = ""
    ) {
        self.subject = subject
        self.subCategory = subCategory ?? (subject.subCategories.first ?? "")
        self.source = source
        self.errorType = errorType
        self.bugDescription = bugDescription
        self.patch = patch
        self.invariant = invariant
    }
    
    public func toBugEntry() -> BugEntry {
        BugEntry(
            subject: subject,
            subCategory: subCategory,
            source: source.trimmingCharacters(in: .whitespacesAndNewlines),
            errorType: errorType,
            bugDescription: bugDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            patch: patch.trimmingCharacters(in: .whitespacesAndNewlines),
            invariant: invariant.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Parse Result Status
public enum ParseResult {
    case success(BugEntry)
    case partial(prefilled: BugEntryDraft, reason: String)
    case empty
}

// MARK: - Smart Clipboard Ingestion Engine
public struct ClipboardParser {
    
    public static func parse(rawText: String?) -> ParseResult {
        guard let text = rawText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return .empty
        }
        
        // 1. Try structured JSON first
        if let jsonResult = tryParseJSON(text) {
            return jsonResult
        }
        
        // 2. Try Markdown / Structured Text parsing
        return parseMarkdown(text)
    }
    
    // MARK: - JSON Decoding Strategy
    private static func tryParseJSON(_ text: String) -> ParseResult? {
        // Strip markdown code fences if present (e.g. ```json ... ```)
        var cleaned = text
        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: .newlines)
            if lines.count >= 2 {
                cleaned = lines.dropFirst().dropLast().joined(separator: "\n")
            }
        }
        
        guard cleaned.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") else {
            return nil
        }
        
        guard let data = cleaned.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Extract Subject
        let rawSubject = (dict["subject"] as? String) ?? (dict["materie"] as? String) ?? ""
        let subject = resolveSubject(from: rawSubject)
        
        // Extract SubCategory
        let rawSubCategory = (dict["subCategory"] as? String)
            ?? (dict["sub_category"] as? String)
            ?? (dict["subcategorie"] as? String)
            ?? (dict["subcategory"] as? String)
            ?? ""
        let subCategory = resolveSubCategory(for: subject, rawText: rawSubCategory)
        
        // Extract ErrorType
        let rawError = (dict["errorType"] as? String)
            ?? (dict["error_type"] as? String)
            ?? (dict["clasificare"] as? String)
            ?? (dict["tip"] as? String)
            ?? ""
        let errorType = resolveErrorType(from: rawError)
        
        let source = (dict["source"] as? String) ?? (dict["sursa"] as? String) ?? ""
        let bug = (dict["bugDescription"] as? String) ?? (dict["bug"] as? String) ?? (dict["descriere"] as? String) ?? ""
        let patch = (dict["patch"] as? String) ?? (dict["solutie"] as? String) ?? ""
        let invariant = (dict["invariant"] as? String) ?? (dict["formula"] as? String) ?? ""
        
        let draft = BugEntryDraft(
            subject: subject,
            subCategory: subCategory,
            source: source,
            errorType: errorType,
            bugDescription: bug,
            patch: patch,
            invariant: invariant
        )
        
        // Check if all essential fields are present
        if !bug.isEmpty && !patch.isEmpty && !invariant.isEmpty {
            return .success(draft.toBugEntry())
        } else {
            return .partial(prefilled: draft, reason: "Câmpuri parțiale extrase din JSON.")
        }
    }
    
    // MARK: - Markdown & Key-Value Parsing Strategy
    private static func parseMarkdown(_ text: String) -> ParseResult {
        // Normalize text line endings
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        // 1. Extract Subject
        let rawSubject = extractRegexMatch(
            pattern: #"(?i)(?:Materie|Subject|Disciplina):\s*([^\n\r]+)"#,
            in: normalized
        ) ?? ""
        let subject = resolveSubject(from: rawSubject.isEmpty ? normalized : rawSubject)
        
        // 2. Extract SubCategory
        let rawSubCategory = extractRegexMatch(
            pattern: #"(?i)(?:Subcategorie|Sub-categorie|Subcategory|Topic|Subiect):\s*([^\n\r]+)"#,
            in: normalized
        ) ?? ""
        let subCategory = resolveSubCategory(for: subject, rawText: rawSubCategory.isEmpty ? normalized : rawSubCategory)
        
        // 3. Extract ErrorType
        let rawError = extractRegexMatch(
            pattern: #"(?i)(?:Clasificare|Classification|Tip|ErrorType):\s*([^\n\r]+)"#,
            in: normalized
        ) ?? ""
        let errorType = resolveErrorType(from: rawError.isEmpty ? normalized : rawError)
        
        // 4. Extract Source
        let source = extractRegexMatch(
            pattern: #"(?i)(?:Sursă|Sursa|Source|Origine|Problema):\s*([^\n\r]+)"#,
            in: normalized
        ) ?? ""
        
        // 5. Extract Bug Description
        let bug = extractSectionMatch(
            primaryHeader: #"(?i)(?:###\s*)?(?:🔴\s*)?Bug(?:\s*Description|\s*Descriere)?:\s*"#,
            nextHeaders: [#"(?i)(?:###\s*)?Patch:"#, #"(?i)(?:###\s*)?Invariant:"#, #"(?i)(?:###\s*)?Solutie:"#],
            in: normalized
        )
        
        // 6. Extract Patch
        let patch = extractSectionMatch(
            primaryHeader: #"(?i)(?:###\s*)?(?:🟢\s*)?Patch(?:\s*Mecanic|\s*Rule)?:\s*"#,
            nextHeaders: [#"(?i)(?:###\s*)?Invariant:"#, #"(?i)(?:###\s*)?Teorema:"#],
            in: normalized
        )
        
        // 7. Extract Invariant
        let invariant = extractSectionMatch(
            primaryHeader: #"(?i)(?:###\s*)?(?:🔷\s*)?Invariant(?:\s*Matematic|\s*Algoritmic)?:\s*"#,
            nextHeaders: [#"(?i)(?:###\s*)?Sursa:"#, #"(?i)(?:###\s*)?Status:"#],
            in: normalized
        )
        
        let draft = BugEntryDraft(
            subject: subject,
            subCategory: subCategory,
            source: source,
            errorType: errorType,
            bugDescription: bug,
            patch: patch,
            invariant: invariant
        )
        
        // Validation: If both bug and patch exist, we have a viable auto-ingested log
        if !bug.isEmpty && !patch.isEmpty {
            let finalInvariant = invariant.isEmpty ? "Invariant nespecificat" : invariant
            let finalSource = source.isEmpty ? "Clipboard Log" : source
            
            var entry = draft.toBugEntry()
            entry.invariant = finalInvariant
            entry.source = finalSource
            return .success(entry)
        }
        
        // If some text was provided but missing core fields, return draft with partial note
        if !bug.isEmpty || !patch.isEmpty || !source.isEmpty {
            return .partial(prefilled: draft, reason: "Unele câmpuri necesită completare manuală.")
        }
        
        // If no structured pattern matched at all, dump entire text into bug description
        var fallbackDraft = BugEntryDraft()
        fallbackDraft.bugDescription = normalized
        return .partial(prefilled: fallbackDraft, reason: "Text nestructurat; te rugăm să verifici câmpurile.")
    }
    
    // MARK: - Normalization Helpers
    public static func resolveSubject(from raw: String) -> Subject {
        let lower = raw.lowercased()
        if lower.contains("mate") || lower.contains("math") || lower.contains("analiz") || lower.contains("algeb") || lower.contains("geomet") {
            return .matematica
        } else if lower.contains("info") || lower.contains("cs") || lower.contains("c++") || lower.contains("graf") || lower.contains("algoritm") {
            return .informatica
        } else if lower.contains("roman") || lower.contains("eseu") || lower.contains("comentariu") || lower.contains("bac") && lower.contains("sub") {
            return .romana
        } else if lower.contains("fizic") || lower.contains("phys") || lower.contains("mecanic") || lower.contains("termodinam") || lower.contains("optic") {
            return .fizica
        }
        return .matematica
    }
    
    public static func resolveSubCategory(for subject: Subject, rawText: String) -> String {
        let lower = rawText.lowercased()
        let available = subject.subCategories
        
        for candidate in available {
            let candLower = candidate.lowercased()
            // Check direct match
            if lower.contains(candLower) {
                return candidate
            }
            // Check compact title
            let compact = Subject.compactSubCategoryName(candidate).lowercased()
            if lower.contains(compact) {
                return candidate
            }
        }
        
        // Fuzzy keywords per subject
        switch subject {
        case .matematica:
            if lower.contains("analiz") || lower.contains("derivat") || lower.contains("integr") || lower.contains("limit") || lower.contains("hopital") || lower.contains("asimptot") {
                return available[0]
            }
            if lower.contains("algeb") || lower.contains("matric") || lower.contains("determinan") || lower.contains("grup") || lower.contains("inel") || lower.contains("polinom") {
                return available[1]
            }
            if lower.contains("geom") || lower.contains("trigo") || lower.contains("vector") || lower.contains("dreapt") || lower.contains("sin") || lower.contains("cos") {
                return available[2]
            }
        case .informatica:
            if lower.contains("graf") || lower.contains("arbor") || lower.contains("bfs") || lower.contains("dfs") || lower.contains("heap") || lower.contains("algoritm") {
                return available[0]
            }
            if lower.contains("sir") || lower.contains("string") || lower.contains("cstring") || lower.contains("char") {
                return available[1]
            }
            if lower.contains("eficient") || lower.contains("o(1)") || lower.contains("stream") || lower.contains("subiectul iii.3") || lower.contains("frecvent") {
                return available[2]
            }
            if lower.contains("pointer") || lower.contains("stiv") || lower.contains("bit") || lower.contains("c++") || lower.contains("sintax") {
                return available[3]
            }
        case .romana:
            if lower.contains("subiectul i") || lower.contains("sub i") || lower.contains("argumentar") {
                return available[0]
            }
            if lower.contains("subiectul ii") || lower.contains("sub ii") || lower.contains("perspectiv") || lower.contains("didascal") || lower.contains("poetic") {
                return available[1]
            }
            if lower.contains("subiectul iii") || lower.contains("sub iii") || lower.contains("eseu") || lower.contains("canonic") || lower.contains("ion") || lower.contains("plumb") {
                return available[2]
            }
        case .fizica:
            if lower.contains("mecanic") || lower.contains("fort") || lower.contains("viteza") {
                return available[0]
            }
            if lower.contains("termo") || lower.contains("gaz") || lower.contains("cald") {
                return available[1]
            }
            if lower.contains("curent") || lower.contains("circuit") || lower.contains("kirchhoff") || lower.contains("ohm") {
                return available[2]
            }
            if lower.contains("optic") || lower.contains("lentil") || lower.contains("refract") {
                return available[3]
            }
        }
        
        return available.first ?? ""
    }
    
    public static func resolveErrorType(from raw: String) -> ErrorType {
        let lower = raw.lowercased()
        if lower.contains("tip a") || lower.contains("tipa") || lower.contains("teoretic") || lower.contains("lacuna") || lower.contains("formula") {
            return .tipA
        } else if lower.contains("tip b") || lower.contains("tipb") || lower.contains("mecanic") || lower.contains("calcul") || lower.contains("semn") || lower.contains("neatentie") {
            return .tipB
        } else if lower.contains("tip c") || lower.contains("tipc") || lower.contains("euristic") || lower.contains("blocaj") || lower.contains("timp") || lower.contains("120s") {
            return .tipC
        }
        return .tipA
    }
    
    // MARK: - Regex Match Utilities
    private static func extractRegexMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        if match.numberOfRanges > 1 {
            let captureRange = match.range(at: 1)
            if captureRange.location != NSNotFound {
                return nsString.substring(with: captureRange).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    private static func extractSectionMatch(primaryHeader: String, nextHeaders: [String], in text: String) -> String {
        guard let primaryRegex = try? NSRegularExpression(pattern: primaryHeader, options: []) else { return "" }
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        guard let primaryMatch = primaryRegex.firstMatch(in: text, options: [], range: fullRange) else {
            return ""
        }
        
        let startLocation = primaryMatch.range.location + primaryMatch.range.length
        var endLocation = nsString.length
        
        for nextHeader in nextHeaders {
            if let nextRegex = try? NSRegularExpression(pattern: nextHeader, options: []) {
                let searchRange = NSRange(location: startLocation, length: nsString.length - startLocation)
                if let nextMatch = nextRegex.firstMatch(in: text, options: [], range: searchRange) {
                    if nextMatch.range.location < endLocation {
                        endLocation = nextMatch.range.location
                    }
                }
            }
        }
        
        let sectionRange = NSRange(location: startLocation, length: max(0, endLocation - startLocation))
        let extracted = nsString.substring(with: sectionRange)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return extracted
    }
}
