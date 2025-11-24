//
//  VariantControl.swift
//  liquid-glass-terminal
//
//  Control for selecting glass effect variant.
//

import SwiftUI

struct VariantControl: View {
    @Binding var variant: GlassVariant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Variant", systemImage: "square.3.layers.3d")
                .font(.headline)

            Picker("Variant", selection: $variant) {
                ForEach(GlassVariant.allCases) { v in
                    Text(v.displayName).tag(v)
                }
            }
            .pickerStyle(.segmented)

            Text(variant.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    VariantControl(variant: .constant(.regular))
        .padding()
        .frame(width: 350)
}
