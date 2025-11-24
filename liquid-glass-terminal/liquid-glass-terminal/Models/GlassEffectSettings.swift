//
//  GlassEffectSettings.swift
//  liquid-glass-terminal
//
//  Central settings model for Liquid Glass effect parameters.
//

import SwiftUI

// MARK: - Glass Variant

enum GlassVariant: String, CaseIterable, Codable, Identifiable {
    case regular
    case clear
    case identity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .clear: return "Clear"
        case .identity: return "Identity"
        }
    }

    var description: String {
        switch self {
        case .regular: return "Frosted glass, best for most UI"
        case .clear: return "Transparent, dramatic liquid effect"
        case .identity: return "Disabled, no glass effect"
        }
    }
}

// MARK: - Glass Shape

enum GlassShape: String, CaseIterable, Codable, Identifiable {
    case rect
    case capsule
    case circle
    case ellipse
    case roundedRect

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rect: return "Rectangle"
        case .capsule: return "Capsule"
        case .circle: return "Circle"
        case .ellipse: return "Ellipse"
        case .roundedRect: return "Rounded Rect"
        }
    }
}

// MARK: - Codable Color

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        // Default fallback - will be updated when color is resolved
        self.red = 0.5
        self.green = 0.5
        self.blue = 1.0
        self.opacity = 1.0
    }

    var color: Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }

    var hexString: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static let clear = CodableColor(red: 0, green: 0, blue: 0, opacity: 0)
    static let blue = CodableColor(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.3)
    static let purple = CodableColor(red: 0.686, green: 0.322, blue: 0.871, opacity: 0.3)
    static let green = CodableColor(red: 0.204, green: 0.780, blue: 0.349, opacity: 0.3)
    static let orange = CodableColor(red: 1.0, green: 0.584, blue: 0.0, opacity: 0.3)
}

// MARK: - Glass Effect Settings

@Observable
final class GlassEffectSettings {
    // Core glass effect
    var variant: GlassVariant = .regular
    var shape: GlassShape = .rect
    var cornerRadius: CGFloat = 12.0

    // Tint
    var tintEnabled: Bool = false
    var tintColor: CodableColor = .blue

    // Interactive
    var isInteractive: Bool = false

    // Container
    var containerSpacing: CGFloat = 8.0

    // Visual modifiers
    var saturation: Double = 1.0
    var brightness: Double = 0.0

    // Presets (will be populated from GlassPreset)
    var selectedPresetID: UUID?

    init() {}

    // MARK: - Reset

    func reset() {
        variant = .regular
        shape = .rect
        cornerRadius = 12.0
        tintEnabled = false
        tintColor = .blue
        isInteractive = false
        containerSpacing = 8.0
        saturation = 1.0
        brightness = 0.0
        selectedPresetID = nil
    }

    // MARK: - Persistence

    private static let userDefaultsKey = "glassEffectSettings"

    func save() {
        let data = SettingsData(
            variant: variant,
            shape: shape,
            cornerRadius: cornerRadius,
            tintEnabled: tintEnabled,
            tintColor: tintColor,
            isInteractive: isInteractive,
            containerSpacing: containerSpacing,
            saturation: saturation,
            brightness: brightness
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    static func load() -> GlassEffectSettings {
        let settings = GlassEffectSettings()
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) else {
            return settings
        }
        settings.variant = decoded.variant
        settings.shape = decoded.shape
        settings.cornerRadius = decoded.cornerRadius
        settings.tintEnabled = decoded.tintEnabled
        settings.tintColor = decoded.tintColor
        settings.isInteractive = decoded.isInteractive
        settings.containerSpacing = decoded.containerSpacing
        settings.saturation = decoded.saturation
        settings.brightness = decoded.brightness
        return settings
    }

    // Codable wrapper for persistence
    private struct SettingsData: Codable {
        let variant: GlassVariant
        let shape: GlassShape
        let cornerRadius: CGFloat
        let tintEnabled: Bool
        let tintColor: CodableColor
        let isInteractive: Bool
        let containerSpacing: CGFloat
        let saturation: Double
        let brightness: Double
    }
}

// MARK: - Environment Key

private struct GlassEffectSettingsKey: EnvironmentKey {
    static let defaultValue: GlassEffectSettings = GlassEffectSettings()
}

extension EnvironmentValues {
    var glassSettings: GlassEffectSettings {
        get { self[GlassEffectSettingsKey.self] }
        set { self[GlassEffectSettingsKey.self] = newValue }
    }
}
