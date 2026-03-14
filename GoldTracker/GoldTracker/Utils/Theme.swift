import SwiftUI

// MARK: - Design Tokens

enum GoldTheme {
    // Brand gold palette
    static let gold = Color("BrandGold", bundle: nil)
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xF5C518), Color(hex: 0xD4A94F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let richGold = LinearGradient(
        colors: [Color(hex: 0xFFD700), Color(hex: 0xF5A623), Color(hex: 0xC8963E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Semantic colors
    static let profit = Color(hex: 0x34C759)
    static let loss = Color(hex: 0xFF3B30)
    static let neutral = Color.secondary

    // Card
    static let cardRadius: CGFloat = 20
    static let innerRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 12

    static func profitColor(_ value: Double) -> Color {
        if value > 0 { return profit }
        if value < 0 { return loss }
        return neutral
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    // Cross-platform system colors
    static var appBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var appSecondaryBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var appGroupedBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

// MARK: - View Modifiers

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
    }
}

struct ElevatedCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color.appBackground)
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
            }
    }
}

struct SurfaceCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                    .fill(Color.appSecondaryBackground)
            }
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }

    func elevatedCard() -> some View {
        modifier(ElevatedCard())
    }

    func surfaceCard() -> some View {
        modifier(SurfaceCard())
    }
}

// MARK: - Custom Label Styles

struct GoldTabLabelStyle: LabelStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            configuration.title
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
        }
    }
}

// MARK: - Animated Number

struct AnimatedNumber: View {
    let value: Double
    let formatter: (Double) -> String
    var font: Font = .system(.title, design: .rounded, weight: .bold)
    var color: Color = .primary

    @State private var displayValue: Double = 0

    var body: some View {
        Text(formatter(displayValue))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayValue))
            .onChange(of: value, initial: true) { _, newValue in
                withAnimation(.spring(duration: 0.6)) {
                    displayValue = newValue
                }
            }
    }
}
