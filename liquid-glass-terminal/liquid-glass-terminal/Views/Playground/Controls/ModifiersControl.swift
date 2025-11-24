//
//  ModifiersControl.swift
//  liquid-glass-terminal
//
//  Control for saturation, brightness, spacing, and interactive mode.
//

import SwiftUI

struct ModifiersControl: View {
    @Binding var saturation: Double
    @Binding var brightness: Double
    @Binding var containerSpacing: CGFloat
    @Binding var isInteractive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Visual Modifiers", systemImage: "slider.horizontal.3")
                .font(.headline)

            VStack(spacing: 12) {
                LabeledSlider(
                    label: "Saturation",
                    value: $saturation,
                    range: 0...3,
                    step: 0.1,
                    format: "%.1f"
                )

                LabeledSlider(
                    label: "Brightness",
                    value: $brightness,
                    range: -1...1,
                    step: 0.05,
                    format: "%+.2f"
                )
            }

            Divider()

            Label("Container", systemImage: "square.stack.3d.up")
                .font(.headline)

            VStack(spacing: 12) {
                LabeledCGFloatSlider(
                    label: "Spacing",
                    value: $containerSpacing,
                    range: 0...50,
                    step: 1,
                    format: "%.0f",
                    unit: " pt"
                )

                HStack {
                    Text("Interactive")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Toggle("", isOn: $isInteractive)
                        .labelsHidden()
                }

                if isInteractive {
                    Text("Glass responds to hover and press with shimmer effects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
        .animation(.easeInOut(duration: 0.2), value: isInteractive)
    }
}

#Preview {
    ModifiersControl(
        saturation: .constant(1.0),
        brightness: .constant(0.0),
        containerSpacing: .constant(8),
        isInteractive: .constant(false)
    )
    .padding()
    .frame(width: 350)
}
