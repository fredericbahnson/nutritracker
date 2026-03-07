import SwiftUI

// MARK: - NutriTrackApp

@main
struct NutriTrackApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    private let stack = CoreDataStack.shared
    @StateObject private var todayVM = TodayViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var themeColors = ThemeColors()

    var body: some Scene {
        WindowGroup {
            if let error = stack.loadError {
                CoreDataErrorView(error: error)
                    .preferredColorScheme(colorScheme)
            } else {
                MainScreen()
                    .environmentObject(todayVM)
                    .environmentObject(settingsVM)
                    .environmentObject(themeColors)
                    .environment(\.managedObjectContext, stack.viewContext)
                    .preferredColorScheme(colorScheme)
                    .onAppear {
                        todayVM.fetchTodayEntries()
                    }
                    .onOpenURL { _ in
                        // nutritrack:// received — app is already at MainScreen, nothing to do
                    }
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - CoreDataErrorView

private struct CoreDataErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Unable to Load Data")
                .font(.title2).fontWeight(.semibold)
            Text("NutriTrack could not open its database. Try restarting the app. If the problem persists, reinstalling may resolve it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.secondaryLabel))
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .accessibilityElement(children: .combine)
    }
}
