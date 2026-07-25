import SwiftUI
import MapKit

struct MapTab: View {
    @StateObject private var locationService = LocationService.shared
    @State private var sessions: [GameSession] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Namespace private var mapScope

    private var locatedSessions: [GameSession] {
        sessions.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, scope: mapScope) {
                    UserAnnotation()

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
                .mapControls {
                    MapUserLocationButton(scope: mapScope)
                    MapCompass(scope: mapScope)
                    MapScaleView(scope: mapScope)
                }
                .mapScope(mapScope)

                if locatedSessions.isEmpty {
                    emptyOverlay
                }

                VStack {
                    Spacer()
                    mapStatus
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .navigationTitle("Play map")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshMap()
            locationService.refreshLocation()
        }
        .onChange(of: locationService.latitude) { _, _ in
            updateCamera()
        }
        .onChange(of: locationService.longitude) { _, _ in
            updateCamera()
        }
    }

    private var emptyOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(AppTheme.primary)

            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(2)

            Text(emptyStateMessage)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .appSurface(cornerRadius: 20)
        .padding(.horizontal, 40)
        .allowsHitTesting(false)
    }

    private var mapStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: locatedSessions.isEmpty ? "location.circle" : "mappin.and.ellipse")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.primary.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(locatedSessions.isEmpty ? "Your play map" : "\(locatedSessions.count) saved play \(locatedSessions.count == 1 ? "spot" : "spots")")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                Text(locatedSessions.isEmpty ? "Finish a game to leave your first pin." : "Every completed round with a location is saved here.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.secondaryInk)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: 560, alignment: .leading)
        .appSurface(cornerRadius: 18)
    }

    private var emptyStateIcon: String {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            "location.slash"
        default:
            sessions.isEmpty ? "mappin.slash" : "location.magnifyingglass"
        }
    }

    private var emptyStateTitle: String {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            "LOCATION OFF"
        default:
            sessions.isEmpty ? "NO PINS YET" : "NO LOCATED PINS"
        }
    }

    private var emptyStateMessage: String {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            return "Allow location access in Settings to drop pins for completed games."
        default:
            if sessions.isEmpty {
                return "Complete a game to drop a pin where you played."
            }
            return "Location is warming up. Play one more round after it is ready to add a pin."
        }
    }

    private func refreshMap() {
        sessions = GameSessionStore.load()
        updateCamera(animated: false)
    }

    private func updateCamera(animated: Bool = true) {
        let nextPosition: MapCameraPosition

        if locatedSessions.isEmpty, let coordinate = locationService.coordinate {
            nextPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else if locatedSessions.count == 1, let session = locatedSessions.first {
            nextPosition = .region(MKCoordinateRegion(
                center: session.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else if !locatedSessions.isEmpty {
            nextPosition = .region(region(for: locatedSessions))
        } else {
            nextPosition = .automatic
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = nextPosition
            }
        } else {
            cameraPosition = nextPosition
        }
    }

    private func region(for sessions: [GameSession]) -> MKCoordinateRegion {
        let latitudes = sessions.map(\.latitude)
        let longitudes = sessions.map(\.longitude)
        let minLatitude = latitudes.min() ?? 0
        let maxLatitude = latitudes.max() ?? 0
        let minLongitude = longitudes.min() ?? 0
        let maxLongitude = longitudes.max() ?? 0

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLatitude - minLatitude) * 1.5, 0.02),
                longitudeDelta: max((maxLongitude - minLongitude) * 1.5, 0.02)
            )
        )
    }
}

private extension GameSession {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    MapTab()
}
