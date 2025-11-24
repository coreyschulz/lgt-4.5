//
//  LivePreviewView.swift
//  liquid-glass-terminal
//
//  Live preview of glass effect settings with sample elements.
//

import SwiftUI

struct LivePreviewView: View {
    @Environment(\.glassSettings) var settings

    var body: some View {
        VStack(spacing: 16) {
            Text("Live Preview")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Preview area with gradient background
            ZStack {
                // Background gradient to show glass effect
                LinearGradient(
                    colors: [.purple, .blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.6)

                // Sample image pattern
                Image(systemName: "app.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.2))

                // Glass effect container with sample elements
                GlassEffectContainer(spacing: settings.containerSpacing) {
                    VStack(spacing: settings.containerSpacing) {
                        // Main sample element
                        sampleElement(label: "Sample Glass", icon: "sparkles")
                            .frame(height: 80)

                        // Row of smaller elements
                        HStack(spacing: settings.containerSpacing) {
                            sampleElement(label: "A", icon: "star.fill")
                                .frame(width: 70, height: 70)
                            sampleElement(label: "B", icon: "heart.fill")
                                .frame(width: 70, height: 70)
                            sampleElement(label: "C", icon: "bolt.fill")
                                .frame(width: 70, height: 70)
                        }
                    }
                    .padding()
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.2))
        }
    }

    @ViewBuilder
    private func sampleElement(label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.primary)
        .dynamicGlassEffect(settings)
    }
}

// MARK: - Simple Preview (without container for testing individual shapes)

struct SimpleGlassPreview: View {
    @Environment(\.glassSettings) var settings

    var body: some View {
        VStack(spacing: 8) {
            Text("Shape Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                // Background
                LinearGradient(
                    colors: [.orange, .pink, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.5)

                // Glass element
                VStack {
                    Image(systemName: "cube.transparent")
                        .font(.largeTitle)
                    Text(settings.shape.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.primary)
                .frame(width: 120, height: 100)
                .dynamicGlassEffect(settings)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    LivePreviewView()
        .environment(\.glassSettings, GlassEffectSettings())
        .frame(width: 350)
        .padding()
}
