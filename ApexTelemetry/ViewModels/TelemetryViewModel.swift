import SwiftUI
import Combine
import UIKit

// MARK: - Central Telemetry ViewModel
@MainActor
public final class TelemetryViewModel: ObservableObject {
    @Published public var storage: StorageManager
    
    // Filtering State
    @Published public var selectedSubject: Subject? = nil {
        didSet {
            // Reset subcategory filter when switching subjects
            selectedSubCategory = nil
        }
    }
    @Published public var selectedSubCategory: String? = nil
    @Published public var selectedErrorType: ErrorType? = nil
    @Published public var selectedStatus: BugStatus? = nil
    @Published public var searchText: String = ""
    
    // Sheet & Modal Presentation State
    @Published public var isShowingManualEntry: Bool = false
    @Published public var isShowingRecallDrill: Bool = false
    @Published public var isShowingSettings: Bool = false
    
    // Draft / Edit State
    @Published public var activeEditingEntry: BugEntry? = nil
    @Published public var manualEntryDraft: BugEntryDraft? = nil
    
    // Feedback & Toast Banner
    @Published public var toastMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(storage: StorageManager = .shared) {
        self.storage = storage
        
        // Forward changes from storage to ensure view updates
        storage.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtered Bug Entries
    public var filteredEntries: [BugEntry] {
        storage.entries.filter { entry in
            // Subject filter
            if let subject = selectedSubject, entry.subject != subject {
                return false
            }
            // SubCategory filter
            if let subCategory = selectedSubCategory, !subCategory.isEmpty, entry.subCategory != subCategory {
                return false
            }
            // ErrorType filter
            if let errorType = selectedErrorType, entry.errorType != errorType {
                return false
            }
            // BugStatus filter
            if let status = selectedStatus, entry.status != status {
                return false
            }
            // Text Search filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchDesc = entry.bugDescription.lowercased().contains(query)
                let matchSource = entry.source.lowercased().contains(query)
                let matchPatch = entry.patch.lowercased().contains(query)
                let matchInvariant = entry.invariant.lowercased().contains(query)
                let matchSub = entry.subCategory.lowercased().contains(query)
                if !(matchDesc || matchSource || matchPatch || matchInvariant || matchSub) {
                    return false
                }
            }
            return true
        }
    }
    
    // MARK: - Telemetry Statistics
    public var stats: TelemetryStats {
        TelemetryStats(entries: storage.entries)
    }
    
    // Dynamic Subcategories for currently selected Subject
    public var availableSubCategories: [String] {
        guard let subject = selectedSubject else { return [] }
        return subject.subCategories
    }
    
    // MARK: - One-Tap AI Clipboard Ingestion
    public func ingestFromClipboard() {
        TelemetryHaptics.lightTap()
        
        guard let clipboardText = UIPasteboard.general.string, !clipboardText.isEmpty else {
            showToast("Clipboard-ul este gol. Copiază un log generat de AI.")
            TelemetryHaptics.warning()
            return
        }
        
        let result = ClipboardParser.parse(rawText: clipboardText)
        
        switch result {
        case .success(let newEntry):
            storage.addEntry(newEntry)
            TelemetryHaptics.success()
            showToast("✅ Ingerat: \(newEntry.subject.displayName) [\(Subject.compactSubCategoryName(newEntry.subCategory))]")
            
        case .partial(let draft, let reason):
            self.manualEntryDraft = draft
            self.activeEditingEntry = nil
            self.isShowingManualEntry = true
            TelemetryHaptics.warning()
            showToast("ℹ️ \(reason)")
            
        case .empty:
            showToast("⚠️ Textul din clipboard nu a putut fi decodificat.")
            TelemetryHaptics.error()
        }
    }
    
    // MARK: - Actions
    public func toggleMastered(for entry: BugEntry) {
        storage.toggleMastered(withId: entry.id)
        TelemetryHaptics.rigidTap()
    }
    
    public func deleteEntry(_ entry: BugEntry) {
        storage.deleteEntry(withId: entry.id)
        TelemetryHaptics.warning()
    }
    
    public func openManualEntry(for entry: BugEntry? = nil) {
        self.activeEditingEntry = entry
        if let entry = entry {
            self.manualEntryDraft = BugEntryDraft(
                subject: entry.subject,
                subCategory: entry.subCategory,
                source: entry.source,
                errorType: entry.errorType,
                bugDescription: entry.bugDescription,
                patch: entry.patch,
                invariant: entry.invariant
            )
        } else {
            // New entry defaulting to currently filtered subject if set
            let sub = selectedSubject ?? .matematica
            self.manualEntryDraft = BugEntryDraft(
                subject: sub,
                subCategory: selectedSubCategory ?? sub.subCategories.first,
                source: "",
                errorType: selectedErrorType ?? .tipA,
                bugDescription: "",
                patch: "",
                invariant: ""
            )
        }
        self.isShowingManualEntry = true
    }
    
    public func saveDraft(_ draft: BugEntryDraft) {
        if let editing = activeEditingEntry {
            var updated = editing
            updated.subject = draft.subject
            updated.subCategory = draft.subCategory
            updated.source = draft.source
            updated.errorType = draft.errorType
            updated.bugDescription = draft.bugDescription
            updated.patch = draft.patch
            updated.invariant = draft.invariant
            storage.updateEntry(updated)
            TelemetryHaptics.success()
            showToast("Bug actualizat cu succes.")
        } else {
            let newEntry = draft.toBugEntry()
            storage.addEntry(newEntry)
            TelemetryHaptics.success()
            showToast("Bug nou salvat în telemetrie.")
        }
        self.isShowingManualEntry = false
        self.activeEditingEntry = nil
        self.manualEntryDraft = nil
    }
    
    // MARK: - Toast Banner Presentation
    public func showToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation(.easeInOut(duration: 0.25)) {
                if self?.toastMessage == message {
                    self?.toastMessage = nil
                }
            }
        }
    }
}
