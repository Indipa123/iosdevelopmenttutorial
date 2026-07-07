//
//  IOS_TutorialApp.swift
//  IOS Tutorial
//
//  Created by Indipa Ayomal on 2026-06-06.
//

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
    }
}

#Preview {
    MainTabView()
}
