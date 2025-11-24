//
//  TintControl.swift
//  liquid-glass-terminal
//
//  Control for glass tint color and opacity.
//

import SwiftUI

struct TintControl: View {
    @Binding var tintEnabled: Bool
    @Binding var tintColor: CodableColor

    @State private var selectedColor: Color = .blue
    @State private var opacity: Double = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Tint", systemImage: "paintpalette")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $tintEnabled)
                    .labelsHidden()
            }

            if tintEnabled {
                VStack(spacing: 12) {
                    HStack {
                        ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()

                        // Quick color swatches
                        HStack(spacing: 8) {
                            colorSwatch(.blue)
                            colorSwatch(.purple)
                            colorSwatch(.green)
                            colorSwatch(.orange)
                            colorSwatch(.pink)
                        }
                    }

                    LabeledSlider(
                        label: "Opacity",
                        value: $opacity,
                        range: 0...1,
                        step: 0.01,
                        format: "%.0f",
                        unit: "%"
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
        .animation(.easeInOut(duration: 0.2), value: tintEnabled)
        .onChange(of: selectedColor) { _, newColor in
            updateTintColor()
        }
        .onChange(of: opacity) { _, _ in
            updateTintColor()
        }
        .onAppear {
            // Initialize local state from tintColor
            selectedColor = Color(red: tintColor.red, green: tintColor.green, blue: tintColor.blue)
            opacity = tintColor.opacity
        }
    }

    private func updateTintColor() {
        // Convert SwiftUI Color to RGB components
        let nsColor = NSColor(selectedColor)
        // Convert to RGB color space first
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return }
        tintColor = CodableColor(
            red: rgbColor.redComponent,
            green: rgbColor.greenComponent,
            blue: rgbColor.blueComponent,
            opacity: opacity
        )
    }

    private func colorSwatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .onTapGesture {
                selectedColor = color
            }
    }
}

#Preview {
    VStack {
        TintControl(
            tintEnabled: .constant(true),
            tintColor: .constant(.blue)
        )
        TintControl(
            tintEnabled: .constant(false),
            tintColor: .constant(.blue)
        )
    }
    .padding()
    .frame(width: 350)
}
