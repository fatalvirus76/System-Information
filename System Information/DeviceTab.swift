import SwiftUI

// MARK: - Flik 3: Enhet
struct DeviceTab: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Hero-kort
                GlassCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LinearGradient(colors: p.accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 52, height: 52)
                            Image(systemName: "iphone.gen3.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.profile.deviceName)
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundStyle(p.primaryText)
                                .lineLimit(1)
                            Text(m.profile.modelName)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(p.secondaryText)
                                .lineLimit(2)
                            Text(m.profile.isSimulator ? "Simulator" : "Hårdvara")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(m.profile.isSimulator ? p.warn : p.good)
                        }
                        Spacer()
                    }
                }

                // System
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "gearshape.2.fill", title: "System")
                        InfoRow(icon: "gearshape.fill", label: "OS", value: "\(m.profile.systemName) \(m.profile.systemVersion)")
                        InfoRow(icon: "number.square", label: "Build", value: m.profile.buildVersion)
                        InfoRow(icon: "terminal.fill", label: "Kernel", value: m.profile.kernelVersion)
                        InfoRow(icon: "network", label: "Hostname", value: m.profile.hostName)
                        InfoRow(icon: "calendar.badge.clock", label: "Startad", value: shortDate(m.profile.bootTime))
                        InfoRow(icon: "clock.badge.checkmark", label: "Upptid", value: Fmt.duration(m.live.uptime))
                    }
                }

                // Hårdvara
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "cpu", title: "Hårdvara", color: p.cpuColor)
                        InfoRow(icon: "cpu.fill", label: "Processorer", value: "\(m.profile.cpuCores) kärnor", iconColor: p.cpuColor)
                        if let perf = m.profile.perfCores, let eff = m.profile.effCores {
                            InfoRow(icon: "bolt.heart.fill", label: "Prestanda / Eko", value: "\(perf)P · \(eff)E", iconColor: p.cpuColor)
                        }
                        InfoRow(icon: "dial.low", label: "Aktiva just nu", value: "\(m.profile.activeProcessorCount)", iconColor: p.cpuColor)
                        InfoRow(icon: "memorychip.fill", label: "Fysiskt minne", value: Fmt.bytes(Int64(m.profile.physicalMemory)), iconColor: p.ramColor)
                        InfoRow(icon: "app.badge.fill", label: "App-minnestak", value: Fmt.bytes(Int64(m.profile.appMemoryLimit)), iconColor: p.ramColor)
                        InfoRow(icon: "externaldrive.fill", label: "Lagring", value: Fmt.bytes(m.live.diskTotalBytes), iconColor: p.diskColor)
                        InfoRow(icon: "checkmark.circle", label: "Fri lagring", value: Fmt.bytes(m.live.diskFreeBytes), iconColor: p.good)
                        if m.live.diskImportantFreeBytes > 0 {
                            InfoRow(icon: "arrow.down.circle", label: "Fri (inkl. cacher)", value: Fmt.bytes(m.live.diskImportantFreeBytes), iconColor: p.good)
                        }
                        InfoRow(icon: "app.dashed", label: "Appens data", value: Fmt.bytes(m.live.appSizeBytes), iconColor: p.accent)
                    }
                }

                // Skärm
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "display", title: "Skärm", color: p.warn)
                        InfoRow(icon: "ruler", label: "Upplösning", value: "\(m.profile.screenNativeW) × \(m.profile.screenNativeH)", iconColor: p.warn)
                        InfoRow(icon: "plus.viewfinder", label: "Pixeltäthet", value: "\(Int(m.profile.screenScale))× · \(Int(m.profile.screenScale * 163)) ppi", iconColor: p.warn)
                        InfoRow(icon: "play.tv", label: "Uppdatering", value: "\(Int(m.profile.refreshRate)) Hz", iconColor: p.warn)
                        InfoRow(icon: "sun.max.fill", label: "Ljusstyrka", value: Fmt.percent(m.live.brightnessPct, 0), iconColor: p.warn)
                        InfoRow(icon: "rectangle.portrait.inset.fill", label: "Safe area", value: m.profile.capInsets, iconColor: p.warn)
                    }
                }

                // Batteri
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "battery.100percent.bolt", title: "Batteri", color: p.battColor)
                        InfoRow(icon: "percent", label: "Nivå", value: m.live.battery.level >= 0 ? Fmt.percent(m.live.battery.level, 0) : "—", iconColor: p.battColor)
                        InfoRow(icon: "bolt.fill", label: "Status", value: m.live.battery.stateText, iconColor: m.live.battery.charging ? p.good : p.tertiaryText)
                        if m.live.battery.amperageMA != 0 {
                            InfoRow(icon: "bolt", label: "Ström", value: String(format: "%.0f mA", m.live.battery.amperageMA), iconColor: p.battColor)
                            InfoRow(icon: "bolt.horizontal", label: "Spänning", value: String(format: "%.0f mV", m.live.battery.voltageMV), iconColor: p.battColor)
                            InfoRow(icon: "lightbulb.max", label: "Effekt", value: String(format: "%.2f W", m.live.battery.watts), iconColor: p.battColor)
                        }
                        if let t = m.live.battery.tempC {
                            InfoRow(icon: "thermometer", label: "Temp", value: String(format: "%.1f °C", t), iconColor: p.battColor)
                        }
                        if let h = m.live.battery.healthPct {
                            InfoRow(icon: "heart", label: "Hälsa", value: Fmt.percent(h, 1), valueColor: p.levelColor(100 - h), iconColor: p.battColor)
                        }
                        if let c = m.live.battery.cycleCount {
                            InfoRow(icon: "arrow.triangle.2.circlepath", label: "Cykler", value: "\(c)", iconColor: p.battColor)
                        }
                        if let time = m.live.battery.timeRemainingText {
                            InfoRow(icon: "hourglass", label: "Uppskattning", value: time, iconColor: p.battColor)
                        }
                    }
                }

                // Region & språk
                GlassCard {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader(icon: "globe.americas.fill", title: "Region & språk", color: p.secondary)
                        InfoRow(icon: "globe", label: "Tidszon", value: m.profile.timeZoneID, iconColor: p.secondary)
                        InfoRow(icon: "character.book.closed", label: "Locale", value: m.profile.localeID, iconColor: p.secondary)
                        InfoRow(icon: "text.bubble", label: "Språk", value: m.profile.language.uppercased(), iconColor: p.secondary)
                        InfoRow(icon: "map", label: "Region", value: m.profile.region, iconColor: p.secondary)
                    }
                }

                // Tillgänglighet
                if !m.profile.accessibilityFlags.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(icon: "accessibility", title: "Aktiv tillgänglighet", color: p.good)
                            FlowLayout(spacing: 8) {
                                ForEach(m.profile.accessibilityFlags, id: \.self) { f in
                                    Text(f)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(p.good)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(p.trackFill, in: Capsule())
                                }
                            }
                        }
                    }
                }

                // Systemflaggor
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(icon: "switch.2", title: "Lägen", color: p.accent)
                        ToggleRow(title: "Lågenergiläge", icon: "bolt.slash.fill", isOn: m.live.lowPowerMode)
                        ToggleRow(title: "VPN aktivt", icon: "lock.shield.fill", isOn: m.profile.vpnOn)
                        ToggleRow(title: "Extern ström", icon: "cable.connector", isOn: m.live.battery.externalPowered)
                    }
                }
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
        }
    }

    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "sv_SE")
        f.dateFormat = "d MMM HH:mm"
        return f.string(from: d)
    }
}

struct ToggleRow: View {
    @Environment(\.palette) private var p
    var title: String
    var icon: String
    var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOn ? p.accent : p.tertiaryText)
                .frame(width: 22)
            Text(title).font(.subheadline).foregroundStyle(p.secondaryText)
            Spacer()
            Text(isOn ? "PÅ" : "AV")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(isOn ? .white : p.tertiaryText)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(isOn ? AnyShapeStyle(LinearGradient(colors: p.accentGradient, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(p.trackFill), in: Capsule())
        }
    }
}

// MARK: - Enkel flödeslayout för chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews, place: nil)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        _ = layout(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews) { idx, x, y, size in
            subviews[idx].place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: ProposedViewSize(size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews, place: ((Int, CGFloat, CGFloat, CGSize) -> Void)?) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        var size = CGSize.zero
        for (idx, s) in subviews.enumerated() {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            place?(idx, x, y, sz)
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            size.width = max(size.width, x)
            size.height = max(size.height, y + rowH)
        }
        return size
    }
}
