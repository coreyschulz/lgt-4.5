//
//  CodeGenerator.swift
//  liquid-glass-terminal
//
//  Generates SwiftUI code snippets from glass effect settings.
//

import Foundation

struct CodeGenerator {
    static func generate(from settings: GlassEffectSettings) -> String {
        var lines: [String] = []

        // Container note if spacing is custom
        if settings.containerSpacing != 8.0 {
            lines.append("// Wrap in GlassEffectContainer for morphing:")
            lines.append("GlassEffectContainer(spacing: \(Int(settings.containerSpacing))) {")
            lines.append("    // Your content here")
            lines.append("}")
            lines.append("")
        }

        // Main glass effect
        let variant = variantString(settings.variant)
        let shape = shapeString(settings.shape, cornerRadius: settings.cornerRadius)
        let interactive = settings.isInteractive ? ", isInteractive: true" : ""

        if settings.variant == .identity {
            lines.append("// Glass effect disabled (identity)")
        } else {
            lines.append(".glassEffect(\(variant), in: \(shape)\(interactive))")
        }

        // Saturation modifier
        if settings.saturation != 1.0 {
            lines.append(".saturation(\(String(format: "%.1f", settings.saturation)))")
        }

        // Brightness modifier
        if settings.brightness != 0.0 {
            lines.append(".brightness(\(String(format: "%.2f", settings.brightness)))")
        }

        // Tint overlay
        if settings.tintEnabled {
            let hex = settings.tintColor.hexString
            let opacity = String(format: "%.2f", settings.tintColor.opacity)
            lines.append("")
            lines.append("// Tint overlay")
            lines.append(".overlay {")
            lines.append("    Color(hex: \"\(hex)\")")
            lines.append("        .opacity(\(opacity))")
            lines.append("}")
        }

        return lines.joined(separator: "\n")
    }

    private static func variantString(_ variant: GlassVariant) -> String {
        switch variant {
        case .regular: return ".regular"
        case .clear: return ".clear"
        case .identity: return ".identity"
        }
    }

    private static func shapeString(_ shape: GlassShape, cornerRadius: CGFloat) -> String {
        switch shape {
        case .rect: return ".rect"
        case .capsule: return "Capsule()"
        case .circle: return "Circle()"
        case .ellipse: return "Ellipse()"
        case .roundedRect: return "RoundedRectangle(cornerRadius: \(Int(cornerRadius)))"
        }
    }
}
