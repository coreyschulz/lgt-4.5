//
//  CursorView.swift
//  liquid-glass-terminal
//
//  Blinking cursor view with glass styling.
//

import SwiftUI

/// Blinking cursor view
struct CursorView: View {
    let cursor: CursorState
    let font: TerminalFont
    let isVisible: Bool

    var body: some View {
        Group {
            if cursor.visible && isVisible {
                cursorContent
            }
        }
    }

    @ViewBuilder
    private var cursorContent: some View {
        switch cursor.style {
        case .block:
            RoundedRectangle(cornerRadius: 2)
                .fill(TerminalColorPalette.cursor)
                .frame(width: font.characterWidth, height: font.lineHeight)
                .shadow(color: .white.opacity(0.3), radius: 2)
        case .underline:
            Rectangle()
                .fill(TerminalColorPalette.cursor)
                .frame(width: font.characterWidth, height: 2)
                .shadow(color: .white.opacity(0.3), radius: 2)
        case .bar:
            Rectangle()
                .fill(TerminalColorPalette.cursor)
                .frame(width: 2, height: font.lineHeight)
                .shadow(color: .white.opacity(0.3), radius: 2)
        }
    }
}

/// Standalone animated cursor for overlay use
struct AnimatedCursor: View {
    let style: CursorState.CursorStyle
    let font: TerminalFont
    let visible: Bool

    @State private var opacity: Double = 1.0

    var body: some View {
        Group {
            if visible {
                cursorContent
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            opacity = 0.3
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var cursorContent: some View {
        switch style {
        case .block:
            RoundedRectangle(cornerRadius: 2)
                .fill(TerminalColorPalette.cursor)
                .frame(width: font.characterWidth, height: font.lineHeight)
                .shadow(color: .white.opacity(0.4), radius: 3)
        case .underline:
            Rectangle()
                .fill(TerminalColorPalette.cursor)
                .frame(width: font.characterWidth, height: 2)
                .shadow(color: .white.opacity(0.4), radius: 3)
        case .bar:
            Rectangle()
                .fill(TerminalColorPalette.cursor)
                .frame(width: 2, height: font.lineHeight)
                .shadow(color: .white.opacity(0.4), radius: 3)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        VStack {
            Text("Block")
                .font(.caption)
            AnimatedCursor(style: .block, font: .default, visible: true)
        }

        VStack {
            Text("Underline")
                .font(.caption)
            AnimatedCursor(style: .underline, font: .default, visible: true)
        }

        VStack {
            Text("Bar")
                .font(.caption)
            AnimatedCursor(style: .bar, font: .default, visible: true)
        }
    }
    .padding(40)
    .background(Color.black.opacity(0.5))
    .glassEffect(.regular)
}
