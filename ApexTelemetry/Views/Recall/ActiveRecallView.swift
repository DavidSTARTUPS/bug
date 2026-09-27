import SwiftUI

// MARK: - Active Recall Flashcard Reconstruction Engine
public struct ActiveRecallView: View {
    public let entries: [BugEntry]
    public let onComplete: () -> Void
    public let onRecordResult: (UUID, Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int = 0
    @State private var isSolutionRevealed: Bool = false
    @State private var sessionMasteredCount: Int = 0
    @State private var sessionNeedsReviewCount: Int = 0
    @State private var isSessionFinished: Bool = false
    
    public init(
        entries: [BugEntry],
        onComplete: @escaping () -> Void,
        onRecordResult: @escaping (UUID, Bool) -> Void
    ) {
        self.entries = entries
        self.onComplete = onComplete
        self.onRecordResult = onRecordResult
    }
    
    private var currentBug: BugEntry? {
        guard currentIndex < entries.count else { return nil }
        return entries[currentIndex]
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.oledBlack.ignoresSafeArea()
                
                if entries.isEmpty {
                    emptyQueueView
                } else if isSessionFinished {
                    sessionSummaryView
                } else if let bug = currentBug {
                    drillCardView(for: bug)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        TelemetryHaptics.lightTap()
                        dismiss()
                        onComplete()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.textMuted)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    if !entries.isEmpty && !isSessionFinished {
                        Text("Active Recall (\(currentIndex + 1)/\(entries.count))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Drill Card View
    private func drillCardView(for bug: BugEntry) -> some View {
        VStack(spacing: 0) {
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderSubtle)
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(Color.telemetryCyan)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(entries.count), height: 3)
                        .animation(.spring(response: 0.35), value: currentIndex)
                }
            }
            .frame(height: 3)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Challenge Metadata
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: bug.subject.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(bug.subject.displayName)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        
                        if !bug.subCategory.isEmpty {
                            Text(Subject.compactSubCategoryName(bug.subCategory))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.borderSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        
                        Spacer()
                        
                        Text(bug.errorType.rawValue)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(Color.forErrorType(bug.errorType))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.forErrorType(bug.errorType).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    if !bug.source.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                            Text(bug.source)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // STEP 1: The Challenge (Bug Description)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STEP 1 • PROVOCAREA")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.telemetryRose)
                        
                        Text(bug.bugDescription)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.surfaceDark)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                    }
                    
                    // STEP 2: The Solution & Invariant Reveal
                    if isSolutionRevealed {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("STEP 2 • SOLUȚIA & INVARIANTUL")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.telemetryEmerald)
                            
                            // Terminal Patch
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("❯ PATCH CORECTIV:")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.telemetryEmerald)
                                    Spacer()
                                }
                                
                                Text(bug.patch)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .lineSpacing(3)
                            }
                            .padding(14)
                            .background(Color.terminalBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.terminalBorder, lineWidth: 1)
                            )
                            
                            // Invariant Block
                            if !bug.invariant.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sum")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("INVARIANT MATEMATIC / ALGORITMIC:")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(.telemetryCyan)
                                    
                                    Text(bug.invariant)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(red: 228/255.0, green: 228/255.0, blue: 231/255.0))
                                        .italic()
                                        .lineSpacing(2)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.telemetryCyan.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.telemetryCyan.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .identity
                        ))
                    } else {
                        // Blurred / Hidden Teaser
                        Button(action: {
                            TelemetryHaptics.mediumTap()
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                isSolutionRevealed = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Arată Soluția & Invariantul")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            
            // Evaluation Controls (Visible only after reveal)
            if isSolutionRevealed {
                evaluationBar(for: bug)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Evaluation Action Bar
    private func evaluationBar(for bug: BugEntry) -> some View {
        HStack(spacing: 12) {
            // Still Hesitating (Red / Rose)
            Button(action: {
                handleEvaluation(for: bug, mastered: false)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("Încă Ezit")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.telemetryRose)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 100% Mastered (Green / Emerald)
            Button(action: {
                handleEvaluation(for: bug, mastered: true)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Stăpânit 100%")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.telemetryEmerald)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.surfaceDark)
        .overlay(
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private func handleEvaluation(for bug: BugEntry, mastered: Bool) {
        if mastered {
            TelemetryHaptics.success()
            sessionMasteredCount += 1
        } else {
            TelemetryHaptics.lightTap()
            sessionNeedsReviewCount += 1
        }
        
        onRecordResult(bug.id, mastered)
        
        withAnimation(.easeInOut(duration: 0.25)) {
            if currentIndex + 1 < entries.count {
                currentIndex += 1
                isSolutionRevealed = false
            } else {
                isSessionFinished = true
            }
        }
    }
    
    // MARK: - 2. Session Summary View
    private var sessionSummaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.telemetryEmerald.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.telemetryEmerald)
            }
            
            VStack(spacing: 8) {
                Text("Sesiune Completată!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Toate bug-urile selectate au fost reconstruite mental.")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(sessionMasteredCount)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.telemetryEmerald)
                    Text("Stăpânite")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .telemetryCard()
                
                VStack(spacing: 4) {
                    Text("\(sessionNeedsReviewCount)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.telemetryRose)
                    Text("De Repetat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .telemetryCard()
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                TelemetryHaptics.lightTap()
                dismiss()
                onComplete()
            }) {
                Text("Înapoi la Dashboard")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - 3. Empty Queue View
    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(.telemetryEmerald)
            Text("Niciun bug activ de revizuit!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Toate erorile din filtrul curent sunt stăpânite 100%. Adaugă sau activează alte bug-uri din ecranul principal.")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                dismiss()
                onComplete()
            }) {
                Text("Închide")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.surfaceDark)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 1))
            }
            .padding(.top, 10)
        }
    }
}
