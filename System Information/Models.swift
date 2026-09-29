import Foundation
import UIKit

// MARK: - Formateringshjälp
enum Fmt {
    /// Bytes → läsbar sträng (binära prefix)
    static func bytes(_ b: Int64) -> String {
        let gb = Double(b) / 1_073_741_824.0
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        let mb = Double(b) / 1_048_576.0
        if mb >= 1.0 { return String(format: "%.0f MB", mb) }
        return String(format: "%.0f KB", Double(b) / 1024.0)
    }

    static func bytes(_ b: UInt64) -> String { bytes(Int64(bitPattern: b)) }

    /// Sekunder → "3d 4h 12m" / "4h 12m 5s" / "12m 3s"
    static func duration(_ s: TimeInterval) -> String {
        let t = Int(s)
        let d = t / 86400, h = (t % 86400) / 3600, m = (t % 3600) / 60, sec = t % 60
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        if h > 0 { return "\(h)h \(m)m \(sec)s" }
        return "\(m)m \(sec)s"
    }

    static func percent(_ v: Double, _ digits: Int = 1) -> String {
        String(format: "%.\(digits)f%%", max(0, v))
    }
}

extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}

// MARK: - Tidsserie för sparklines (CPU/RAM osv)
struct MetricSeries: Identifiable {
    let id = UUID()
    let name: String
    private(set) var values: [Double]
    let maxPoints: Int

    init(name: String, maxPoints: Int = 60) {
        self.name = name
        self.maxPoints = maxPoints
        self.values = []
    }

    mutating func push(_ v: Double) {
        values.append(v.clamped(to: 0...100))
        if values.count > maxPoints { values.removeFirst(values.count - maxPoints) }
    }

    var current: Double { values.last ?? 0 }
    var average: Double { values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }
    var peak: Double { values.max() ?? 0 }
}

// MARK: - Batteridetaljer
struct BatteryReading {
    var level: Double = -1                 // 0-100, -1 = okänt (simulator)
    var state: UIDevice.BatteryState = .unknown
    var charging: Bool = false
    var externalPowered: Bool = false
    var amperageMA: Double = 0             // + vid laddning
    var voltageMV: Double = 0
    var watts: Double = 0
    var maxCapacity: Int? = nil            // mAh aktuell fulladd
    var designCapacity: Int? = nil         // mAh från fabrik
    var healthPct: Double? = nil           // max/design %
    var cycleCount: Int? = nil
    var tempC: Double? = nil
    var timeRemainingText: String? = nil   // IOPMPowerSource-estimering
    var isEstimated: Bool = false

    var stateIcon: String {
        switch state {
        case .charging: return "bolt.fill"
        case .full: return "battery.100.bolt"
        case .unplugged: return "battery.50"
        default: return "questionmark.circle"
        }
    }

    var stateText: String {
        switch state {
        case .charging: return "Laddar"
        case .full: return "Fulladd"
        case .unplugged: return "Förbrukning"
        default: return "Okänd"
        }
    }
}

// MARK: - Statisk enhets-/systemprofil (beräknas en gång)
struct DeviceProfile {
    var deviceName: String
    var modelIdentifier: String
    var modelName: String
    var systemName: String
    var systemVersion: String
    var buildVersion: String
    var kernelVersion: String
    var hostName: String
    var bootTime: Date
    var cpuCores: Int
    var perfCores: Int?
    var effCores: Int?
    var activeProcessorCount: Int
    var physicalMemory: UInt64
    var appMemoryLimit: UInt64
    var screenNativeW: Int
    var screenNativeH: Int
    var screenScale: CGFloat
    var refreshRate: Double
    var isSimulator: Bool
    var timeZoneID: String
    var localeID: String
    var language: String
    var region: String
    var calendarID: String
    var capInsets: String          // safe area ö/under
    var accessibilityFlags: [String]
    var lowPowerMode: Bool
    var vpnOn: Bool
    var thermalState: String
    var brightnessPct: Double
    var autoLockSeconds: Int?
}

// MARK: - Levande mätvärden (uppdateras varje tick)
struct LiveStats {
    var cpuPercent: Double = 0
    var ramUsedBytes: UInt64 = 0
    var ramTotalBytes: UInt64 = 0
    var diskTotalBytes: Int64 = 0
    var diskFreeBytes: Int64 = 0
    var diskImportantFreeBytes: Int64 = 0
    var appSizeBytes: Int64 = 0
    var uptime: TimeInterval = 0
    var battery = BatteryReading()
    var brightnessPct: Double = 0
    var network = NetworkProbe()
    var cpuSeries = MetricSeries(name: "CPU")
    var ramSeries = MetricSeries(name: "RAM")
    var gpuLoadPct: Double? = nil
    var thermalState: String = "—"
    var lowPowerMode: Bool = false
    var activeTimer: TimeInterval = 0
    var lastUpdate = Date()
}

// MARK: - Nätvercksdata (före forenklad struct, fylls av NetworkProbe)
struct NetworkProbe {
    var satisfied = false
    var interfaceType = "—"
    var interfaceName = "—"
    var supportsIPv4 = false
    var supportsIPv6 = false
    var transitive = false
    var minRTTms: Double? = nil
    var details: String = ""
    var ipAddresses: [String] = []
}
