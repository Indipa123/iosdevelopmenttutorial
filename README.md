# GameM Application

GameM is a SwiftUI iOS game hub developed as part of an **iOS Application Development** project.

The app brings together three quick-play mini-games—**Tap Frenzy**, **Light It Up**, and **Quiz Rush**—with a player profile, local score history, a play-location map, and daily challenge reminders. It demonstrates SwiftUI interface design, the MVVM pattern, persistent storage, location services, local notifications, audio feedback, and API integration.

---

## Table of Contents

- [Features](#features)
- [Folder Architecture](#folder-architecture)
- [Technologies Used](#technologies-used)
- [APIs](#apis)
- [Installation](#installation)
- [Permissions](#permissions)
- [Credits](#credits)
- [Limitations](#limitations)
- [Reflection](#reflection)

---

## Features

- Three interactive mini-games: **Tap Frenzy**, **Light It Up**, and **Quiz Rush**.
- Player profile with a display name, illustrated face avatars, and an optional photo-library profile picture.
- Persistent personal-best scoreboard for every game.
- Statistics dashboard for games played, total score, average score, personal bests, and recent activity.
- Location-aware play map that pins completed game sessions when location access is available.
- Daily challenge reminder with configurable notification time.
- Appearance preference for system, light, or dark mode.
- Haptic and system-sound feedback during gameplay.
- Local persistence for profile data, preferences, high scores, and game-session history using `AppStorage` and `UserDefaults`.
- Responsive SwiftUI layouts for iPhone and iPad.

---

## Folder Architecture

The project follows a lightweight MVVM structure, separating presentation, view models, data models, and services.

```text
iosdevelopmenttutorial/
├── .gitignore
├── README.md
└── IOS Tutorial/
    ├── IOS Tutorial.xcodeproj
    └── IOS Tutorial/
        ├── App/
        │   └── IOS_TutorialApp.swift
        ├── Assets.xcassets/
        ├── Models/
        │   ├── GameMode.swift
        │   ├── GameSession.swift
        │   └── TriviaQuestion.swift
        ├── Services/
        │   ├── LocationService.swift
        │   ├── NotificationService.swift
        │   └── TriviaAPI.swift
        ├── ViewModels/
        │   ├── LightItUpVM.swift
        │   ├── QuizRushVM.swift
        │   ├── StatsVM.swift
        │   └── TapFrenzyVM.swift
        └── Views/
            ├── Games/
            │   ├── LightItUpView.swift
            │   ├── QuizRushView.swift
            │   └── TapFrenzyView.swift
            ├── Shared/
            │   ├── PlayerProfile.swift
            │   ├── ScoreBadge.swift
            │   └── SharedVisuals.swift
            └── Tabs/
                ├── HomeTab.swift
                ├── MapTab.swift
                ├── SettingsTab.swift
                └── StatsTab.swift
```

---

## Technologies Used

- Swift
- SwiftUI
- MVVM architecture
- MapKit
- Core Location
- UserNotifications
- PhotosUI
- AudioToolbox and UIKit haptics
- `URLSession` and `JSONDecoder`
- `UserDefaults` and `AppStorage`

---

## APIs

### Open Trivia Database (OpenTDB)

Quiz Rush retrieves ten multiple-choice questions from [Open Trivia Database](https://opentdb.com/api.php). Players can choose from mixed, sports, movies, geography, history, science, computers, music, and animals categories, as well as several difficulty levels.

Responses are loaded with `URLSession`, decoded with `Codable`, and presented in the Quiz Rush game.

---

## Installation

### Requirements

- macOS
- Xcode 16 or later
- iOS 18.6 Simulator or later

### Steps

1. Clone the repository.

   ```bash
   git clone <repository-url>
   ```

2. Open [IOS Tutorial.xcodeproj](IOS%20Tutorial/IOS%20Tutorial.xcodeproj) in Xcode.

3. Select an iPhone or iPad simulator.

4. Press **Run** (`⌘R`).

---

## Permissions

### Location

Location access is optional. When allowed, the app saves the location of completed games and shows those sessions as pins on the play map.

### Notifications

Notification permission is requested only when a player enables the daily challenge reminder.

### Photos

Players can choose a profile picture through the system photo picker. The selected image is resized and stored locally as a profile image; the app does not upload it to a server.

---

## Credits

- Trivia questions are provided by [Open Trivia Database](https://opentdb.com/).
- Maps and location presentation use Apple’s MapKit and Core Location frameworks.
- System icons are provided by Apple’s SF Symbols.

> **Disclaimer:** This project is for educational purposes. Third-party names, services, and trademarks remain the property of their respective owners.

---

## Limitations

- Quiz Rush requires an internet connection to fetch questions from OpenTDB.
- Player profiles, scores, and game sessions are stored only on the current device; there is no account system or cloud backup.
- There is no online multiplayer or global leaderboard.
- Location pins are available only after location access is granted and a completed game has a valid coordinate.
- The application is currently available in English only.

---

## Reflection

This project is a practical exploration of building a complete iOS experience from several smaller game mechanics. It combines SwiftUI views with view models, persistence, network data, notifications, and location features while keeping the game flows quick and approachable.

The main challenge is keeping each mini-game visually distinct while maintaining a coherent app experience. The project leaves room for future work such as cloud-synced profiles, accessibility preferences, an onboarding flow, and leaderboards.
