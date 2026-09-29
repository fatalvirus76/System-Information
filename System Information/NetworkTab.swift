import SwiftUI
import Network
import Combine

// MARK: - Flik 4: Nätverk
struct NetworkTab: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p
    @State private var dnsProbe = DNSProbe()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Anslutningsstatus
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(statusColor.opacity(0.18)).frame(width: 46, height: 46)
                                Image(systemName: m.live.network.satisfied ? iconForType : "wifi.slash")
                                    .font(.system(size: 21, weight: .bold))
                                    .foregroundStyle(statusColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.live.network.satisfied ? "UPPKOPPLAD" : "FRÅNKOPLAD")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundStyle(statusColor)
                                Text(m.live.network.interfaceType == "—" ? "—" : "\(m.live.network.interfaceType) · \(m.live.network.interfaceName)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(p.secondaryText)
                            }
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            netTag("IPv4", on: m.live.network.supportsIPv4)
                            netTag("IPv6", on: m.live.network.supportsIPv6)
                            netTag("VPN", on: m.profile.vpnOn)
                            Spacer()
                        }
                    }
                }

                // Latens
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "speedometer", title: "Latens", color: p.good)
                        InfoRow(icon: "pingwave", label: "RTT 1.1.1.1", value: m.live.network.minRTTms.map { String(format: "%.0f ms", $0) } ?? "mäter…", iconColor: p.good)
                        InfoRow(icon: "timer", label: "Senaste uppdatering", value: shortTime(m.live.lastUpdate), iconColor: p.good)
                    }
                }

                // IP-adresser
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(icon: "network", title: "IP-adresser", color: p.secondary)
                        if m.live.network.ipAddresses.isEmpty {
                            Text("Inga adresser").font(.system(size: 11, design: .monospaced)).foregroundStyle(p.tertiaryText)
                        } else {
                            ForEach(m.live.network.ipAddresses, id: \.self) { ip in
                                HStack(spacing: 10) {
                                    Image(systemName: ip.contains(":") ? "a.square.fill" : "number.square.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ip.contains(":") ? p.secondary : p.accent)
                                        .frame(width: 22)
                                    Text(ip)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(p.primaryText)
                                        .textSelection(.enabled)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // DNS-uppslag
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(icon: "magnifyingglass.circle.fill", title: "DNS-uppslag", color: p.cpuColor)
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 12))
                                .foregroundStyle(p.tertiaryText)
                            Text(dnsProbe.host)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(p.primaryText)
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                Task { await dnsProbe.resolve() }
                            } label: {
                                Text(dnsProbe.running ? "Slår upp…" : dnsProbe.results.isEmpty ? "Slå upp" : "Uppdatera")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(LinearGradient(colors: p.accentGradient, startPoint: .leading, endPoint: .trailing), in: Capsule())
                            }
                            .disabled(dnsProbe.running)
                        }
                        ForEach(dnsProbe.results, id: \.self) { r in
                            HStack(spacing: 8) {
                                Circle().fill(r.contains(":") ? p.secondary : p.cpuColor).frame(width: 6, height: 6)
                                Text(r).font(.system(size: 11, design: .monospaced)).foregroundStyle(p.secondaryText)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                        }
                        if let e = dnsProbe.error {
                            Text(e).font(.system(size: 10, design: .monospaced)).foregroundStyle(p.bad)
                        }
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
        }
        .task {
            if dnsProbe.results.isEmpty { await dnsProbe.resolve() }
        }
    }

    private var statusColor: Color { m.live.network.satisfied ? p.good : p.bad }
    private var iconForType: String {
        switch m.live.network.interfaceType {
        case "Wi-Fi": return "wifi"
        case "Celldata": return "antenna.radiowaves.left.and.right"
        case "Ethernet": return "cable.connector"
        default: return "network"
        }
    }

    private func netTag(_ t: String, on: Bool) -> some View {
        Text(t)
            .font(.system(size: 9, weight: .heavy)).tracking(0.5)
            .foregroundStyle(on ? .white : p.tertiaryText)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(on ? AnyShapeStyle(LinearGradient(colors: p.accentGradient, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(p.trackFill), in: Capsule())
    }

    private func shortTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "sv_SE")
        f.dateFormat = "HH:mm:ss"
        return f.string(from: d)
    }
}

// MARK: - DNS-prob
@MainActor
final class DNSProbe: ObservableObject {
    @Published var host = "apple.com"
    @Published var results: [String] = []
    @Published var error: String?
    @Published var running = false

    func resolve() async {
        running = true
        error = nil
        let hostCopy = host
        defer { running = false }
        let outcome: (ips: [String], code: Int32) = await withCheckedContinuation { (cont: CheckedContinuation<(ips: [String], code: Int32), Never>) in
            DispatchQueue.global(qos: .utility).async {
                var hints = addrinfo(
                    ai_flags: AI_ADDRCONFIG,
                    ai_family: AF_UNSPEC,
                    ai_socktype: SOCK_STREAM,
                    ai_protocol: IPPROTO_TCP,
                    ai_addrlen: 0,
                    ai_canonname: nil,
                    ai_addr: nil,
                    ai_next: nil
                )
                var res: UnsafeMutablePointer<addrinfo>?
                let code = getaddrinfo(hostCopy, nil, &hints, &res)
                var ips: [String] = []
                if code == 0, let res {
                    defer { freeaddrinfo(res) }
                    var p: UnsafeMutablePointer<addrinfo>? = res
                    while let cur = p {
                        let a = cur.pointee.ai_addr!
                        var buf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(a, cur.pointee.ai_addrlen, &buf, socklen_t(buf.count), nil, 0, NI_NUMERICHOST) == 0 {
                            let ip = String(cString: buf)
                            if !ips.contains(ip) { ips.append(ip) }
                        }
                        p = cur.pointee.ai_next
                    }
                }
                cont.resume(returning: (ips, code))
            }
        }
        results = outcome.ips
        if outcome.ips.isEmpty { error = "Uppslag misslyckades (\(outcome.code))" }
    }
}
