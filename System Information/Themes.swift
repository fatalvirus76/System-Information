import SwiftUI
import Combine

// MARK: - Färg-hjälp (hex)
extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - Teman
enum AppTheme: String, CaseIterable, Identifiable {
    case glass      // frostigt ljust glas
    case dark       // modernt mörkt
    case dracula    // Dracula-palett
    case synthwave  // neon 80-tal

    var id: String { rawValue }

    var displayIcon: String {
        switch self {
        case .glass: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        case .dracula: return "wineglass.fill"
        case .synthwave: return "sparkles.rectangle.stack.fill"
        }
    }

    var displayName: String {
        switch self {
        case .glass: return "Glas"
        case .dark: return "Mörkt"
        case .dracula: return "Dracula"
        case .synthwave: return "Synthwave"
        }
    }

    var isDark: Bool { self != .glass }

    /// Komplett palett per tema — all UI läser härifrån.
    var palette: Palette {
        switch self {
        case .glass:
            return Palette(
                backgroundTop: Color(hex: 0xEAF0FB),
                backgroundBottom: Color(hex: 0xD4DEF3),
                glow1: Color(hex: 0x6FA0FF).opacity(0.35),
                glow2: Color(hex: 0xB48CFF).opacity(0.28),
                cardFill: Color.white.opacity(0.72),
                cardStroke: Color.white.opacity(0.9),
                innerStroke: Color(hex: 0x2B3A55).opacity(0.07),
                primaryText: Color(hex: 0x17233B),
                secondaryText: Color(hex: 0x41506E),
                tertiaryText: Color(hex: 0x7484A5),
                accent: Color(hex: 0x2E6BFF),
                accentGradient: [Color(hex: 0x2E6BFF), Color(hex: 0x8E5BFF)],
                secondary: Color(hex: 0x8E5BFF),
                good: Color(hex: 0x189A5C),
                warn: Color(hex: 0xC87A00),
                bad: Color(hex: 0xD9364C),
                cpuColor: Color(hex: 0x2E6BFF),
                ramColor: Color(hex: 0x8E5BFF),
                diskColor: Color(hex: 0x189A5C),
                battColor: Color(hex: 0x0FA98C),
                trackFill: Color(hex: 0x2B3A55).opacity(0.10),
                chartGrid: Color(hex: 0x2B3A55).opacity(0.10),
                colorScheme: .light
            )
        case .dark:
            return Palette(
                backgroundTop: Color(hex: 0x0B0D13),
                backgroundBottom: Color(hex: 0x121724),
                glow1: Color(hex: 0x2E6BFF).opacity(0.22),
                glow2: Color(hex: 0x00C2A8).opacity(0.16),
                cardFill: Color(hex: 0x161C2B).opacity(0.88),
                cardStroke: Color.white.opacity(0.08),
                innerStroke: Color.white.opacity(0.06),
                primaryText: Color(hex: 0xEAF0FA),
                secondaryText: Color(hex: 0xA6B2CC),
                tertiaryText: Color(hex: 0x6B7794),
                accent: Color(hex: 0x4D8DFF),
                accentGradient: [Color(hex: 0x4D8DFF), Color(hex: 0x00C2A8)],
                secondary: Color(hex: 0x00C2A8),
                good: Color(hex: 0x34C77B),
                warn: Color(hex: 0xF5A623),
                bad: Color(hex: 0xFF5A6E),
                cpuColor: Color(hex: 0x4D8DFF),
                ramColor: Color(hex: 0xB48CFF),
                diskColor: Color(hex: 0x34C77B),
                battColor: Color(hex: 0x00C2A8),
                trackFill: Color.white.opacity(0.08),
                chartGrid: Color.white.opacity(0.07),
                colorScheme: .dark
            )
        case .dracula:
            return Palette(
                backgroundTop: Color(hex: 0x21222C),
                backgroundBottom: Color(hex: 0x282A36),
                glow1: Color(hex: 0xFF5555).opacity(0.18),
                glow2: Color(hex: 0xBD93F9).opacity(0.18),
                cardFill: Color(hex: 0x343746).opacity(0.92),
                cardStroke: Color(hex: 0x44475A).opacity(0.8),
                innerStroke: Color(hex: 0x44475A).opacity(0.5),
                primaryText: Color(hex: 0xF8F8F2),
                secondaryText: Color(hex: 0xBFC2D4),
                tertiaryText: Color(hex: 0x6272A4),
                accent: Color(hex: 0xFF5555),
                accentGradient: [Color(hex: 0xFF5555), Color(hex: 0xBD93F9)],
                secondary: Color(hex: 0x8BE9FD),
                good: Color(hex: 0x50FA7B),
                warn: Color(hex: 0xF1FA8C),
                bad: Color(hex: 0xFF5555),
                cpuColor: Color(hex: 0xBD93F9),
                ramColor: Color(hex: 0x8BE9FD),
                diskColor: Color(hex: 0x50FA7B),
                battColor: Color(hex: 0x50FA7B),
                trackFill: Color(hex: 0x44475A).opacity(0.6),
                chartGrid: Color(hex: 0x44475A).opacity(0.5),
                colorScheme: .dark
            )
        case .synthwave:
            return Palette(
                backgroundTop: Color(hex: 0x0D0221),
                backgroundBottom: Color(hex: 0x241748),
                glow1: Color(hex: 0xFF2E97).opacity(0.30),
                glow2: Color(hex: 0x00F0FF).opacity(0.20),
                cardFill: Color(hex: 0x1B0B3A).opacity(0.85),
                cardStroke: Color(hex: 0xFF2E97).opacity(0.32),
                innerStroke: Color(hex: 0x00F0FF).opacity(0.15),
                primaryText: Color(hex: 0xF6F3FF),
                secondaryText: Color(hex: 0xC2B5E8),
                tertiaryText: Color(hex: 0x7C6BAF),
                accent: Color(hex: 0xFF2E97),
                accentGradient: [Color(hex: 0xFF2E97), Color(hex: 0xFF8E3C)],
                secondary: Color(hex: 0x00F0FF),
                good: Color(hex: 0x00F0A4),
                warn: Color(hex: 0xFFD23F),
                bad: Color(hex: 0xFF3B5B),
                cpuColor: Color(hex: 0xFF2E97),
                ramColor: Color(hex: 0x00F0FF),
                diskColor: Color(hex: 0xFF8E3C),
                battColor: Color(hex: 0x00F0A4),
                trackFill: Color(hex: 0x00F0FF).opacity(0.10),
                chartGrid: Color(hex: 0xFF2E97).opacity(0.12),
                colorScheme: .dark
            )
        }
    }
}

// MARK: - Palett
struct Palette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let glow1: Color
    let glow2: Color
    let cardFill: Color
    let cardStroke: Color
    let innerStroke: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accent: Color
    let accentGradient: [Color]
    let secondary: Color
    let good: Color
    let warn: Color
    let bad: Color
    let cpuColor: Color
    let ramColor: Color
    let diskColor: Color
    let battColor: Color
    let trackFill: Color
    let chartGrid: Color
    let colorScheme: ColorScheme

    /// Grön→gul→röd beroende på belastning i procent
    func levelColor(_ pct: Double) -> Color {
        switch pct {
        case ..<60: return good
        case ..<85: return warn
        default: return bad
        }
    }
}

// MARK: - Palette i environment (alla vyer läser palett utan genomrutning)
private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = AppTheme.dark.palette
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// MARK: - ThemeManager (persistens i UserDefaults)
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private static let storageKey = "selected_theme"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
            .flatMap(AppTheme.init(rawValue:))
        theme = saved ?? .synthwave
    }

    var palette: Palette { theme.palette }
}
