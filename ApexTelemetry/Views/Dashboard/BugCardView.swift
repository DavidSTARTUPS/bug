import SwiftUI

// MARK: - Individual Bug Telemetry Card
public struct BugCardView: View {
    public let entry: BugEntry
    public let onToggleMastered: () -> Void
    public let onDelete: () -> Void
    public let onEdit: () -> Void
    
    @State private var isShowingDeleteConfirmation = false
    
    public init(
        entry: BugEntry,
        onToggleMastered: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.entry = entry
        self.onToggleMastered = onToggleMastered
        self.onDelete = onDelete
        self.onEdit = onEdit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Header Metadata Bar
            HStack(alignment: .center, spacing: 8) {
                // Subject Tag
                HStack(spacing: 4) {
                    Image(systemName: entry.subject.iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(entry.subject.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                // Discreet SubCategory Tag
                if !entry.subCategory.isEmpty {
                    Text(Subject.compactSubCategoryName(entry.subCategory))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.borderSubtle.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.borderLight.opacity(0.3), lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Error Type Pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.forErrorType(entry.errorType))
                        .frame(width: 6, height: 6)
                    Text(entry.errorType.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.forErrorType(entry.errorType).opacity(0.15))
                .foregroundColor(Color.forErrorType(entry.errorType))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.forErrorType(entry.errorType).opacity(0.4), lineWidth: 0.8)
                )
            }
            
            // 2. Source Badge
            if !entry.source.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.textMuted)
                    Text(entry.source)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            
            // 3. Bug Description
            VStack(alignment: .leading, spacing: 4) {
                Text("🔴 EROARE / BLOCAJ:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.telemetryRose)
                Text(entry.bugDescription)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .lineSpacing(2)
            }
            
            // 4. Terminal-Style Patch Container
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red.opacity(0.6)).frame(width: 7, height: 7)
                        Circle().fill(Color.yellow.opacity(0.6)).frame(width: 7, height: 7)
                        Circle().fill(Color.green.opacity(0.6)).frame(width: 7, height: 7)
                    }
                    Text("❯ PATCH:")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.telemetryEmerald)
                    Spacer()
                }
                
                Text(entry.patch)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 228/255.0, green: 228/255.0, blue: 231/255.0))
                    .lineSpacing(2)
            }
            .padding(12)
            .background(Color.terminalBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.terminalBorder, lineWidth: 1)
            )
            
            // 5. Invariant Block (Math / Algorithmic Law)
            if !entry.invariant.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "sum")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.telemetryCyan)
                        Text("INVARIANT:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.telemetryCyan)
                    }
                    Text(entry.invariant)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .italic()
                        .lineSpacing(1.5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.telemetryCyan.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.telemetryCyan.opacity(0.2), lineWidth: 0.8)
                )
            }
            
            // 6. Footer: Mastery Status & Review Telemetry
            HStack(alignment: .center, spacing: 8) {
                // Mastered Status Button
                Button(action: onToggleMastered) {
                    HStack(spacing: 5) {
                        Image(systemName: entry.isMastered ? "checkmark.seal.fill" : "circle.dashed")
                            .font(.system(size: 12, weight: .bold))
                        Text(entry.isMastered ? "Stăpânit" : "În lucru")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(entry.isMastered ? .telemetryEmerald : .textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(entry.isMastered ? Color.telemetryEmerald.opacity(0.15) : Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Review Count
                if entry.reviewCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9))
                        Text("\(entry.reviewCount) drills")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.textMuted)
                }
                
                Spacer()
                
                // Relative Date
                Text(relativeDateString(for: entry.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
                
                // Edit Menu Button
                Button(action: onEdit) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .telemetryCard(cornerRadius: 14)
    }
    
    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
