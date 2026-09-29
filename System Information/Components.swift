import SwiftUI

// MARK: - Bakgrund: gradient + mjuka glowCirklar (i overlay, vidgar aldrig layouten)
struct AppBackground: View {
    @Environment(\.palette) private var p

    var body: some View {
        LinearGradient(colors: [p.backgroundTop, p.backgroundBottom], startPoint: .top, endPoint: .bottom)
            .overlay {
                ZStack {
                    Circle().fill(p.glow1).frame(width: 300, height: 300).blur(radius: 80)
                        .offset(x: -120, y: -240)
                    Circle().fill(p.glow2).frame(width: 260, height: 260).blur(radius: 70)
                        .offset(x: 130, y: 120)
                    Circle().fill(p.glow1).frame(width: 200, height: 200).blur(radius: 60)
                        .offset(x: 60, y: 420)
                }
            }
            .ignoresSafeArea()
    }
}

// MARK: - Kort-wrapper: glasfill + gradient-stroke + skugga
struct GlassCard<Content: View>: View {
    @Environment(\.palette) private var p
    var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .background(p.cardFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: p.accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .opacity(p.colorScheme == .light ? 0.35 : 0.5),
                        lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(p.innerStroke, lineWidth: 0.5)
                    .padding(1)
            )
            .shadow(color: .black.opacity(p.colorScheme == .light ? 0.06 : 0.35), radius: 12, y: 6)
    }
}

// MARK: - Sirkulärt gauge (CPU/RAM/Batt)
struct RingGauge: View {
    @Environment(\.palette) private var p
    var value: Double            // 0-100
    var color: Color
    var icon: String
    var headline: String
    var subline: String
    var series: [Double]
    var size: CGFloat = 128

    var body: some View {
        ZStack {
            Circle()
                .stroke(p.trackFill, lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(1, value / 100))
                .stroke(
                    AngularGradient(colors: [color.opacity(0.55), color], center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: value)

            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.16, weight: .semibold))
                    .foregroundStyle(color)
                Text(headline)
                    .font(.system(size: size * 0.20, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(p.primaryText)
                    .contentTransition(.numericText())
                Text(subline)
                    .font(.system(size: size * 0.085, weight: .medium, design: .monospaced))
                    .foregroundStyle(p.tertiaryText)
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottom) {
            if !series.isEmpty {
                Sparkline(values: series, color: color)
                    .frame(width: size * 0.62, height: 16)
                    .offset(y: 8)
            }
        }
    }
}

// MARK: - Sparkline
struct Sparkline: View {
    var values: [Double]
    var color: Color
    var showFill: Bool = true

    var body: some View {
        GeometryReader { geo in
            let count = max(values.count, 2)
            let stepX = geo.size.width / CGFloat(count - 1)
            let path = linePath(width: geo.size.width, height: geo.size.height, stepX: stepX)

            ZStack {
                if showFill {
                    path.0
                        .fill(LinearGradient(colors: [color.opacity(0.35), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                }
                path.1.stroke(color.opacity(0.9), lineWidth: 1.6)
            }
        }
    }

    private func linePath(width: CGFloat, height: CGFloat, stepX: CGFloat) -> (fill: Path, stroke: Path) {
        var stroke = Path()
        var fill = Path()
        guard values.count > 1 else { return (fill, stroke) }
        let maxV = max(values.max() ?? 1, 1)
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * stepX
            let y = height - (CGFloat(v / maxV) * height * 0.9) - 1
            if i == 0 {
                stroke.move(to: CGPoint(x: x, y: y))
                fill.move(to: CGPoint(x: x, y: height))
                fill.addLine(to: CGPoint(x: x, y: y))
            } else {
                stroke.addLine(to: CGPoint(x: x, y: y))
                fill.addLine(to: CGPoint(x: x, y: y))
            }
        }
        fill.addLine(to: CGPoint(x: width, y: height))
        fill.closeSubpath()
        return (fill, stroke)
    }
}

// MARK: - Horisontell progressbar
struct MeterBar: View {
    @Environment(\.palette) private var p
    var fraction: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(p.trackFill)
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, geo.size.width * min(1, max(0, fraction))))
                    .animation(.easeOut(duration: 0.6), value: fraction)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Rad: label-värde med ikon
struct InfoRow: View {
    @Environment(\.palette) private var p
    var icon: String
    var label: String
    var value: String
    var valueColor: Color? = nil
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor ?? p.accent)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(p.secondaryText)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(valueColor ?? p.primaryText)
                .multilineTextAlignment(.trailing)
                .contentTransition(.identity)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Sektionsrubrik
struct SectionHeader: View {
    @Environment(\.palette) private var p
    var icon: String
    var title: String
    var color: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color ?? p.accent)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(p.secondaryText)
            Spacer()
        }
        .padding(.top, 6)
    }
}
