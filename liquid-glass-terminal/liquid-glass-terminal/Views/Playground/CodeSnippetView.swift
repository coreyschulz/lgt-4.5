//
//  CodeSnippetView.swift
//  liquid-glass-terminal
//
//  Displays generated SwiftUI code with copy functionality.
//

import SwiftUI
import AppKit

struct CodeSnippetView: View {
    @Environment(\.glassSettings) var settings
    @State private var copied = false

    private var generatedCode: String {
        CodeGenerator.generate(from: settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Generated Code", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                copyButton
            }

            ScrollView {
                Text(generatedCode)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(maxHeight: 180)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    private var copyButton: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                Text(copied ? "Copied!" : "Copy")
            }
            .font(.caption)
            .foregroundStyle(copied ? .green : .blue)
        }
        .buttonStyle(.plain)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)

        withAnimation {
            copied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
        }
    }
}

#Preview {
    CodeSnippetView()
        .environment(\.glassSettings, {
            let settings = GlassEffectSettings()
            settings.variant = .regular
            settings.shape = .roundedRect
            settings.cornerRadius = 16
            settings.saturation = 1.2
            settings.tintEnabled = true
            return settings
        }())
        .frame(width: 350)
        .padding()
}
