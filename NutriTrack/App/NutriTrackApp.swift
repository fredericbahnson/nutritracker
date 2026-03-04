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

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
