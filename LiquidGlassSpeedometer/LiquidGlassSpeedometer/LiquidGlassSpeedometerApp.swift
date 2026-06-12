import SwiftUI

@main
struct LiquidGlassSpeedometerApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(appState.locationManager)
                .environmentObject(appState.motionManager)
                .environmentObject(appState.dataStore)
                .preferredColorScheme(.dark)
        }
    }
}
