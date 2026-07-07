import SwiftUI
import MapKit

struct MapTab: View {
    @State private var sessions: [GameSession] = []

    // TODO (Week 4 Step 5): call LocationService.shared.requestPermission() and record
    // the current coordinates on every completed GameSession so real pins appear here.

    private var locatedSessions: [GameSession] {
        sessions.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    ForEach(locatedSessions) { session in
                        Marker(
                            "\(session.mode.displayName): \(session.score)",
                            systemImage: session.mode.icon,
                            coordinate: CLLocationCoordinate2D(
                                latitude: session.latitude,
                                longitude: session.longitude
                            )
                        )
                        .tint(session.mode.accent)
                    }
                }

                if locatedSessions.isEmpty {
                    emptyOverlay
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            sessions = GameSessionStore.load()
        }
    }

    private var emptyOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(.cyan)

            Text("NO PINS YET")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(2)

            Text("Complete a game to drop a pin where you played.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 40)
        .allowsHitTesting(false)
    }
}

#Preview {
    MapTab()
        .preferredColorScheme(.dark)
}
