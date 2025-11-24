//
//  ShapeControl.swift
//  liquid-glass-terminal
//
//  Control for selecting glass effect shape and corner radius.
//

import SwiftUI

struct ShapeControl: View {
    @Binding var shape: GlassShape
    @Binding var cornerRadius: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Shape", systemImage: "square.on.circle")
                .font(.headline)

            Picker("Shape", selection: $shape) {
                ForEach(GlassShape.allCases) { s in
                    HStack {
                        shapeIcon(for: s)
                        Text(s.displayName)
                    }
                    .tag(s)
                }
            }
            .pickerStyle(.menu)

            if shape == .roundedRect {
                LabeledCGFloatSlider(
                    label: "Corner Radius",
                    value: $cornerRadius,
                    range: 0...50,
                    step: 1,
                    format: "%.0f",
                    unit: " pt"
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
        .animation(.easeInOut(duration: 0.2), value: shape)
    }

    @ViewBuilder
    private func shapeIcon(for shape: GlassShape) -> some View {
        switch shape {
        case .rect:
            Image(systemName: "rectangle.fill")
        case .capsule:
            Image(systemName: "capsule.fill")
        case .circle:
            Image(systemName: "circle.fill")
        case .ellipse:
            Image(systemName: "oval.fill")
        case .roundedRect:
            Image(systemName: "rectangle.roundedtop.fill")
        }
    }
}

#Preview {
    VStack {
        ShapeControl(shape: .constant(.roundedRect), cornerRadius: .constant(12))
        ShapeControl(shape: .constant(.capsule), cornerRadius: .constant(12))
    }
    .padding()
    .frame(width: 350)
}
