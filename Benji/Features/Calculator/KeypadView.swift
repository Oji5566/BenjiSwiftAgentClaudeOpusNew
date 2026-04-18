import SwiftUI

/// Native numeric keypad used by the calculator. Designed to feel like
/// the iOS Calculator / Apple Pay numeric pad — large rounded buttons,
/// haptics, system materials.
struct KeypadView: View {
    var onKey: (String) -> Void
    var onEnter: () -> Void

    private let layout: [[Key]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.dot,        .digit("0"), .backspace]
    ]

    enum Key: Hashable {
        case digit(String), dot, backspace
        var label: String {
            switch self {
            case .digit(let s): return s
            case .dot: return "."
            case .backspace: return "⌫"
            }
        }
        var accessibilityLabel: String {
            switch self {
            case .digit(let s): return s
            case .dot: return "decimal point"
            case .backspace: return "delete last digit"
            }
        }
        var systemImage: String? {
            switch self {
            case .backspace: return "delete.left"
            default: return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(layout, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
            Button(action: onEnter) {
                Label("Track this amount", systemImage: "arrow.up.circle.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Track this amount")
        }
    }

    @ViewBuilder
    private func keyButton(_ key: Key) -> some View {
        Button {
            switch key {
            case .digit(let s): onKey(s)
            case .dot: onKey(".")
            case .backspace: onKey("backspace")
            }
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            Group {
                if let sym = key.systemImage {
                    Image(systemName: sym)
                } else {
                    Text(key.label)
                }
            }
            .font(.title.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key.accessibilityLabel)
    }
}
