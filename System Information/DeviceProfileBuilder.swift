import Foundation
import UIKit
import os

// MARK: - Statisk profil — byggs en gång vid start
enum DeviceProfileBuilder {

    static func build() -> DeviceProfile {
        let pi = ProcessInfo.processInfo
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let modelID = modelNameIdentifier()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screen = scene?.screen ?? UIScreen.main
        let native = screen.nativeBounds
        let refresh = Double(screen.maximumFramesPerSecond)

        // Kärnor: prestanda/effekt via sysctl (afinities fungerar inte alltid; slå upp per freq)
        let active = pi.activeProcessorCount
        let total = hwCPUCount()
        let (perf, eff) = coreSplit(total: total)

        var acc: [String] = []
        if UIAccessibility.isVoiceOverRunning { acc.append("VoiceOver") }
        if UIAccessibility.isBoldTextEnabled { acc.append("Fet text") }
        if UIAccessibility.isDarkerSystemColorsEnabled { acc.append("Mörkare färger") }
        if UIAccessibility.isReduceTransparencyEnabled { acc.append("Minska transparens") }
        if UIAccessibility.isReduceMotionEnabled { acc.append("Minska rörelse") }
        if UIAccessibility.isGuidedAccessEnabled { acc.append("Styrd åtkomst") }
        if UIAccessibility.isSwitchControlRunning { acc.append("Switch Control") }
        if UIAccessibility.isInvertColorsEnabled { acc.append("Invertera färger") }

        let caps = scene?.keyWindow?.safeAreaInsets ?? .zero

        return DeviceProfile(
            deviceName: device.name,
            modelIdentifier: modelID,
            modelName: friendlyModelName(modelID),
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            buildVersion: buildVersionString(),
            kernelVersion: kernelVersionString(),
            hostName: pi.hostName,
            bootTime: Date().addingTimeInterval(-pi.systemUptime),
            cpuCores: total > 0 ? total : active,
            perfCores: perf,
            effCores: eff,
            activeProcessorCount: active,
            physicalMemory: pi.physicalMemory,
            appMemoryLimit: recommendedMem(pi),
            screenNativeW: Int(native.width),
            screenNativeH: Int(native.height),
            screenScale: screen.nativeScale,
            refreshRate: refresh,
            isSimulator: isSimulatorPath(),
            timeZoneID: TimeZone.current.identifier,
            localeID: Locale.current.identifier,
            language: Locale.current.language.languageCode?.identifier ?? "—",
            region: Locale.current.region?.identifier ?? "—",
            calendarID: calendarIdentifierString(),
            capInsets: "T \(Int(caps.top)) / B \(Int(caps.bottom))",
            accessibilityFlags: acc,
            lowPowerMode: pi.isLowPowerModeEnabled,
            vpnOn: false,
            thermalState: "—",
            brightnessPct: Double(UIScreen.main.brightness) * 100,
            autoLockSeconds: autoLockSeconds()
        )
    }

    // ---- Hjälpfunktioner ----

    private static func recommendedMem(_ pi: ProcessInfo) -> UInt64 {
        UInt64(os_proc_available_memory())
    }

    private static func calendarIdentifierString() -> String {
        let cal = Locale.current.calendar as NSCalendar
        return cal.calendarIdentifier.rawValue
    }

    static func modelNameIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { raw in
            String(decoding: raw.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }

    private static func isSimulatorPath() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private static func buildVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let m = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "\(m) (\(v)) · \(unameString())"
    }

    private static func unameString() -> String {
        var u = utsname()
        uname(&u)
        let rel = withUnsafeBytes(of: &u.release) { raw in String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self)) }
        return rel
    }

    private static func kernelVersionString() -> String {
        var u = utsname()
        uname(&u)
        let ver = withUnsafeBytes(of: &u.version) { raw in String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self)) }
        let machine = modelNameIdentifier()
        return "\(ver) [\(machine)]"
    }

    private static func autoLockSeconds() -> Int? {
        nil // read-only; sätts ej i app-sandbox
    }

    private static func hwCPUCount() -> Int {
        var count: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &count, &size, nil, 0)
        return Int(count)
    }

    private static func coreSplit(total: Int) -> (perf: Int?, eff: Int?) {
        var size = 0
        sysctlbyname("hw.perflevel0.physicalcpu", nil, &size, nil, 0)
        var n0: Int32 = 0
        if size > 0 { sysctlbyname("hw.perflevel0.physicalcpu", &n0, &size, nil, 0) }
        size = 0
        sysctlbyname("hw.perflevel1.physicalcpu", nil, &size, nil, 0)
        var n1: Int32 = 0
        if size > 0 { sysctlbyname("hw.perflevel1.physicalcpu", &n1, &size, nil, 0) }
        if n0 > 0, n1 > 0 { return (Int(n0), Int(n1)) }
        if n0 > 0, total > Int(n0) { return (Int(n0), total - Int(n0)) }
        return (nil, nil)
    }

    static func friendlyModelName(_ id: String) -> String {
        let map: [String: String] = [
            "iPhone12,1": "iPhone 11", "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE (2:a gen)",
            "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12", "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max", "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13", "iPhone14,6": "iPhone SE (3:e gen)",
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus", "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus", "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max", "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus", "iPhone17,5": "iPhone 16e",
            "iPhone18,1": "iPhone 17 Pro", "iPhone18,2": "iPhone 17 Pro Max", "iPhone18,3": "iPhone 17", "iPhone18,4": "iPhone 17 Plus",
            "x86_64": "Simulator", "i386": "Simulator", "arm64": "Simulator"
        ]
        if let n = map[id] { return "\(n) · \(id)" }
        return id
    }
}
