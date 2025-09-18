import SwiftUI
import Combine

// Enum for theme selection
enum Theme: Int, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }

    var name: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

// Enum for accent color selection
enum AccentColor: String, CaseIterable, Identifiable {
    case blue, red, green, orange, purple
    var id: Self { self }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

class AppearanceViewModel: ObservableObject {
    @Published var theme: Theme {
        didSet {
            saveTheme()
            applyTheme()
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet {
            saveAccentColor()
        }
    }

    private let themeKey = "appTheme"
    private let accentColorKey = "appAccentColor"

    init() {
        // Load saved settings
        let savedTheme = UserDefaults.standard.integer(forKey: themeKey)
        self.theme = Theme(rawValue: savedTheme) ?? .system

        let savedAccentColor = UserDefaults.standard.string(forKey: accentColorKey)
        self.accentColor = AccentColor(rawValue: savedAccentColor ?? AccentColor.blue.rawValue) ?? .blue
        
        // Apply on init
        applyTheme()
    }

    private func saveTheme() {
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }

    private func saveAccentColor() {
        UserDefaults.standard.set(accentColor.rawValue, forKey: accentColorKey)
    }

    func applyTheme() {
        guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        for window in firstScene.windows {
            switch theme {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}
