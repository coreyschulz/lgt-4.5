//
//  GlassPreset.swift
//  liquid-glass-terminal
//
//  Preset configurations for Liquid Glass effects.
//

import SwiftUI

struct GlassPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var variant: GlassVariant
    var shape: GlassShape
    var cornerRadius: CGFloat
    var tintColor: CodableColor
    var tintEnabled: Bool
    var saturation: Double
    var brightness: Double
    var isInteractive: Bool
    var containerSpacing: CGFloat
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        variant: GlassVariant,
        shape: GlassShape,
        cornerRadius: CGFloat = 12.0,
        tintColor: CodableColor = .clear,
        tintEnabled: Bool = false,
        saturation: Double = 1.0,
        brightness: Double = 0.0,
        isInteractive: Bool = false,
        containerSpacing: CGFloat = 8.0,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.variant = variant
        self.shape = shape
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.tintEnabled = tintEnabled
        self.saturation = saturation
        self.brightness = brightness
        self.isInteractive = isInteractive
        self.containerSpacing = containerSpacing
        self.isBuiltIn = isBuiltIn
    }

    // MARK: - Built-in Presets

    static let builtIn: [GlassPreset] = [
        GlassPreset(
            name: "Classic",
            variant: .regular,
            shape: .rect,
            cornerRadius: 0,
            tintColor: .clear,
            tintEnabled: false,
            saturation: 1.0,
            brightness: 0.0,
            isInteractive: false,
            containerSpacing: 8.0,
            isBuiltIn: true
        ),
        GlassPreset(
            name: "Frosted Pill",
            variant: .regular,
            shape: .capsule,
            cornerRadius: 0,
            tintColor: CodableColor(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.1),
            tintEnabled: true,
            saturation: 1.2,
            brightness: 0.05,
            isInteractive: true,
            containerSpacing: 12.0,
            isBuiltIn: true
        ),
        GlassPreset(
            name: "Crystal Clear",
            variant: .clear,
            shape: .roundedRect,
            cornerRadius: 20,
            tintColor: .clear,
            tintEnabled: false,
            saturation: 1.0,
            brightness: 0.0,
            isInteractive: false,
            containerSpacing: 16.0,
            isBuiltIn: true
        ),
        GlassPreset(
            name: "Ocean",
            variant: .regular,
            shape: .roundedRect,
            cornerRadius: 16,
            tintColor: CodableColor(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.15),
            tintEnabled: true,
            saturation: 1.1,
            brightness: 0.0,
            isInteractive: false,
            containerSpacing: 8.0,
            isBuiltIn: true
        ),
        GlassPreset(
            name: "Sunset",
            variant: .regular,
            shape: .roundedRect,
            cornerRadius: 24,
            tintColor: CodableColor(red: 1.0, green: 0.4, blue: 0.2, opacity: 0.12),
            tintEnabled: true,
            saturation: 1.3,
            brightness: 0.03,
            isInteractive: true,
            containerSpacing: 10.0,
            isBuiltIn: true
        ),
        GlassPreset(
            name: "Neon",
            variant: .clear,
            shape: .roundedRect,
            cornerRadius: 12,
            tintColor: CodableColor(red: 0.686, green: 0.322, blue: 0.871, opacity: 0.2),
            tintEnabled: true,
            saturation: 1.5,
            brightness: 0.08,
            isInteractive: true,
            containerSpacing: 6.0,
            isBuiltIn: true
        )
    ]

    // MARK: - Apply to Settings

    func apply(to settings: GlassEffectSettings) {
        settings.variant = variant
        settings.shape = shape
        settings.cornerRadius = cornerRadius
        settings.tintColor = tintColor
        settings.tintEnabled = tintEnabled
        settings.saturation = saturation
        settings.brightness = brightness
        settings.isInteractive = isInteractive
        settings.containerSpacing = containerSpacing
        settings.selectedPresetID = id
    }

    // MARK: - Create from Settings

    static func from(settings: GlassEffectSettings, name: String) -> GlassPreset {
        GlassPreset(
            name: name,
            variant: settings.variant,
            shape: settings.shape,
            cornerRadius: settings.cornerRadius,
            tintColor: settings.tintColor,
            tintEnabled: settings.tintEnabled,
            saturation: settings.saturation,
            brightness: settings.brightness,
            isInteractive: settings.isInteractive,
            containerSpacing: settings.containerSpacing,
            isBuiltIn: false
        )
    }
}

// MARK: - Preset Manager

@Observable
final class PresetManager {
    var customPresets: [GlassPreset] = []

    var allPresets: [GlassPreset] {
        GlassPreset.builtIn + customPresets
    }

    private static let userDefaultsKey = "glassPresets.custom"

    init() {
        load()
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([GlassPreset].self, from: data) else {
            return
        }
        customPresets = decoded
    }

    func addPreset(_ preset: GlassPreset) {
        customPresets.append(preset)
        save()
    }

    func removePreset(_ preset: GlassPreset) {
        customPresets.removeAll { $0.id == preset.id }
        save()
    }
}
