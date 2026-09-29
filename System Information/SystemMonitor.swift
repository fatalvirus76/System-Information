import Foundation
import UIKit
import Combine
import Network

// MARK: - Övervakningsmotor: statisk profil + levande tick
@MainActor
final class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published private(set) var profile: DeviceProfile
    @Published private(set) var live = LiveStats()
    @Published private(set) var coreLoads: [Double] = []
    @Published private(set) var appCPU: Double = 0
    @Published private(set) var appFootprintBytes: UInt64 = 0
    @Published private(set) var vm = SystemProbe.VMStats()

    private var timer: Timer?
    private let workQueue = DispatchQueue(label: "sysinfo.probe", qos: .utility)
    private let pathMonitor = NWPathMonitor()
    private var tickCount = 0
    private var firstSample = true

    private init() {
        profile = DeviceProfileBuilder.build()
        startPathMonitor()
        start()
    }

    private func startPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            // Samla allt utanför main — publicera sedan på huvudtråden.
            var np = NetworkProbe()
            np.satisfied = path.status == .satisfied
            np.supportsIPv4 = path.supportsIPv4
            np.supportsIPv6 = path.supportsIPv6
            np.minRTTms = PingCache.shared.lastRTT
            let iface = path.usesInterfaceType(.cellular) ? nil
                : (path.usesInterfaceType(.wifi) ? path.availableInterfaces.first(where: { $0.type == .wifi })
                   : path.availableInterfaces.first(where: { $0.type == .wiredEthernet }) ?? path.availableInterfaces.first)
            np.interfaceName = iface?.name ?? "—"
            if path.usesInterfaceType(.wifi) { np.interfaceType = "Wi-Fi" }
            else if path.usesInterfaceType(.cellular) { np.interfaceType = "Celldata" }
            else if path.usesInterfaceType(.wiredEthernet) { np.interfaceType = "Ethernet" }
            else if path.status == .satisfied { np.interfaceType = "Annan länk" }
            else { np.interfaceType = "Frånkopplad" }
            let addrs = SystemProbe.interfaceAddresses()
            np.ipAddresses = Array((addrs.v4.map(\.ip) + addrs.v6.map(\.ip)).prefix(6))
            let vpn = addrs.hasVPN
            let finished = np
            Task { @MainActor in
                self.live.network = finished
                self.profile.vpnOn = vpn
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "sysinfo.path"))
    }

    func start() {
        timer?.invalidate()
        let t = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        tickCount += 1
        let heavy = tickCount % 8 == 0 || firstSample   // var 16:e sekund: disk + mappskann
        let now = Date()
        let totalPhysical = profile.physicalMemory

        workQueue.async {
            let sysCPU = SystemProbe.systemCPUPercent()
            let cores = SystemProbe.coreLoads()
            let app = SystemProbe.appCPUPercent()
            let foot = SystemProbe.appFootprint()
            let vm = SystemProbe.vmStats()
            let ps = SystemProbe.registryBattery()
            let disk = SystemProbe.diskAndAppSize(heavy: heavy)

            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true
            let level = Double(device.batteryLevel) * 100  // -1 i simulator
            let state = device.batteryState
            let batt = SystemMonitor.buildBattery(level: level, state: state, raw: ps)

            let totalPages = vm.active + vm.inactive + vm.wired + vm.compressed + vm.free + vm.speculative
            let usedPages = vm.active + vm.wired + vm.compressed
            let usedBytes = vm.pageSize * usedPages
            let ramPct = totalPages > 0 ? Double(usedPages) / Double(totalPages) * 100 : 0

            let thermal: String
            switch ProcessInfo.processInfo.thermalState {
            case .nominal: thermal = "Normal"
            case .fair: thermal = "Tillfredsställande"
            case .serious: thermal = "Allvarlig"
            case .critical: thermal = "Kritisk"
            @unknown default: thermal = "—"
            }
            let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled
            let uptime = ProcessInfo.processInfo.systemUptime

            Task { @MainActor in
                self.firstSample = false
                var l = self.live
                l.cpuPercent = sysCPU.clamped(to: 0...100)
                l.cpuSeries.push(sysCPU)
                l.ramUsedBytes = usedBytes
                l.ramTotalBytes = totalPhysical
                l.ramSeries.push(ramPct)
                l.diskTotalBytes = disk.total
                l.diskFreeBytes = disk.free
                l.diskImportantFreeBytes = disk.important
                l.appSizeBytes = disk.appSize
                l.uptime = uptime
                l.battery = batt
                l.thermalState = thermal
                l.lowPowerMode = lpm
                l.brightnessPct = ScreenMetrics.brightnessPct
                l.lastUpdate = now
                self.live = l
                self.coreLoads = cores
                self.appCPU = app
                self.appFootprintBytes = foot
                self.vm = vm
                self.profile.lowPowerMode = lpm
                self.profile.thermalState = thermal
                self.profile.brightnessPct = l.brightnessPct
            }
        }
        PingCache.shared.ping()
    }

    // Batterisammanställning — ren funktion, inga delade mutationer
    private nonisolated static func buildBattery(level: Double, state: UIDevice.BatteryState, raw ps: SystemProbe.RawBattery) -> BatteryReading {
        var batt = BatteryReading()
        let pct: Double
        if level >= 0 {
            pct = level
        } else if let cur = ps.currentCapacity, let mx = ps.maxCapacity, mx > 0 {
            pct = Double(cur) / Double(mx) * 100
        } else {
            pct = 0
        }
        batt.level = pct
        batt.state = level >= 0 ? state : (ps.isCharging == true ? .charging : (ps.externalConnected == true ? .full : .unplugged))
        batt.charging = ps.isCharging ?? (state == .charging)
        batt.externalPowered = ps.externalConnected ?? (state == .charging || state == .full)
        if let amps = ps.amperage, let volts = ps.voltage {
            batt.amperageMA = Double(amps)
            batt.voltageMV = Double(volts)
            batt.watts = abs(Double(amps) / 1000.0) * (Double(volts) / 1000.0)
        }
        batt.maxCapacity = ps.maxCapacity
        batt.designCapacity = ps.designCapacity
        if let mx = ps.maxCapacity, let dz = ps.designCapacity, dz > 0 {
            batt.healthPct = min(100, Double(mx) / Double(dz) * 100)
        }
        batt.cycleCount = ps.cycles
        batt.tempC = ps.tempC
        if let cur = ps.currentCapacity, let mx = ps.maxCapacity, let amps = ps.amperage, amps != 0 {
            if batt.charging {
                let mins = Double(max(0, mx - cur)) / abs(Double(amps)) * 60
                if mins > 0.5, mins < 600 { batt.timeRemainingText = "Fulladd om ≈ \(Fmt.duration(mins * 60))" }
            } else {
                let mins = Double(cur) / abs(Double(amps)) * 60
                if mins > 0.5, mins < 3000 { batt.timeRemainingText = "≈ \(Fmt.duration(mins * 60)) kvar" }
            }
        }
        batt.isEstimated = batt.timeRemainingText != nil
        return batt
    }
}

// MARK: - Appens egna vägar för storlek
enum AppGroupPaths {
    static let containerRoot: URL = URL(fileURLWithPath: NSHomeDirectory())
    static let dataRoot: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSHomeDirectory())
}

// MARK: - RTT-cachare: TCP-connect till 1.1.1.1:443, mäter tiden
final class PingCache: @unchecked Sendable {
    static let shared = PingCache()
    private(set) var lastRTT: Double? {
        get { lock.withLock { _rtt } }
        set { lock.withLock { _rtt = newValue } }
    }
    private var _rtt: Double?
    private let lock = NSLock()
    private let q = DispatchQueue(label: "sysinfo.ping")
    private var inFlight = false

    func ping() {
        q.async { [weak self] in
            guard let self, !self.inFlight else { return }
            self.inFlight = true
            defer { self.inFlight = false }
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = in_port_t(443).bigEndian
            guard inet_pton(AF_INET, "1.1.1.1", &addr.sin_addr) == 1 else { return }
            let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
            guard sock >= 0 else { return }
            defer { close(sock) }
            var tv = timeval(tv_sec: 2, tv_usec: 0)
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.stride))
            let start = CFAbsoluteTimeGetCurrent()
            let r = withUnsafePointer(to: &addr) { p in
                p.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.stride)) }
            }
            if r == 0 {
                self.lastRTT = (CFAbsoluteTimeGetCurrent() - start) * 1000
            }
        }
    }
}
