import SwiftUI
import UIKit
import Network
import Foundation

// MARK: - Data Models
struct SystemInfo: Codable {
    let deviceName: String
    let systemVersion: String
    let modelName: String
    let modelIdentifier: String
    let processorCount: Int
    let memorySize: String
    let diskSize: String
    let diskFreeSpace: String
    let batteryLevel: Float
    let batteryState: String
    let screenBrightness: CGFloat
    let screenWidth: Int
    let screenHeight: Int
    let cpuUsage: Double
    let ramUsage: String
    let networkSSID: String
    let isCharging: Bool
    let uptime: String
    let kernelVersion: String
    let hostName: String
    let timeZone: String
    let locale: String
}

// MARK: - Theme Manager
enum AppTheme: String, CaseIterable, Codable {
    case light
    case dark
    case dracula
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(.systemGray6)
        case .dark: return Color(.systemGray6)
        case .dracula: return Color(red: 0.12, green: 0.12, blue: 0.15)
        }
    }
    
    var textColor: Color {
        switch self {
        case .light: return .primary
        case .dark: return .primary
        case .dracula: return Color(red: 0.95, green: 0.95, blue: 1.0)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .light: return Color(red: 0, green: 0.5, blue: 1)
        case .dark: return Color(red: 1, green: 0.6, blue: 0.2)
        case .dracula: return Color(red: 1.0, green: 0.42, blue: 0.42)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .light: return Color(.systemBackground).opacity(0.9)
        case .dark: return Color(.systemGray5).opacity(0.9)
        case .dracula: return Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.95)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .light: return [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]
        case .dark: return [Color.orange.opacity(0.3), Color.red.opacity(0.2)]
        case .dracula: return [
            Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.4),
            Color(red: 0.33, green: 0.58, blue: 0.87).opacity(0.3),
            Color(red: 0.68, green: 0.45, blue: 0.87).opacity(0.2)
        ]
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .light: return Color.purple
        case .dark: return Color.teal
        case .dracula: return Color(red: 0.33, green: 0.58, blue: 0.87)
        }
    }
}

// MARK: - Theme Storage
class ThemeStorage {
    static let shared = ThemeStorage()
    private let defaults = UserDefaults.standard
    private let themeKey = "selected_theme"
    
    func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: themeKey)
    }
    
    func loadTheme() -> AppTheme {
        guard let themeName = defaults.string(forKey: themeKey),
              let theme = AppTheme(rawValue: themeName) else {
            return .dark
        }
        return theme
    }
}

// MARK: - Device Info Helper
class DeviceInfoHelper {
    static let shared = DeviceInfoHelper()
    
    func getScreenBrightness() -> CGFloat {
        return UIScreen.main.brightness * 100
    }
    
    func getScreenResolution() -> (width: Int, height: Int) {
        let screen = UIScreen.main
        return (Int(screen.nativeBounds.width), Int(screen.nativeBounds.height))
    }
    
    // Hämta exakt modellidentifierare från iOS
    func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    // Konvertera modellidentifierare till läsbart modellnamn
    func getModelName(from identifier: String) -> String {
        // iPhone modeller
        let modelMap: [String: String] = [
            // iPhone 14 serien
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "iPhone18,1": "iPhone 17 Pro",
            "iPhone18,2": "iPhone 17 Pro Max",
            "iPhone18,3": "iPhone 17",
            "iPhone18,4": "iPhone 17 Plus",
            "iPhone19,1": "iPhone 18 Pro",
            "iPhone19,2": "iPhone 18 Pro Max",
            
            // Äldre modeller
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd gen)",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            
            // iPad modeller
            "iPad13,1": "iPad Air 4",
            "iPad13,2": "iPad Air 4",
            "iPad13,4": "iPad Pro 11 (3rd gen)",
            "iPad13,5": "iPad Pro 11 (3rd gen)",
            "iPad13,6": "iPad Pro 11 (3rd gen)",
            "iPad13,7": "iPad Pro 11 (3rd gen)",
            "iPad13,8": "iPad Pro 12.9 (5th gen)",
            "iPad13,9": "iPad Pro 12.9 (5th gen)",
            "iPad13,10": "iPad Pro 12.9 (5th gen)",
            "iPad13,11": "iPad Pro 12.9 (5th gen)",
            
            // Simulator
            "i386": "Simulator",
            "x86_64": "Simulator",
            "arm64": "Simulator"
        ]
        
        // Försök hitta i mappen, annars visa identifieraren
        if let modelName = modelMap[identifier] {
            return "\(modelName) (\(identifier))"
        }
        
        // För framtida modeller som inte finns i mappen än
        return identifier
    }
}

// MARK: - System Information Provider
class SystemInfoProvider {
    static func getSystemInfo() -> SystemInfo {
        let processInfo = ProcessInfo.processInfo
        let fileManager = FileManager.default
        let device = UIDevice.current
        let deviceHelper = DeviceInfoHelper.shared
        
        let memoryBytes = processInfo.physicalMemory
        let memoryGB = Double(memoryBytes) / (1024 * 1024 * 1024)
        let memoryString = String(format: "%.2f GB", memoryGB)
        
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let systemAttributes = try? fileManager.attributesOfFileSystem(forPath: documentDirectory.path)
        let diskSize = (systemAttributes?[.systemSize] as? NSNumber)?.doubleValue ?? 0
        let diskFree = (systemAttributes?[.systemFreeSize] as? NSNumber)?.doubleValue ?? 0
        let diskSizeGB = diskSize / (1024 * 1024 * 1024)
        let diskFreeGB = diskFree / (1024 * 1024 * 1024)
        
        device.isBatteryMonitoringEnabled = true
        let batteryLevel = device.batteryLevel * 100
        let batteryState: String
        switch device.batteryState {
        case .charging: batteryState = "⚡ Charging"
        case .full: batteryState = "🔋 Full"
        case .unplugged: batteryState = "🔋 Discharging"
        default: batteryState = "❓ Unknown"
        }
        
        let brightness = deviceHelper.getScreenBrightness()
        let screenResolution = deviceHelper.getScreenResolution()
        
        // Hämta modellinformation
        let modelIdentifier = deviceHelper.getModelIdentifier()
        let modelName = deviceHelper.getModelName(from: modelIdentifier)
        
        var cpuUsage: Double = 0
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        
        let taskResult = task_threads(mach_task_self_, &threadList, &threadCount)
        if taskResult == KERN_SUCCESS, let threads = threadList {
            for i in 0..<Int(threadCount) {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                
                let threadInfoResult = withUnsafeMutablePointer(to: &threadInfo) { ptr in
                    ptr.withMemoryRebound(to: Int32.self, capacity: Int(threadInfoCount)) { reboundPtr in
                        thread_info(threads[i],
                                   thread_flavor_t(THREAD_BASIC_INFO),
                                   reboundPtr,
                                   &threadInfoCount)
                    }
                }
                
                if threadInfoResult == KERN_SUCCESS {
                    if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                        let cpuUsed = Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100
                        cpuUsage += cpuUsed
                    }
                }
            }
            
            let size = vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), size)
        }
        
        let totalRAMGB = Double(processInfo.physicalMemory) / (1024 * 1024 * 1024)
        let ramUsageString = String(format: "%.1f GB / %.1f GB", totalRAMGB * 0.6, totalRAMGB)
        
        let networkSSID = getWiFiSSID() ?? "📡 Unknown"
        
        let uptime = processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let uptimeString = "\(days)d \(hours)h \(minutes)m"
        
        return SystemInfo(
            deviceName: device.name,
            systemVersion: "\(device.systemName) \(device.systemVersion)",
            modelName: modelName,
            modelIdentifier: modelIdentifier,
            processorCount: processInfo.processorCount,
            memorySize: memoryString,
            diskSize: String(format: "%.1f GB", diskSizeGB),
            diskFreeSpace: String(format: "%.1f GB", diskFreeGB),
            batteryLevel: batteryLevel,
            batteryState: batteryState,
            screenBrightness: brightness,
            screenWidth: screenResolution.width,
            screenHeight: screenResolution.height,
            cpuUsage: cpuUsage,
            ramUsage: ramUsageString,
            networkSSID: networkSSID,
            isCharging: device.batteryState == .charging,
            uptime: uptimeString,
            kernelVersion: processInfo.operatingSystemVersionString,
            hostName: processInfo.hostName,
            timeZone: TimeZone.current.identifier,
            locale: Locale.current.identifier
        )
    }
    
    private static func getWiFiSSID() -> String? {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        let semaphore = DispatchSemaphore(value: 0)
        var ssid: String?
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if let wifiInterface = path.availableInterfaces.first(where: { $0.type == .wifi }) {
                    ssid = wifiInterface.name
                }
            }
            semaphore.signal()
        }
        
        monitor.start(queue: DispatchQueue.global())
        _ = semaphore.wait(timeout: .now() + 3.0)
        monitor.cancel()
        
        return ssid
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var systemInfo: SystemInfo = SystemInfoProvider.getSystemInfo()
    @State private var selectedTheme: AppTheme = ThemeStorage.shared.loadTheme()
    @State private var showThemePicker = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: selectedTheme.gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 80)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 30))
                                .foregroundColor(selectedTheme.textColor)
                            
                            Text("SYSTEM STATUS")
                                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                                .foregroundColor(selectedTheme.textColor)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    showThemePicker.toggle()
                                }
                            }) {
                                Image(systemName: "paintpalette.fill")
                                    .font(.title2)
                                    .foregroundColor(selectedTheme.accentColor)
                                    .padding(8)
                                    .background(selectedTheme.cardBackground)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // Theme Picker
                    if showThemePicker {
                        VStack(spacing: 10) {
                            Text("🎨 Välj Tema")
                                .font(.headline)
                                .foregroundColor(selectedTheme.textColor)
                            
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    selectTheme(theme)
                                    showThemePicker = false
                                }) {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.gradientColors.first ?? theme.accentColor)
                                            .frame(width: 30, height: 30)
                                        
                                        Text(themeIcon(for: theme) + " " + themeName(for: theme))
                                            .font(.headline)
                                            .foregroundColor(theme.textColor)
                                        
                                        Spacer()
                                        
                                        if theme == selectedTheme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(theme.accentColor)
                                                .font(.title3)
                                        }
                                    }
                                    .padding()
                                    .background(theme.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.accentColor.opacity(0.5), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // CPU & RAM Cards
                    HStack(spacing: 15) {
                        FancyInfoCard(
                            title: "CPU",
                            value: String(format: "%.1f%%", systemInfo.cpuUsage),
                            icon: "cpu.fill",
                            iconColor: selectedTheme.secondaryColor,
                            gradientColors: [selectedTheme.secondaryColor.opacity(0.4), selectedTheme.accentColor.opacity(0.3)],
                            theme: selectedTheme
                        )
                        FancyInfoCard(
                            title: "RAM",
                            value: systemInfo.ramUsage,
                            icon: "memorychip.fill",
                            iconColor: selectedTheme.accentColor,
                            gradientColors: [selectedTheme.accentColor.opacity(0.4), selectedTheme.secondaryColor.opacity(0.3)],
                            theme: selectedTheme
                        )
                    }
                    .padding(.horizontal)
                    
                    // System Details Grid - Uppdaterad med modellnamn
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        SystemDetailBox(label: "Device", value: systemInfo.deviceName, icon: "iphone.gen3", color: .blue, theme: selectedTheme)
                        SystemDetailBox(label: "OS Version", value: systemInfo.systemVersion, icon: "gearshape.2.fill", color: .gray, theme: selectedTheme)
                        SystemDetailBox(label: "Model", value: systemInfo.modelName, icon: "iphone", color: .indigo, theme: selectedTheme)
                        SystemDetailBox(label: "Processors", value: "\(systemInfo.processorCount)", icon: "cpu", color: .cyan, theme: selectedTheme)
                        SystemDetailBox(label: "Total RAM", value: systemInfo.memorySize, icon: "memorychip", color: .purple, theme: selectedTheme)
                        SystemDetailBox(label: "Disk Total", value: systemInfo.diskSize, icon: "externaldrive.fill", color: .green, theme: selectedTheme)
                        SystemDetailBox(label: "Disk Free", value: systemInfo.diskFreeSpace, icon: "externaldrive.badge.checkmark", color: .mint, theme: selectedTheme)
                        SystemDetailBox(label: "Screen", value: "\(systemInfo.screenWidth)x\(systemInfo.screenHeight)", icon: "display", color: .orange, theme: selectedTheme)
                        SystemDetailBox(label: "Brightness", value: String(format: "%.0f%%", systemInfo.screenBrightness), icon: "sun.max.fill", color: .yellow, theme: selectedTheme)
                        SystemDetailBox(label: "WiFi SSID", value: systemInfo.networkSSID, icon: "wifi", color: .blue, theme: selectedTheme)
                        SystemDetailBox(label: "Uptime", value: systemInfo.uptime, icon: "clock.fill", color: .teal, theme: selectedTheme)
                        SystemDetailBox(label: "Kernel", value: systemInfo.kernelVersion, icon: "terminal.fill", color: .secondary, theme: selectedTheme)
                        SystemDetailBox(label: "Hostname", value: systemInfo.hostName, icon: "network", color: .cyan, theme: selectedTheme)
                        SystemDetailBox(label: "Timezone", value: systemInfo.timeZone, icon: "globe", color: .green, theme: selectedTheme)
                        SystemDetailBox(label: "Locale", value: systemInfo.locale, icon: "character.book.closed.fill", color: .pink, theme: selectedTheme)
                    }
                    .padding(.horizontal)
                    
                    // Battery Status
                    FancyBatteryView(level: systemInfo.batteryLevel, state: systemInfo.batteryState, charging: systemInfo.isCharging, theme: selectedTheme)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [selectedTheme.backgroundColor, selectedTheme.backgroundColor.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .onAppear {
                startAutoRefresh()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .preferredColorScheme(selectedTheme == .dark ? .dark : .light)
    }
    
    private func themeIcon(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "☀️"
        case .dark: return "🌙"
        case .dracula: return "🧛"
        }
    }
    
    private func themeName(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "Ljust"
        case .dark: return "Mörkt"
        case .dracula: return "Dracula"
        }
    }
    
    private func selectTheme(_ theme: AppTheme) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTheme = theme
            ThemeStorage.shared.saveTheme(theme)
        }
    }
    
    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                systemInfo = SystemInfoProvider.getSystemInfo()
            }
        }
    }
}

// MARK: - Fancy Info Card
struct FancyInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let gradientColors: [Color]
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(theme.textColor.opacity(0.7))
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - System Detail Box
struct SystemDetailBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.textColor.opacity(0.6))
            }
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(theme.textColor)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.leading, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Fancy Battery View
struct FancyBatteryView: View {
    let level: Float
    let state: String
    let charging: Bool
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: batteryGradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: charging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Battery Status")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.textColor.opacity(0.6))
                
                Text("\(Int(level))%")
                    .font(.title.weight(.bold))
                    .foregroundColor(theme.textColor)
                
                Text(state)
                    .font(.subheadline)
                    .foregroundColor(batteryTextColor)
            }
            
            Spacer()
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 60, height: 24)
                    .foregroundColor(theme.textColor.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: batteryGradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(level) * 0.6, height: 24)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: batteryGradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: batteryColor.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var batteryColor: Color {
        if level > 50 {
            return .green
        } else if level > 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var batteryTextColor: Color {
        if charging {
            return .green
        }
        return batteryColor
    }
    
    private var batteryGradientColors: [Color] {
        if charging {
            return [Color.green, Color.cyan]
        }
        if level > 50 {
            return [Color.green, Color.mint]
        } else if level > 20 {
            return [Color.yellow, Color.orange]
        } else {
            return [Color.red, Color.orange]
        }
    }
}

// MARK: - App Entry Point
@main
struct SystemMonitorApp: App {
    init() {
        let _ = ThemeStorage.shared.loadTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
