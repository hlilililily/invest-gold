import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var valueColor: Color = .primary
    var icon: String? = nil
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: compact ? 10 : 11, weight: .semibold))
                        .foregroundStyle(Color("BrandGold"))
                }
                Text(title)
                    .font(.system(size: compact ? 11 : 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(compact ? .subheadline : .title3, design: .rounded, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 12 : 14)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }
}

struct HeroStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(.white.opacity(0.12))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 10) {
            StatCard(title: "持仓", value: "100g", icon: "scalemass")
            StatCard(title: "收益", value: "+¥1,200.00", valueColor: GoldTheme.profit, icon: "chart.line.uptrend.xyaxis")
        }
        HeroStatCard(title: "总市值", value: "¥120,000.00", subtitle: "+12.5%", icon: "chart.bar.fill")
            .background(GoldTheme.richGold)
            .clipShape(RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous))
    }
    .padding()
}
