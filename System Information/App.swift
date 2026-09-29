import SwiftUI

// MARK: - App-entry
@main
struct SystemMonitorApp: App {
    // Singletonerna tvingas fram HÄR, på huvudtråden, innan SwiftUI:s
    // StateObject-autoclosures utvärderas (de kan köras på worker-trådar
    // och en @MainActor-init därifrån = krasch i dispatch_once).
    @StateObject private var themes: ThemeManager
    @StateObject private var monitor: SystemMonitor

    init() {
        _themes = StateObject(wrappedValue: SystemMonitorApp.eagerThemes)
        _monitor = StateObject(wrappedValue: SystemMonitorApp.eagerMonitor)
    }

    private static let eagerThemes: ThemeManager = MainActor.assumeIsolated { ThemeManager.shared }
    private static let eagerMonitor: SystemMonitor = MainActor.assumeIsolated { SystemMonitor.shared }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themes)
                .environmentObject(monitor)
        }
    }
}
