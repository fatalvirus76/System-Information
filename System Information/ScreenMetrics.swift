import UIKit

// MARK: - Skärm via windowScene istället för UIScreen.main (iOS 26-deprecation)
enum ScreenMetrics {
    /// Aktiv skärm via anslutna fönsterscener — ger nil innan scen finns, aldrig crash.
    static var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen
    }

    /// Ljusstyrka 0–100 % (0 om ingen scen ännu)
    static var brightnessPct: Double {
        (screen?.brightness ?? 0) * 100
    }
}
