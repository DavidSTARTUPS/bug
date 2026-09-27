import SwiftUI
import UniformTypeIdentifiers

// MARK: - Local Data Safety & Backup Settings
public struct SettingsView: View {
    @ObservedObject public var storage: StorageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingFileImporter = false
    @State private var importStatusMessage: String? = nil
    @State private var isShowingClearAlert = false
    @State private var isShowingShareSheet = false
    @State private var exportFileURL: URL? = nil
    
    public init(storage: StorageManager) {
        self.storage = storage
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.oledBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section 1: FlareStore Persistence & Sandbox Status
                        flareStoreSecurityCard
                        
                        // Section 2: Backup & Restore Actions
                        backupRestoreSection
                        
                        // Section 3: Database Utilities
                        databaseUtilitiesSection
                        
                        // Section 4: App Information & FlareStore Guide
                        aboutSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Setări & Siguranță Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide") {
                        TelemetryHaptics.lightTap()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = exportFileURL {
                    ActivityView(activityItems: [url])
                }
            }
            .alert("Ștergere Bază de Date", isPresented: $isShowingClearAlert) {
                Button("Șterge Tot", role: .destructive) {
                    storage.clearAll()
                    TelemetryHaptics.warning()
                }
                Button("Anulează", role: .cancel) {}
            } message: {
                Text("Ești sigur că vrei să elimini toate bug-urile din telemetrie? Fă un export JSON înainte.")
            }
        }
    }
    
    // MARK: - 1. FlareStore Persistence Info
    private var flareStoreSecurityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.telemetryEmerald)
                Text("PERSISTENȚĂ 100% OFFLINE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.telemetryEmerald)
            }
            
            Text("Datele sunt stocate exclusiv local în containerul securizat al aplicației (`Documents/bug_log.json`).")
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineSpacing(2)
            
            Text("La re-semnarea certificatului pe FlareStore sau reinstalare, iOS păstrează fișierele din Documents atât timp cât Bundle ID-ul rămâne neschimbat. Pentru siguranță absolută, fă un Export periodic.")
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
                .lineSpacing(2)
        }
        .padding(16)
        .telemetryCard()
    }
    
    // MARK: - 2. Backup & Restore Section
    private var backupRestoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT & IMPORT JSON")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.textMuted)
            
            // Export Button
            Button(action: {
                TelemetryHaptics.lightTap()
                if let url = storage.exportFileURL() {
                    self.exportFileURL = url
                    self.isShowingShareSheet = true
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.telemetryCyan.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.telemetryCyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exportă Baza de Date JSON")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Salvează în Fișiere, trimite prin AirDrop sau WhatsApp")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .padding(14)
                .telemetryCard()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Import Button
            Button(action: {
                TelemetryHaptics.lightTap()
                isShowingFileImporter = true
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.telemetryPurple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.telemetryPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Importă Backup JSON")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Restaurează bug-urile salvate anterior")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .padding(14)
                .telemetryCard()
            }
            .buttonStyle(PlainButtonStyle())
            
            if let status = importStatusMessage {
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.telemetryEmerald)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - 3. Database Utilities Section
    private var databaseUtilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UTILITARE BAZĂ DE DATE")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.textMuted)
            

            // Wipe All
            Button(action: {
                TelemetryHaptics.warning()
                isShowingClearAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.telemetryRose)
                    Text("Șterge Toate Datele (Reset)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.telemetryRose)
                    Spacer()
                }
                .padding(14)
                .telemetryCard()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 4. About & FlareStore Guide
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DISTRIBUȚIE FLARESTORE")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.textMuted)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("ApexTelemetry • v1.0.0 (Native Sideload)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("1. Push pe GitHub (branch main/master).\n2. GitHub Actions compilează `ApexTelemetry.ipa`.\n3. Descarcă artifactul din tab-ul Actions.\n4. Încarcă-l pe https://flarestore.app/web-signer pentru semnare și instalare directă.")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(3)
            }
            .padding(14)
            .telemetryCard()
        }
    }
    
    // MARK: - File Import Logic
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            do {
                let count = try storage.importJSON(from: selectedURL, replaceExisting: false)
                TelemetryHaptics.success()
                importStatusMessage = "✅ Importat cu succes (\(count) înregistrări)."
            } catch {
                TelemetryHaptics.error()
                importStatusMessage = "❌ Eroare la citirea fișierului JSON: \(error.localizedDescription)"
            }
        case .failure(let error):
            TelemetryHaptics.error()
            importStatusMessage = "❌ Selectarea fișierului a eșuat: \(error.localizedDescription)"
        }
    }
}

// UIActivityViewController representation for SwiftUI
public struct ActivityView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
