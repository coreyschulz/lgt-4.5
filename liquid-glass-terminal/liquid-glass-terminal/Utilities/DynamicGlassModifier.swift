//
//  DynamicGlassModifier.swift
//  liquid-glass-terminal
//
//  ViewModifier that applies Liquid Glass effect based on settings.
//

import SwiftUI

// MARK: - Dynamic Glass Modifier

struct DynamicGlassModifier: ViewModifier {
    let settings: GlassEffectSettings

    func body(content: Content) -> some View {
        content
            .modifier(GlassEffectApplier(settings: settings))
            .saturation(settings.saturation)
            .brightness(settings.brightness)
            .overlay {
                if settings.tintEnabled {
                    tintOverlay
                }
            }
    }

    @ViewBuilder
    private var tintOverlay: some View {
        switch settings.shape {
        case .rect:
            Rectangle()
                .fill(settings.tintColor.color)
                .allowsHitTesting(false)
        case .capsule:
            Capsule()
                .fill(settings.tintColor.color)
                .allowsHitTesting(false)
        case .circle:
            Circle()
                .fill(settings.tintColor.color)
                .allowsHitTesting(false)
        case .ellipse:
            Ellipse()
                .fill(settings.tintColor.color)
                .allowsHitTesting(false)
        case .roundedRect:
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .fill(settings.tintColor.color)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Glass Effect Applier

private struct GlassEffectApplier: ViewModifier {
    let settings: GlassEffectSettings

    func body(content: Content) -> some View {
        switch settings.variant {
        case .regular:
            applyRegular(content: content)
        case .clear:
            applyClear(content: content)
        case .identity:
            content
        }
    }

    @ViewBuilder
    private func applyRegular(content: Content) -> some View {
        switch settings.shape {
        case .rect:
            content.glassEffect(.regular, in: .rect)
        case .capsule:
            content.glassEffect(.regular, in: Capsule())
        case .circle:
            content.glassEffect(.regular, in: Circle())
        case .ellipse:
            content.glassEffect(.regular, in: Ellipse())
        case .roundedRect:
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: settings.cornerRadius))
        }
    }

    @ViewBuilder
    private func applyClear(content: Content) -> some View {
        switch settings.shape {
        case .rect:
            content.glassEffect(.clear, in: .rect)
        case .capsule:
            content.glassEffect(.clear, in: Capsule())
        case .circle:
            content.glassEffect(.clear, in: Circle())
        case .ellipse:
            content.glassEffect(.clear, in: Ellipse())
        case .roundedRect:
            content.glassEffect(.clear, in: RoundedRectangle(cornerRadius: settings.cornerRadius))
        }
    }
}

// MARK: - View Extension

extension View {
    func dynamicGlassEffect(_ settings: GlassEffectSettings) -> some View {
        modifier(DynamicGlassModifier(settings: settings))
    }
}
