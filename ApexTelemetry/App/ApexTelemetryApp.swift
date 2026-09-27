import SwiftUI

@main
struct ApexTelemetryApp: App {
    @StateObject private var viewModel = TelemetryViewModel()
    
    init() {
        // Enforce OLED Black theme for UIKit elements (Navigation Bars, Toolbars)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.black
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.monospacedSystemFont(ofSize: 17, weight: .bold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Remove default list background color for seamless OLED black
        UICollectionView.appearance().backgroundColor = UIColor.black
        UITableView.appearance().backgroundColor = UIColor.black
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: viewModel)
                .preferredColorScheme(.dark)
                .background(Color.black.ignoresSafeArea())
        }
    }
}
