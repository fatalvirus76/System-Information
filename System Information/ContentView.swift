import SwiftUI

// MARK: - Rotvy med flikar
struct ContentView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @EnvironmentObject private var themes: ThemeManager
    @State private var tab: MainTab = .overview
    @State private var showThemeSheet = false

    enum MainTab: String, CaseIterable {
        case overview = "Översikt"
        case performance = "Prestanda"
        case device = "Enhet"
        case network = "Nätverk"

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2.fill"
            case .performance: return "waveform.path.ecg"
            case .device: return "iphone.gen3"
            case .network: return "network"
            }
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                header
                tabBar
                Group {
                    switch tab {
                    case .overview: OverviewTab()
                    case .performance: PerformanceTab()
                    case .device: DeviceTab()
                    case .network: NetworkTab()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.palette, themes.palette)
        .environmentObject(monitor)
        .preferredColorScheme(themes.palette.colorScheme)
        .id(themes.theme)
        .sheet(isPresented: $showThemeSheet) { ThemePickerSheet() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SYSTEMSTATUS")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        LinearGradient(colors: themes.palette.accentGradient, startPoint: .leading, endPoint: .trailing)
                    )
                Text(monitor.profile.modelName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(themes.palette.tertiaryText)
                    .lineLimit(1)
            }
            Spacer()
            StatusPill()
            Button { showThemeSheet = true } label: {
                Image(systemName: themes.theme.displayIcon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(themes.palette.accent)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(themes.palette.cardStroke, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 5) {
            ForEach(MainTab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = t }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: t.icon).font(.system(size: 14, weight: .semibold))
                        Text(t.rawValue).font(.system(size: 9, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        tab == t
                            ? AnyShapeStyle(LinearGradient(colors: themes.palette.accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.clear)
                    )
                    .foregroundStyle(tab == t ? Color.white : themes.palette.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(themes.palette.cardStroke, lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}

// MARK: - Live-indikator
struct StatusPill: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle().fill(p.good.opacity(0.5)).frame(width: 10, height: 10)
                    .scaleEffect(pulse ? 1.7 : 0.7)
                    .opacity(pulse ? 0 : 0.9)
                Circle().fill(p.good).frame(width: 6, height: 6)
            }
            Text("LIVE")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(p.secondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(p.cardStroke, lineWidth: 1))
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

// MARK: - Flik 1: Översikt
struct OverviewTab: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p

    private var ramPct: Double {
        m.live.ramTotalBytes > 0 ? Double(m.live.ramUsedBytes) / Double(m.live.ramTotalBytes) * 100 : 0
    }
    private var diskPct: Double {
        m.live.diskTotalBytes > 0 ? Double(m.live.diskTotalBytes - m.live.diskFreeBytes) / Double(m.live.diskTotalBytes) * 100 : 0
    }
    private var battPct: Double { max(0, m.live.battery.level) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    GlassCard { gaugeColumn(title: "CPU", icon: "cpu.fill", color: p.cpuColor, pct: m.live.cpuPercent, series: m.live.cpuSeries, sub: "medel \(Fmt.percent(m.live.cpuSeries.average, 0)) · topp \(Fmt.percent(m.live.cpuSeries.peak, 0))") }
                    GlassCard { gaugeColumn(title: "MINNE", icon: "memorychip.fill", color: p.ramColor, pct: ramPct, series: m.live.ramSeries, sub: "\(Fmt.bytes(m.live.ramUsedBytes)) / \(Fmt.bytes(Int64(m.live.ramTotalBytes)))") }
                }

                HStack(spacing: 12) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            cardTitle("BATTERI", icon: m.live.battery.charging ? "bolt.fill" : "battery.100", color: p.battColor)
                            Text("\(Int(battPct))%")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundStyle(p.primaryText)
                                .contentTransition(.numericText())
                            MeterBar(fraction: battPct / 100, color: p.battColor)
                            Text(m.live.battery.stateText + (m.live.battery.watts > 0.05 ? String(format: " · %.1f W", m.live.battery.watts) : ""))
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(p.tertiaryText)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            cardTitle("DISK", icon: "externaldrive.fill", color: p.diskColor)
                            Text(Fmt.bytes(m.live.diskTotalBytes - m.live.diskFreeBytes))
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(p.primaryText)
                            MeterBar(fraction: diskPct / 100, color: p.levelColor(diskPct))
                            Text("av \(Fmt.bytes(m.live.diskTotalBytes))")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(p.tertiaryText)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    MiniStatCard(icon: "clock.fill", title: "UPPTID", value: Fmt.duration(m.live.uptime), color: p.accent)
                    MiniStatCard(icon: "thermometer.medium", title: "VÄRME", value: m.live.thermalState, color: thermalColor)
                    MiniStatCard(icon: "wifi", title: "NÄTVERK", value: m.live.network.interfaceType, color: m.live.network.satisfied ? p.good : p.bad)
                    MiniStatCard(icon: "sun.max.fill", title: "LJUSSTYRKA", value: Fmt.percent(m.live.brightnessPct, 0), color: p.warn)
                    MiniStatCard(icon: "gauge.with.dots.needle.67percent", title: "APP CPU", value: Fmt.percent(m.appCPU, 0), color: p.cpuColor)
                    MiniStatCard(icon: "app.badge.checkmark", title: "APP RAM", value: Fmt.bytes(Int64(m.appFootprintBytes)), color: p.ramColor)
                }

                BatteryHealthCard()
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
        }
    }

    private var thermalColor: Color {
        switch m.live.thermalState {
        case "Normal": return p.good
        case "Tillfredsställande": return p.warn
        case "Allvarlig", "Kritisk": return p.bad
        default: return p.tertiaryText
        }
    }

    private func cardTitle(_ t: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(color)
            Text(t).font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
            Spacer()
        }
    }

    private func gaugeColumn(title: String, icon: String, color: Color, pct: Double, series: MetricSeries, sub: String) -> some View {
        VStack(spacing: 8) {
            RingGauge(value: pct, color: color, icon: icon,
                      headline: Fmt.percent(pct, 0), subline: sub,
                      series: series.values, size: 124)
            Text(title).font(.system(size: 10, weight: .heavy)).tracking(1.2).foregroundStyle(p.secondaryText)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MiniStatCard: View {
    @Environment(\.palette) private var p
    var icon: String, title: String, value: String, color: Color

    var body: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(color)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 8.5, weight: .heavy)).tracking(0.8).foregroundStyle(p.tertiaryText)
                    Text(value).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(p.primaryText)
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct BatteryHealthCard: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.text.square.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(p.battColor)
                    Text("BATTERIHÄLSA").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
                    Spacer()
                    if let h = m.live.battery.healthPct {
                        Text(Fmt.percent(h, 0)).font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(p.levelColor(100 - h))
                    } else {
                        Text("—").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(p.tertiaryText)
                    }
                }
                if let h = m.live.battery.healthPct {
                    MeterBar(fraction: h / 100, color: p.levelColor(100 - h))
                }
                HStack(spacing: 12) {
                    if let c = m.live.battery.cycleCount {
                        batteryChip("arrow.triangle.2.circlepath", "\(c) cykler")
                    }
                    if let t = m.live.battery.tempC {
                        batteryChip("thermometer.sun", String(format: "%.1f °C", t))
                    }
                    if m.live.battery.maxCapacity != nil {
                        batteryChip("battery.100", "\(m.live.battery.maxCapacity ?? 0) mAh")
                    }
                    Spacer()
                }
            }
        }
    }

    private func batteryChip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(p.tertiaryText)
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(p.trackFill, in: Capsule())
    }
}
