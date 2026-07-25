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
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearance) ?? .system
    }

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
        .preferredColorScheme(selectedAppearance.colorScheme)
        .tint(AppTheme.primary)
        .toolbarBackground(AppTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            LocationService.shared.requestPermission()
        }
    }
}

#Preview {
    MainTabView()
}
