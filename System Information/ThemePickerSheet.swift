import SwiftUI

// MARK: - Temaval (flik överst i sheet)
struct ThemePickerSheet: View {
    @EnvironmentObject private var themes: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selected: AppTheme = ThemeManager.shared.theme

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().environment(\.palette, selected.palette)
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Varje tema ger appen en helt egen känsla.")
                            .font(.subheadline)
                            .foregroundStyle(selected.palette.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        ForEach(AppTheme.allCases) { t in
                            ThemeRow(theme: t, isSelected: selected == t)
                                .onTapGesture { selected = t }
                        }

                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                themes.theme = selected
                            }
                            dismiss()
                        } label: {
                            Text("Tillämpa \(selected.displayName)")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(colors: selected.palette.accentGradient, startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                                .shadow(color: selected.palette.accent.opacity(0.5), radius: 10, y: 5)
                        }
                        .padding(.top, 6)
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 18)
                }
                .environment(\.palette, selected.palette)
            }
            .navigationTitle("Teman")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klart") { dismiss() }
                        .foregroundStyle(selected.palette.accent)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ThemeRow: View {
    @Environment(\.palette) private var p
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        let pal = theme.palette
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: pal.accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                Image(systemName: theme.displayIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(p.primaryText)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle().fill(swatch(i, pal)).frame(width: 12, height: 12)
                    }
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? p.accent : p.tertiaryText)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(p.cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSelected ? AnyShapeStyle(LinearGradient(colors: pal.accentGradient, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(p.cardStroke),
                              lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(p.colorScheme == .light ? 0.05 : 0.3), radius: 8, y: 4)
    }

    private func swatch(_ i: Int, _ pal: Palette) -> Color {
        switch i {
        case 0: return pal.backgroundBottom
        case 1: return pal.cardFill
        case 2: return pal.accent
        default: return pal.secondary
        }
    }
}
