//
//  MorphingDemoView.swift
//  liquid-glass-terminal
//
//  Demonstrates glass effect morphing with glassEffectID.
//

import SwiftUI

struct MorphingDemoView: View {
    @Environment(\.glassSettings) var settings
    @State private var currentShape: Int = 0
    @State private var isAnimating = false
    @Namespace private var morphNamespace

    private let shapes: [(name: String, icon: String)] = [
        ("Rectangle", "rectangle.fill"),
        ("Capsule", "capsule.fill"),
        ("Circle", "circle.fill"),
        ("Rounded", "rectangle.roundedtop.fill")
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Morphing Demo", systemImage: "wand.and.stars")
                    .font(.headline)
                Spacer()
                Button(isAnimating ? "Stop" : "Animate") {
                    toggleAnimation()
                }
                .buttonStyle(.bordered)
            }

            // Demo area
            ZStack {
                LinearGradient(
                    colors: [.indigo, .purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.5)

                // Morphing element
                morphingElement
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Manual shape picker
            HStack(spacing: 12) {
                ForEach(0..<shapes.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            currentShape = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: shapes[index].icon)
                                .font(.title3)
                            Text(shapes[index].name)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(currentShape == index ? Color.blue.opacity(0.3) : Color.clear)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tap shapes or animate to see morphing effect with glassEffectID")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var morphingElement: some View {
        GlassEffectContainer(spacing: 8) {
            VStack {
                Image(systemName: shapes[currentShape].icon)
                    .font(.largeTitle)
                Text(shapes[currentShape].name)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(width: 120, height: 100)
            .modifier(MorphingGlassModifier(
                shape: currentShape,
                variant: settings.variant,
                namespace: morphNamespace
            ))
        }
    }

    private func toggleAnimation() {
        isAnimating.toggle()
        if isAnimating {
            animateShapes()
        }
    }

    private func animateShapes() {
        guard isAnimating else { return }

        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            currentShape = (currentShape + 1) % shapes.count
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            animateShapes()
        }
    }
}

// MARK: - Morphing Glass Modifier

private struct MorphingGlassModifier: ViewModifier {
    let shape: Int
    let variant: GlassVariant
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        switch variant {
        case .identity:
            content
        case .regular:
            applyRegularGlass(to: content)
        case .clear:
            applyClearGlass(to: content)
        }
    }

    @ViewBuilder
    private func applyRegularGlass(to content: Content) -> some View {
        switch shape {
        case 0:
            content
                .glassEffect(.regular, in: Rectangle())
                .glassEffectID(0, in: namespace)
        case 1:
            content
                .glassEffect(.regular, in: Capsule())
                .glassEffectID(0, in: namespace)
        case 2:
            content
                .glassEffect(.regular, in: Circle())
                .glassEffectID(0, in: namespace)
        default:
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                .glassEffectID(0, in: namespace)
        }
    }

    @ViewBuilder
    private func applyClearGlass(to content: Content) -> some View {
        switch shape {
        case 0:
            content
                .glassEffect(.clear, in: Rectangle())
                .glassEffectID(0, in: namespace)
        case 1:
            content
                .glassEffect(.clear, in: Capsule())
                .glassEffectID(0, in: namespace)
        case 2:
            content
                .glassEffect(.clear, in: Circle())
                .glassEffectID(0, in: namespace)
        default:
            content
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
                .glassEffectID(0, in: namespace)
        }
    }
}

#Preview {
    MorphingDemoView()
        .environment(\.glassSettings, GlassEffectSettings())
        .frame(width: 350)
        .padding()
}
