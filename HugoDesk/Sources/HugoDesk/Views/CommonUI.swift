import SwiftUI

struct ModernCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ScopeBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct SettingRow<Content: View>: View {
    let key: String
    let title: String
    let helpText: String
    let scope: String
    @ViewBuilder var field: Content

    init(
        key: String,
        title: String,
        helpText: String,
        scope: String,
        @ViewBuilder field: () -> Content
    ) {
        self.key = key
        self.title = title
        self.helpText = helpText
        self.scope = scope
        self.field = field()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body)
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .help(helpText)
                }
                HStack(spacing: 8) {
                    Text(key)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    ScopeBadge(text: scope)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            field
                .frame(width: 360, alignment: .trailing)
        }
    }
}
