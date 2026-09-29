import SwiftUI

// MARK: - Flik 2: Prestanda
struct PerformanceTab: View {
    @EnvironmentObject private var m: SystemMonitor
    @Environment(\.palette) private var p

    private var ramPct: Double {
        m.live.ramTotalBytes > 0 ? Double(m.live.ramUsedBytes) / Double(m.live.ramTotalBytes) * 100 : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Trend-diagram
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 12, weight: .bold)).foregroundStyle(p.cpuColor)
                            Text("TREND · SENASTE 2 MIN")
                                .font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
                            Spacer()
                            legendDot(color: p.cpuColor, label: "CPU \(Fmt.percent(m.live.cpuPercent, 0))")
                            legendDot(color: p.ramColor, label: "RAM \(Fmt.percent(ramPct, 0))")
                        }
                        TrendChart(series: [
                            (values: m.live.cpuSeries.values, color: p.cpuColor),
                            (values: m.live.ramSeries.values, color: p.ramColor)
                        ], gridColor: p.chartGrid)
                        .frame(height: 130)
                    }
                }

                // CPU-kärnor
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cpu.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(p.cpuColor)
                            Text("KERNELAST").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
                            Spacer()
                            Text("\(m.coreLoads.count) kärnor").font(.system(size: 10, design: .monospaced)).foregroundStyle(p.tertiaryText)
                        }
                        if m.coreLoads.isEmpty {
                            Text("Samlar data…").font(.system(size: 11, design: .monospaced)).foregroundStyle(p.tertiaryText)
                        } else {
                            ForEach(Array(m.coreLoads.enumerated()), id: \.offset) { idx, load in
                                HStack(spacing: 8) {
                                    Text("K\(idx)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(p.tertiaryText).frame(width: 26, alignment: .leading)
                                    MeterBar(fraction: load / 100, color: p.levelColor(load))
                                    Text(Fmt.percent(load, 0)).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(p.secondaryText).frame(width: 36, alignment: .trailing)
                                }
                            }
                        }
                    }
                }

                // Minnesfördelning
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "memorychip.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(p.ramColor)
                            Text("MINNESFÖRDELNING").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
                            Spacer()
                        }
                        let vm = m.vm
                        let page = Double(vm.pageSize)
                        MemorySegmentRow(label: "Aktivt", bytes: UInt64(vm.active) * UInt64(page), total: m.live.ramTotalBytes, color: p.ramColor)
                        MemorySegmentRow(label: "Wired", bytes: UInt64(vm.wired) * UInt64(page), total: m.live.ramTotalBytes, color: p.accent)
                        MemorySegmentRow(label: "Komprimerat", bytes: UInt64(vm.compressed) * UInt64(page), total: m.live.ramTotalBytes, color: p.warn)
                        MemorySegmentRow(label: "Inaktivt", bytes: UInt64(vm.inactive) * UInt64(page), total: m.live.ramTotalBytes, color: p.good)
                        MemorySegmentRow(label: "Ledigt", bytes: UInt64(vm.free) * UInt64(page), total: m.live.ramTotalBytes, color: p.tertiaryText)
                    }
                }

                // Denna app
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "app.dashed").font(.system(size: 12, weight: .bold)).foregroundStyle(p.accent)
                            Text("DENNA APP").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(p.secondaryText)
                            Spacer()
                        }
                        InfoRow(icon: "gauge.with.dots.needle.bottom.50percent", label: "CPU", value: Fmt.percent(m.appCPU, 1))
                        InfoRow(icon: "memorychip", label: "Minnesavtryck", value: Fmt.bytes(Int64(m.appFootprintBytes)))
                        InfoRow(icon: "speedometer", label: "Minnestak", value: Fmt.bytes(Int64(m.profile.appMemoryLimit)))
                        InfoRow(icon: "hammer.fill", label: "Appversion", value: appVersionString())
                    }
                }
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(p.secondaryText)
        }
    }

    private func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }
}

struct MemorySegmentRow: View {
    @Environment(\.palette) private var p
    var label: String
    var bytes: UInt64
    var total: UInt64
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundStyle(p.secondaryText).frame(width: 88, alignment: .leading)
            MeterBar(fraction: total > 0 ? Double(bytes) / Double(total) : 0, color: color)
            Text(Fmt.bytes(Int64(bytes))).font(.system(size: 9.5, weight: .semibold, design: .monospaced)).foregroundStyle(p.tertiaryText).frame(width: 62, alignment: .trailing)
        }
    }
}

// MARK: - Multi-serie trend-chart med grid
struct TrendChart: View {
    var series: [(values: [Double], color: Color)]
    var gridColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // horisontella grindlinjer 0/25/50/75/100
                ForEach(0..<5, id: \.self) { i in
                    Path { path in
                        let y = h * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(gridColor, lineWidth: 0.7)
                }
                ForEach(series.indices, id: \.self) { idx in
                    let vals = series[idx].values
                    if vals.count > 1 {
                        let stepX = w / CGFloat(max(vals.count - 1, 1))
                        Path { path in
                            for (i, v) in vals.enumerated() {
                                let x = CGFloat(i) * stepX
                                let y = h - CGFloat(v / 100) * h
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(series[idx].color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    }
                }
            }
        }
    }
}
