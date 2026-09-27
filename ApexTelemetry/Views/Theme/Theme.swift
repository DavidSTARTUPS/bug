import SwiftUI

// MARK: - OLED Telemetry Palette
public extension Color {
    static let oledBlack = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let surfaceDark = Color(red: 18/255.0, green: 18/255.0, blue: 21/255.0) // #121215
    static let borderSubtle = Color(red: 39/255.0, green: 39/255.0, blue: 42/255.0) // #27272a
    static let borderLight = Color(red: 63/255.0, green: 63/255.0, blue: 70/255.0)  // #3f3f46
    static let terminalBackground = Color(red: 10/255.0, green: 10/255.0, blue: 12/255.0) // #0a0a0c
    static let terminalBorder = Color(red: 30/255.0, green: 30/255.0, blue: 36/255.0) // #1e1e24
    
    // Telemetry Type Accents
    static let telemetryPurple = Color(red: 168/255.0, green: 85/255.0, blue: 247/255.0) // #A855F7 (Tip A)
    static let telemetryAmber = Color(red: 245/255.0, green: 158/255.0, blue: 11/255.0)  // #F59E0B (Tip B)
    static let telemetryRose = Color(red: 244/255.0, green: 63/255.0, blue: 94/255.0)    // #F43F5E (Tip C)
    
    // System Status Accents
    static let telemetryEmerald = Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0) // #10B981 (Mastered)
    static let telemetryCyan = Color(red: 6/255.0, green: 182/255.0, blue: 212/255.0)    // #06B6D4 (Invariant)
    static let telemetryBlue = Color(red: 59/255.0, green: 130/255.0, blue: 246/255.0)   // #3B82F6
    static let textSecondary = Color(red: 161/255.0, green: 161/255.0, blue: 170/255.0) // #a1a1aa
    static let textMuted = Color(red: 113/255.0, green: 113/255.0, blue: 122/255.0)     // #71717a
    
    static func forErrorType(_ errorType: ErrorType) -> Color {
        switch errorType {
        case .tipA: return .telemetryPurple
        case .tipB: return .telemetryAmber
        case .tipC: return .telemetryRose
        }
    }
}

// MARK: - Haptic Feedback Utility
public enum TelemetryHaptics {
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    public static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public static func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public static func rigidTap() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Reusable View Modifiers
public struct TelemetryCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 14
    
    public func body(content: Content) -> some View {
        content
            .background(Color.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}

public extension View {
    func telemetryCard(cornerRadius: CGFloat = 14) -> some View {
        self.modifier(TelemetryCardModifier(cornerRadius: cornerRadius))
    }
}
