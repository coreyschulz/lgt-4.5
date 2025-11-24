//
//  TerminalLineView.swift
//  liquid-glass-terminal
//
//  Renders a single line of terminal text with ANSI styling.
//

import SwiftUI

/// Renders a single terminal line with attributed text
struct TerminalLineView: View {
    let line: TerminalLine
    let colorPalette: [Color]
    let font: TerminalFont

    var body: some View {
        Text(line.toAttributedString(colorPalette: colorPalette))
            .font(font.font)
            .textSelection(.enabled)
            // Shadow for better legibility on glass
            .shadow(color: .black.opacity(0.6), radius: 0.5, x: 0, y: 0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: font.lineHeight)
    }
}

/// Preview with sample colored text
#Preview {
    VStack(alignment: .leading, spacing: 0) {
        // Create sample lines with colors
        let sampleLine = createSampleLine()
        TerminalLineView(
            line: sampleLine,
            colorPalette: TerminalColorPalette.standard,
            font: .default
        )

        // Plain text line
        let plainLine = TerminalLine(cells: "Hello, world!".map {
            TerminalCell(character: $0)
        })
        TerminalLineView(
            line: plainLine,
            colorPalette: TerminalColorPalette.standard,
            font: .default
        )
    }
    .padding()
    .background(Color.black.opacity(0.3))
    .glassEffect(.regular)
}

/// Create a sample line with various colors for preview
private func createSampleLine() -> TerminalLine {
    var cells: [TerminalCell] = []

    // Add colored text
    let colors: [(String, TerminalColor)] = [
        ("Red ", .ansi(1)),
        ("Green ", .ansi(2)),
        ("Yellow ", .ansi(3)),
        ("Blue ", .ansi(4)),
        ("Magenta ", .ansi(5)),
        ("Cyan", .ansi(6)),
    ]

    for (text, color) in colors {
        for char in text {
            cells.append(TerminalCell(
                character: char,
                foreground: color,
                background: .default,
                attributes: []
            ))
        }
    }

    return TerminalLine(cells: cells)
}
