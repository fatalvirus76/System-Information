import Foundation
import Darwin
#if !targetEnvironment(simulator)
import IOKit
#endif

// MARK: - Lågnivå-prob (Mach/IOKit/POSIX) — körs i bakgrundsqueue
enum SystemProbe {

    // ---- System-CPU (alla kärnor) via tick-delta ----
    private struct CPUTicks { var user: UInt32 = 0, sys: UInt32 = 0, idle: UInt32 = 0, nice: UInt32 = 0
        var total: UInt32 { user &+ sys &+ idle &+ nice }
        var busy: UInt32 { user &+ sys &+ nice }
    }
    private static var lastCPU = CPUTicks()

    static func systemCPUPercent() -> Double {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        var info = host_cpu_load_info_data_t()
        let r = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        guard r == KERN_SUCCESS else { return 0 }
        var cur = CPUTicks()
        withUnsafeBytes(of: info.cpu_ticks) { buf in
            let p = buf.bindMemory(to: UInt32.self)
            cur.user = p[0]; cur.sys = p[1]; cur.idle = p[2]; cur.nice = p[3]
        }
        let dt = cur.total &- lastCPU.total
        let db = cur.busy &- lastCPU.busy
        lastCPU = cur
        guard dt > 0 else { return 0 }
        return Double(db) / Double(dt) * 100
    }

    // ---- Per kärna: tick-delta per processor ----
    private static var lastCoreTicks: [CPUTicks] = []

    static func coreLoads() -> [Double] {
        var count = mach_msg_type_number_t(0)
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let r = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &info, &infoCount)
        guard r == KERN_SUCCESS, let info else { return [] }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info),
                          vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
        }
        var result: [Double] = []
        result.reserveCapacity(Int(count))
        var ticks: [CPUTicks] = []
        ticks.reserveCapacity(Int(count))
        for cpu in 0..<Int(count) {
            let base = cpu * Int(CPU_STATE_MAX)
            var t = CPUTicks()
            t.user = UInt32(bitPattern: info[base + Int(CPU_STATE_USER)])
            t.sys = UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)])
            t.idle = UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)])
            t.nice = UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)])
            ticks.append(t)
            let prev = lastCoreTicks.indices.contains(cpu) ? lastCoreTicks[cpu] : CPUTicks()
            let dt = t.total &- prev.total
            let db = t.busy &- prev.busy
            result.append(dt > 0 ? Double(db) / Double(dt) * 100 : 0)
        }
        lastCoreTicks = ticks
        return result
    }

    // ---- Denna apps CPU (trådar) ----
    static func appCPUPercent() -> Double {
        var total = 0.0
        var threadList: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &count) == KERN_SUCCESS, let threads = threadList else { return 0 }
        for i in 0..<Int(count) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let r = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if r == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 {
                total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads),
                      vm_size_t(Int(count) * MemoryLayout<thread_t>.stride))
        return total
    }

    // ---- App minnes-fotavtryck ----
    static func appFootprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let r = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return r == KERN_SUCCESS ? info.phys_footprint : 0
    }

    // ---- Systemets minnesstatistik (sidor) ----
    struct VMStats { var pageSize: UInt64 = 0, free: UInt64 = 0, active: UInt64 = 0, inactive: UInt64 = 0, wired: UInt64 = 0, compressed: UInt64 = 0, speculative: UInt64 = 0 }

    static func vmStats() -> VMStats {
        var s = VMStats()
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        s.pageSize = UInt64(pageSize)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let r = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard r == KERN_SUCCESS else { return s }
        s.free = UInt64(stats.free_count)
        s.active = UInt64(stats.active_count)
        s.inactive = UInt64(stats.inactive_count)
        s.wired = UInt64(stats.wire_count)
        s.compressed = UInt64(stats.compressor_page_count)
        s.speculative = UInt64(stats.speculative_count)
        return s
    }

    // ---- Ström/spänning/cykler via IORegistry ----
    struct RawBattery {
        var currentCapacity: Int?   // mAh kvar
        var maxCapacity: Int?       // mAh fulladd (aktuell)
        var designCapacity: Int?    // mAh från fabrik
        var cycles: Int?
        var tempC: Double?
        var amperage: Int?          // mA, negativ = urladdning
        var voltage: Int?           // mV
        var isCharging: Bool?
        var externalConnected: Bool?
    }

    static func registryBattery() -> RawBattery {
        var b = RawBattery()
        #if !targetEnvironment(simulator)
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleBatteryDevice"))
        guard service != 0 else { return b }
        defer { IOObjectRelease(service) }
        func intVal(_ key: String) -> Int? {
            guard let v = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else { return nil }
            if let n = v as? Int { return n }
            if let n = v as? NSNumber { return n.intValue }
            return nil
        }
        b.currentCapacity = intVal("AppleRawCurrentCapacity")
        b.maxCapacity = intVal("AppleRawMaxCapacity")
        b.designCapacity = intVal("DesignCapacity")
        b.cycles = intVal("CycleCount")
        b.amperage = intVal("InstantAmperage")
        b.voltage = intVal("Voltage")
        b.isCharging = (intVal("IsCharging").map { $0 != 0 })
        b.externalConnected = (intVal("ExternalConnected").map { $0 != 0 })
        if let t = intVal("Temperature") { b.tempC = Double(t) / 10.0 }
        #endif
        return b
    }

    // ---- Disk ----
    static func diskStats() -> (total: Int64, free: Int64, importantFree: Int64) {
        var total: Int64 = 0, free: Int64 = 0
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
            free = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        }
        var importantFree: Int64 = 0
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docs,
           let vals = try? docs.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let v = vals.volumeAvailableCapacityForImportantUsage {
            importantFree = Int64(v)
        }
        return (total, free, importantFree)
    }

    // ---- Mapp-storlek ----
    static func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey],
                                     options: [.skipsHiddenFiles], errorHandler: { _, _ in true }) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in en {
            let v = try? f.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            total += Int64(v?.totalFileAllocatedSize ?? v?.fileSize ?? 0)
        }
        return total
    }

    // ---- IP-adresser + VPN (utun) ----
    struct NetAddr { var name: String; var ip: String; var isVPN: Bool }
    static func interfaceAddresses() -> (v4: [NetAddr], v6: [NetAddr], hasVPN: Bool) {
        var v4: [NetAddr] = [], v6: [NetAddr] = []
        var hasVPN = false
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0 else { return (v4, v6, false) }
        defer { freeifaddrs(ifap) }
        var p = ifap
        while let cur = p {
            let addr = cur.pointee.ifa_addr
            if let addr, addr.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let name = String(cString: cur.pointee.ifa_name)
                    let ip = String(cString: host)
                    let vpn = name.hasPrefix("utun") && !ip.hasPrefix("169.254")
                    if vpn { hasVPN = true }
                    if !name.hasPrefix("awdl") && !ip.hasPrefix("127.") { v4.append(NetAddr(name: name, ip: ip, isVPN: vpn)) }
                }
            } else if let addr, addr.pointee.sa_family == UInt8(AF_INET6) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: host)
                    let name = String(cString: cur.pointee.ifa_name)
                    if !ip.hasPrefix("fe80") && !name.hasPrefix("awdl") && !ip.hasPrefix("::1") {
                        v6.append(NetAddr(name: name, ip: ip, isVPN: name.hasPrefix("utun")))
                    }
                }
            }
            p = cur.pointee.ifa_next
        }
        return (v4, v6, hasVPN)
    }
}
