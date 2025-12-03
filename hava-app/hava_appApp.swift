import SwiftUI
import UserNotifications

@main
struct hava_appApp: App {
    @StateObject private var store = AppStore()
    @State private var showWelcome = true
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(store)
                    .environment(\.fontSizeMultiplier, store.dynamicTypeSize)
                    .preferredColorScheme(store.highContrastMode ? .dark : nil)
                if showWelcome {
                    WelcomeView {
                        showWelcome = false
                    }
                }
            }
        }
    }
}

struct FontSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var fontSizeMultiplier: Double {
        get { self[FontSizeMultiplierKey.self] }
        set { self[FontSizeMultiplierKey.self] = newValue }
    }
}

