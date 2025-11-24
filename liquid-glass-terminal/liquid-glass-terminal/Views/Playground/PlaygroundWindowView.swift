//
//  PlaygroundWindowView.swift
//  liquid-glass-terminal
//
//  Root view for the Liquid Glass Playground window.
//

import SwiftUI

struct PlaygroundWindowView: View {
    @Environment(\.glassSettings) var settings
    @State private var presetManager = PresetManager()
    @State private var showingSavePreset = false
    @State private var newPresetName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                header

                // Live Preview
                LivePreviewView()

                // Presets
                presetSection

                // Controls
                controlsSection

                // Morphing Demo
                MorphingDemoView()

                // Code Output
                CodeSnippetView()
            }
            .padding()
        }
        .frame(minWidth: 380, maxWidth: 450)
        .background {
            // Glass background for the entire playground window
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: .rect)
        .sheet(isPresented: $showingSavePreset) {
            savePresetSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Glass Playground")
                    .font(.title2.bold())
                Text("Experiment with Liquid Glass settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Reset") {
                withAnimation(.spring(duration: 0.3)) {
                    settings.reset()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Presets Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Presets", systemImage: "square.grid.2x2")
                    .font(.headline)
                Spacer()
                Button {
                    newPresetName = ""
                    showingSavePreset = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presetManager.allPresets) { preset in
                        presetButton(preset)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    private func presetButton(_ preset: GlassPreset) -> some View {
        Button {
            withAnimation(.spring(duration: 0.4)) {
                preset.apply(to: settings)
            }
        } label: {
            VStack(spacing: 6) {
                // Mini preview
                RoundedRectangle(cornerRadius: 6)
                    .fill(preset.tintEnabled ? preset.tintColor.color : Color.white.opacity(0.2))
                    .frame(width: 50, height: 35)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                Text(preset.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(settings.selectedPresetID == preset.id ? Color.blue.opacity(0.3) : Color.clear)
                    .stroke(settings.selectedPresetID == preset.id ? Color.blue : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !preset.isBuiltIn {
                Button(role: .destructive) {
                    presetManager.removePreset(preset)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            VariantControl(variant: Binding(
                get: { settings.variant },
                set: { settings.variant = $0 }
            ))

            ShapeControl(
                shape: Binding(get: { settings.shape }, set: { settings.shape = $0 }),
                cornerRadius: Binding(get: { settings.cornerRadius }, set: { settings.cornerRadius = $0 })
            )

            TintControl(
                tintEnabled: Binding(get: { settings.tintEnabled }, set: { settings.tintEnabled = $0 }),
                tintColor: Binding(get: { settings.tintColor }, set: { settings.tintColor = $0 })
            )

            ModifiersControl(
                saturation: Binding(get: { settings.saturation }, set: { settings.saturation = $0 }),
                brightness: Binding(get: { settings.brightness }, set: { settings.brightness = $0 }),
                containerSpacing: Binding(get: { settings.containerSpacing }, set: { settings.containerSpacing = $0 }),
                isInteractive: Binding(get: { settings.isInteractive }, set: { settings.isInteractive = $0 })
            )
        }
    }

    // MARK: - Save Preset Sheet

    private var savePresetSheet: some View {
        VStack(spacing: 20) {
            Text("Save as Preset")
                .font(.headline)

            TextField("Preset Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingSavePreset = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    let preset = GlassPreset.from(settings: settings, name: newPresetName)
                    presetManager.addPreset(preset)
                    settings.selectedPresetID = preset.id
                    showingSavePreset = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 300)
    }
}

#Preview {
    PlaygroundWindowView()
        .environment(\.glassSettings, GlassEffectSettings())
        .frame(width: 400, height: 800)
}
