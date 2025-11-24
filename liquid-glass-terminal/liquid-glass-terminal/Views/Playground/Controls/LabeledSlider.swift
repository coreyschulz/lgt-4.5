//
//  LabeledSlider.swift
//  liquid-glass-terminal
//
//  Reusable slider component with label and value display.
//

import SwiftUI

struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    var format: String = "%.2f"
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, value) + unit)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(.blue)
        }
    }
}

struct LabeledCGFloatSlider: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    var step: CGFloat = 1
    var format: String = "%.0f"
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, Double(value)) + unit)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = CGFloat($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
                .tint(.blue)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LabeledSlider(
            label: "Saturation",
            value: .constant(1.5),
            range: 0...3,
            format: "%.1f"
        )

        LabeledCGFloatSlider(
            label: "Corner Radius",
            value: .constant(12),
            range: 0...50,
            format: "%.0f",
            unit: " pt"
        )
    }
    .padding()
    .frame(width: 300)
}
