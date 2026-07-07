import SwiftUI

struct SettingsTab: View {
    @AppStorage("dailyChallengeEnabled") private var dailyChallengeEnabled = false
    @AppStorage("dailyChallengeTime") private var dailyChallengeTime = SettingsTab.defaultChallengeTime

    @State private var showResetConfirmation = false

    /// 6:00 PM today, stored as a time interval so it fits in AppStorage.
    private static var defaultChallengeTime: Double {
        let components = DateComponents(hour: 18, minute: 0)
        let date = Calendar.current.date(from: components) ?? Date()
        return date.timeIntervalSinceReferenceDate
    }

    private var challengeTimeBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: dailyChallengeTime) },
            set: { dailyChallengeTime = $0.timeIntervalSinceReferenceDate }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily challenge reminder", isOn: $dailyChallengeEnabled)

                    DatePicker(
                        "Reminder time",
                        selection: challengeTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!dailyChallengeEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("A daily local notification is scheduled at the chosen time.")
                }

                Section {
                    Button("Reset All Stats", role: .destructive) {
                        showResetConfirmation = true
                    }
                } footer: {
                    Text("Removes every recorded game session and all high scores.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all stats?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllStats()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all game sessions and high scores. It cannot be undone.")
            }
            .onChange(of: dailyChallengeEnabled) { _, isEnabled in
                if isEnabled {
                    enableDailyChallenge()
                } else {
                    NotificationService.shared.cancelDailyChallenge()
                }
            }
            .onChange(of: dailyChallengeTime) { _, _ in
                if dailyChallengeEnabled {
                    NotificationService.shared.scheduleDailyChallenge(at: challengeTimeBinding.wrappedValue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func enableDailyChallenge() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                NotificationService.shared.scheduleDailyChallenge(at: challengeTimeBinding.wrappedValue)
            } else {
                dailyChallengeEnabled = false
            }
        }
    }

    private func resetAllStats() {
        GameSessionStore.clear()
        for mode in GameMode.allCases {
            UserDefaults.standard.removeObject(forKey: mode.highScoreKey)
        }
    }
}

#Preview {
    SettingsTab()
        .preferredColorScheme(.dark)
}
