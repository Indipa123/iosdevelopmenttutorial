import PhotosUI
import SwiftUI

struct SettingsTab: View {
    @AppStorage("dailyChallengeEnabled") private var dailyChallengeEnabled = false
    @AppStorage("dailyChallengeTime") private var dailyChallengeTime = SettingsTab.defaultChallengeTime
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("playerDisplayName") private var playerDisplayName = "Player One"
    @AppStorage("playerAvatar") private var playerAvatar = PlayerAvatar.bolt.rawValue
    @AppStorage("playerPhotoData") private var playerPhotoData = Data()
    @AppStorage("playerUsesCustomPhoto") private var playerUsesCustomPhoto = false
    @State private var showResetConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?

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
            ZStack {
                WallpaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        profileCard
                        appearanceCard
                        challengeCard
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("YOUR DATA")
                            resetCard
                        }
                        Text("Your scores live on this device. You can reset them at any time.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: 560, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.canvas, for: .navigationBar)
            .confirmationDialog(
                "Reset all stats?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) { resetAllStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all game sessions and high scores. It cannot be undone.")
            }
        }
        .tint(AppTheme.primary)
        .onChange(of: dailyChallengeEnabled) { _, isEnabled in
            if isEnabled { enableDailyChallenge() }
            else { NotificationService.shared.cancelDailyChallenge() }
        }
        .onChange(of: dailyChallengeTime) { _, _ in
            if dailyChallengeEnabled {
                NotificationService.shared.scheduleDailyChallenge(at: challengeTimeBinding.wrappedValue)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PREFERENCES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
                .tracking(1.6)
            Text("Make it yours")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.ink)
            Text("Set a rhythm that keeps the fun going.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                PlayerAvatarImage(
                    avatarRawValue: playerAvatar,
                    photoData: playerPhotoData,
                    usesCustomPhoto: playerUsesCustomPhoto,
                    size: 76
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("PLAYER PROFILE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                        .tracking(1.4)

                    TextField("Player name", text: $playerDisplayName)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)

                    Text(playerUsesCustomPhoto ? "Using your photo" : "Choose an avatar or add your photo")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(playerUsesCustomPhoto ? "REPLACE PROFILE PHOTO" : "ADD PROFILE PHOTO", systemImage: "photo.badge.plus")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if playerUsesCustomPhoto {
                Button(role: .destructive) {
                    playerPhotoData = Data()
                    playerUsesCustomPhoto = false
                } label: {
                    Label("REMOVE PHOTO", systemImage: "trash")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(AppTheme.line)

            Text("CHOOSE AN AVATAR")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .tracking(1.4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
                ForEach(PlayerAvatar.allCases) { avatar in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            playerAvatar = avatar.rawValue
                            playerUsesCustomPhoto = false
                        }
                    } label: {
                        AvatarChoice(avatar: avatar, isSelected: !playerUsesCustomPhoto && playerAvatar == avatar.rawValue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(avatar.title) as your player avatar")
                }
            }
        }
        .padding(18)
        .appSurface(cornerRadius: 22)
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                guard let profilePhotoData = PlayerProfilePhoto.optimizedData(from: data) else { return }
                playerPhotoData = profilePhotoData
                playerUsesCustomPhoto = true
            }
        }
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.coral)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily challenge")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                    Text(dailyChallengeEnabled ? "We’ll remind you at \(challengeTimeBinding.wrappedValue.formatted(date: .omitted, time: .shortened))." : "A friendly nudge to play one round.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                }
                Spacer(minLength: 8)
                Toggle("Daily challenge reminder", isOn: $dailyChallengeEnabled)
                    .labelsHidden()
            }

            Divider().overlay(AppTheme.line)

            DatePicker("Reminder time", selection: challengeTimeBinding, displayedComponents: .hourAndMinute)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(dailyChallengeEnabled ? AppTheme.ink : AppTheme.secondaryInk)
                .disabled(!dailyChallengeEnabled)
                .opacity(dailyChallengeEnabled ? 1 : 0.45)
        }
        .padding(18)
        .appSurface(cornerRadius: 22)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: selectedAppearance.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Appearance")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                    Text("Choose what feels best on your eyes.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                }
            }

            Picker("Appearance", selection: $appAppearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Label(appearance.title, systemImage: appearance.icon)
                        .tag(appearance.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Choose system, light, or dark appearance")
        }
        .padding(18)
        .appSurface(cornerRadius: 22)
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearance) ?? .system
    }

    private var resetCard: some View {
        Button(role: .destructive) { showResetConfirmation = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.coral)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reset all stats")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Remove game history and personal bests")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(AppTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.coral)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Deletes all recorded game sessions and high scores")
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.secondaryInk)
            .tracking(1.6)
    }

    private func enableDailyChallenge() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted { NotificationService.shared.scheduleDailyChallenge(at: challengeTimeBinding.wrappedValue) }
            else { dailyChallengeEnabled = false }
        }
    }

    private func resetAllStats() {
        GameSessionStore.clear()
        for mode in GameMode.allCases { UserDefaults.standard.removeObject(forKey: mode.highScoreKey) }
    }
}

#Preview { SettingsTab() }
