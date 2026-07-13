import SwiftUI

@main
struct IOS_TutorialApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeTab()
                .tabItem { Label("Home", systemImage: "gamecontroller") }

            StatsTab()
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            MapTab()
                .tabItem { Label("Map", systemImage: "map") }

            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .preferredColorScheme(.dark)
        .tint(.cyan)
        .onAppear {
            LocationService.shared.requestPermission()
        }
    }
}

#Preview {
    MainTabView()
}
