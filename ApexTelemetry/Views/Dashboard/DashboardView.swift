import SwiftUI

// MARK: - OLED Telemetry Dashboard
public struct DashboardView: View {
    @ObservedObject public var viewModel: TelemetryViewModel
    
    @State private var isShowingDeleteAlert = false
    @State private var entryToDelete: BugEntry? = nil
    
    public init(viewModel: TelemetryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Pure OLED Black Background
                Color.oledBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Fixed Top Header: Weekly Telemetry Bar
                    telemetryMetricsBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    // 2. High-Contrast Ingestion CTA Button
                    clipboardIngestionButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    
                    // 3. Hierarchical Filter Chips (2-Tier: Subject -> SubCategory)
                    hierarchicalFilterSection
                        .padding(.bottom, 8)
                    
                    // 4. Main Scrollable Card Feed
                    bugListFeed
                }
                
                // Floating Toast Banner
                if let toast = viewModel.toastMessage {
                    toastBanner(toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.telemetryEmerald)
                        Text("ApexTelemetry")
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                // Left Bar Item: Settings & Backup
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        TelemetryHaptics.lightTap()
                        viewModel.isShowingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Right Bar Items: Recall Drill Mode & Manual Add
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        // Active Recall Flashcard Drill Button
                        Button(action: {
                            TelemetryHaptics.mediumTap()
                            viewModel.isShowingRecallDrill = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.telemetryCyan)
                                
                                if viewModel.stats.activeCount > 0 {
                                    Circle()
                                        .fill(Color.telemetryRose)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        
                        // Manual Bug Entry Button
                        Button(action: {
                            TelemetryHaptics.lightTap()
                            viewModel.openManualEntry()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingManualEntry) {
                if let draft = viewModel.manualEntryDraft {
                    ManualEntryView(
                        initialDraft: draft,
                        isEditing: viewModel.activeEditingEntry != nil,
                        onSave: { updatedDraft in
                            viewModel.saveDraft(updatedDraft)
                        },
                        onCancel: {
                            viewModel.isShowingManualEntry = false
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $viewModel.isShowingRecallDrill) {
                ActiveRecallView(
                    entries: viewModel.filteredEntries.filter { $0.status == .pendingReview },
                    onComplete: {
                        viewModel.isShowingRecallDrill = false
                    },
                    onRecordResult: { id, mastered in
                        viewModel.storage.recordDrillResult(id: id, mastered: mastered)
                    }
                )
            }
            .sheet(isPresented: $viewModel.isShowingSettings) {
                SettingsView(storage: viewModel.storage)
            }
            .alert("Șterge Bug", isPresented: $isShowingDeleteAlert, presenting: entryToDelete) { entry in
                Button("Șterge Definitiv", role: .destructive) {
                    viewModel.deleteEntry(entry)
                }
                Button("Anulează", role: .cancel) {}
            } message: { entry in
                Text("Sigur dorești să elimini bug-ul din telemetrie? Această acțiune nu poate fi anulată.")
            }
        }
    }
    
    // MARK: - 1. Weekly Telemetry Bar
    private var telemetryMetricsBar: some View {
        HStack(spacing: 8) {
            // Metric 1: Total Active
            VStack(alignment: .leading, spacing: 2) {
                Text("ACTIVE BUGS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.textMuted)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.stats.activeCount)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("/ \(viewModel.stats.totalCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .telemetryCard(cornerRadius: 10)
            
            // Metric 2: Error Type Breakdown Pills
            HStack(spacing: 5) {
                metricPill(count: viewModel.stats.tipACount, type: .tipA)
                metricPill(count: viewModel.stats.tipBCount, type: .tipB)
                metricPill(count: viewModel.stats.tipCCount, type: .tipC)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .telemetryCard(cornerRadius: 10)
            
            // Metric 3: Mastery Rate Gauge
            VStack(alignment: .trailing, spacing: 2) {
                Text("MASTERY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.textMuted)
                Text(String(format: "%.0f%%", viewModel.stats.masteryPercentage))
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(.telemetryEmerald)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .telemetryCard(cornerRadius: 10)
        }
    }
    
    private func metricPill(count: Int, type: ErrorType) -> some View {
        VStack(spacing: 1) {
            Text(type.rawValue.replacingOccurrences(of: "Tip ", with: ""))
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(Color.forErrorType(type))
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(minWidth: 26)
        .padding(.vertical, 2)
        .background(Color.forErrorType(type).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    // MARK: - 2. One-Tap AI Clipboard Ingestion Button
    private var clipboardIngestionButton: some View {
        Button(action: {
            viewModel.ingestFromClipboard()
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Paste AI Log din Clipboard")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    Text("Detectează automat Markdown (### 🔴 BUG LOG) sau JSON")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.75))
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.white.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - 3. Hierarchical Filter Section
    private var hierarchicalFilterSection: some View {
        VStack(spacing: 8) {
            // Tier 1: Main Subject Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    subjectChip(title: "Toate", isSelected: viewModel.selectedSubject == nil) {
                        viewModel.selectedSubject = nil
                    }
                    
                    ForEach(Subject.allCases) { subject in
                        subjectChip(
                            title: subject.displayName,
                            icon: subject.iconName,
                            isSelected: viewModel.selectedSubject == subject
                        ) {
                            if viewModel.selectedSubject == subject {
                                viewModel.selectedSubject = nil
                            } else {
                                viewModel.selectedSubject = subject
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Tier 2: Dynamic SubCategory Chips (Visible when subject is selected)
            if let subject = viewModel.selectedSubject {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Reset subcategory chip
                        subCategoryChip(
                            title: "Toate din \(subject.displayName)",
                            isSelected: viewModel.selectedSubCategory == nil
                        ) {
                            viewModel.selectedSubCategory = nil
                        }
                        
                        ForEach(subject.subCategories, id: \.self) { subCat in
                            subCategoryChip(
                                title: Subject.compactSubCategoryName(subCat),
                                isSelected: viewModel.selectedSubCategory == subCat
                            ) {
                                if viewModel.selectedSubCategory == subCat {
                                    viewModel.selectedSubCategory = nil
                                } else {
                                    viewModel.selectedSubCategory = subCat
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Tier 3: Secondary Filters (Status & Error Type)
            HStack(spacing: 8) {
                // Status Filter Segment
                statusFilterSegment
                
                Spacer()
                
                // Error Type Filter Pills
                HStack(spacing: 6) {
                    ForEach(ErrorType.allCases) { type in
                        Button(action: {
                            TelemetryHaptics.lightTap()
                            if viewModel.selectedErrorType == type {
                                viewModel.selectedErrorType = nil
                            } else {
                                viewModel.selectedErrorType = type
                            }
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    viewModel.selectedErrorType == type
                                    ? Color.forErrorType(type)
                                    : Color.surfaceDark
                                )
                                .foregroundColor(
                                    viewModel.selectedErrorType == type
                                    ? .black
                                    : Color.forErrorType(type)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.forErrorType(type).opacity(0.4), lineWidth: 0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func subjectChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            TelemetryHaptics.lightTap()
            action()
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white : Color.surfaceDark)
            .foregroundColor(isSelected ? .black : .white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white : Color.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func subCategoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            TelemetryHaptics.lightTap()
            action()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.telemetryCyan : Color.surfaceDark.opacity(0.6))
                .foregroundColor(isSelected ? .black : .textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.telemetryCyan : Color.borderSubtle, lineWidth: 0.8)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusFilterSegment: some View {
        HStack(spacing: 2) {
            statusPill(title: "Toate", status: nil)
            statusPill(title: "Pending", status: .pendingReview)
            statusPill(title: "Mastered", status: .mastered)
        }
        .padding(3)
        .background(Color.surfaceDark)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }
    
    private func statusPill(title: String, status: BugStatus?) -> some View {
        Button(action: {
            TelemetryHaptics.lightTap()
            viewModel.selectedStatus = status
        }) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(viewModel.selectedStatus == status ? Color.borderLight : Color.clear)
                .foregroundColor(viewModel.selectedStatus == status ? .white : .textMuted)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 4. Main Bug List Feed
    private var bugListFeed: some View {
        Group {
            if viewModel.filteredEntries.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.filteredEntries) { entry in
                        BugCardView(
                            entry: entry,
                            onToggleMastered: {
                                viewModel.toggleMastered(for: entry)
                            },
                            onDelete: {
                                self.entryToDelete = entry
                                self.isShowingDeleteAlert = true
                            },
                            onEdit: {
                                viewModel.openManualEntry(for: entry)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                viewModel.toggleMastered(for: entry)
                            } label: {
                                Label(
                                    entry.isMastered ? "În lucru" : "Stăpânit",
                                    systemImage: entry.isMastered ? "circle.dashed" : "checkmark.seal.fill"
                                )
                            }
                            .tint(entry.isMastered ? .gray : .green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                self.entryToDelete = entry
                                self.isShowingDeleteAlert = true
                            } label: {
                                Label("Șterge", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.oledBlack)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.borderLight)
            
            VStack(spacing: 6) {
                Text("Niciun bug detectat")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Apasă pe butonul de ingestie clipboard pentru a importa un log sau apasă pe '+' pentru creare manuală.")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                viewModel.storage.loadSampleData()
                TelemetryHaptics.success()
                viewModel.showToast("Baza de date reîncărcată cu exemple.")
            }) {
                Text("Încarcă Exemple BAC / UPB")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.telemetryCyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.telemetryCyan.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: - Toast Banner
    private func toastBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.black)
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 3)
    }
}

// Button scale effect
public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
