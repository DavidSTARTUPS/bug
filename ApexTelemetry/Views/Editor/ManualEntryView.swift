import SwiftUI

// MARK: - Manual Bug Entry & Edit Sheet
public struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var subject: Subject
    @State private var subCategory: String
    @State private var source: String
    @State private var errorType: ErrorType
    @State private var bugDescription: String
    @State private var patch: String
    @State private var invariant: String
    
    public let isEditing: Bool
    public let onSave: (BugEntryDraft) -> Void
    public let onCancel: () -> Void
    
    public init(
        initialDraft: BugEntryDraft,
        isEditing: Bool = false,
        onSave: @escaping (BugEntryDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _subject = State(initialValue: initialDraft.subject)
        _subCategory = State(initialValue: initialDraft.subCategory)
        _source = State(initialValue: initialDraft.source)
        _errorType = State(initialValue: initialDraft.errorType)
        _bugDescription = State(initialValue: initialDraft.bugDescription)
        _patch = State(initialValue: initialDraft.patch)
        _invariant = State(initialValue: initialDraft.invariant)
        self.isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    private var isFormValid: Bool {
        !bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !patch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.oledBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Subject & SubCategory
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MATERIE & SUBCATEGORIE")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.textMuted)
                            
                            // Subject Selector Chips
                            HStack(spacing: 8) {
                                ForEach(Subject.allCases) { item in
                                    Button(action: {
                                        TelemetryHaptics.lightTap()
                                        subject = item
                                        // Auto-select first subcategory of new subject
                                        if let firstSub = item.subCategories.first {
                                            subCategory = firstSub
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: item.iconName)
                                                .font(.system(size: 11))
                                            Text(item.displayName)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(subject == item ? Color.white : Color.surfaceDark)
                                        .foregroundColor(subject == item ? .black : .white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(subject == item ? Color.white : Color.borderSubtle, lineWidth: 1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Dynamic SubCategory Menu / Picker
                            Menu {
                                ForEach(subject.subCategories, id: \.self) { cat in
                                    Button(cat) {
                                        TelemetryHaptics.lightTap()
                                        subCategory = cat
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Subcategorie Examen:")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.textMuted)
                                        Text(Subject.compactSubCategoryName(subCategory.isEmpty ? (subject.subCategories.first ?? "") : subCategory))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.telemetryCyan)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                                .padding(12)
                                .background(Color.surfaceDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Section 2: Error Type Classification
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CLASIFICARE EROARE")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.textMuted)
                            
                            HStack(spacing: 8) {
                                ForEach(ErrorType.allCases) { type in
                                    Button(action: {
                                        TelemetryHaptics.lightTap()
                                        errorType = type
                                    }) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(type.rawValue)
                                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                                .foregroundColor(Color.forErrorType(type))
                                            Text(type.shortLabel)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(errorType == type ? .white : .textMuted)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(errorType == type ? Color.forErrorType(type).opacity(0.2) : Color.surfaceDark)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(errorType == type ? Color.forErrorType(type) : Color.borderSubtle, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Section 3: Source Reference
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SURSĂ / CONTEXT EXAMEN")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.textMuted)
                            
                            TextField("ex: Culegere UPB 2024 Grila 18 sau BAC 2023 Sub III.2", text: $source)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.surfaceDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.borderSubtle, lineWidth: 1)
                                )
                        }
                        
                        // Section 4: Bug Description
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("🔴 EROARE / BLOCAJ COGNITIV")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.telemetryRose)
                                Spacer()
                                Text("Obligatoriu")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textMuted)
                            }
                            
                            TextEditor(text: $bugDescription)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(minHeight: 80)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.surfaceDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.borderSubtle, lineWidth: 1)
                                )
                        }
                        
                        // Section 5: Patch Rule
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("❯ PATCH MECANIC (REGULĂ)")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.telemetryEmerald)
                                Spacer()
                                Text("Monospace")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.textMuted)
                            }
                            
                            TextEditor(text: $patch)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(minHeight: 80)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.terminalBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.terminalBorder, lineWidth: 1)
                                )
                        }
                        
                        // Section 6: Invariant
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("∑ INVARIANT / TEOREMĂ")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.telemetryCyan)
                                Spacer()
                                Text("Formula / Teorie")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textMuted)
                            }
                            
                            TextField("ex: det(A) = sum (-1)^{i+j} * a_{ij} * det(M_{ij})", text: $invariant)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.surfaceDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.borderSubtle, lineWidth: 1)
                                )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Editează Bug" : "Adaugă Bug Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anulează") {
                        TelemetryHaptics.lightTap()
                        dismiss()
                        onCancel()
                    }
                    .foregroundColor(.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvează") {
                        let finalSub = subCategory.isEmpty ? (subject.subCategories.first ?? "") : subCategory
                        let draft = BugEntryDraft(
                            subject: subject,
                            subCategory: finalSub,
                            source: source,
                            errorType: errorType,
                            bugDescription: bugDescription,
                            patch: patch,
                            invariant: invariant
                        )
                        dismiss()
                        onSave(draft)
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isFormValid ? .black : .textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(isFormValid ? Color.white : Color.surfaceDark)
                    .clipShape(Capsule())
                    .disabled(!isFormValid)
                }
            }
        }
    }
}
