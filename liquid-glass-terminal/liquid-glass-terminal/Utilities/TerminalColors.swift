//
//  TerminalColors.swift
//  liquid-glass-terminal
//
//  Color palette definitions optimized for Liquid Glass backgrounds.
//

import SwiftUI

/// Color palette for the terminal, optimized for glass backgrounds
struct TerminalColorPalette {
    /// Standard 16-color ANSI palette optimized for glass backgrounds
    /// Colors are boosted for better visibility over transparent glass
    static let standard: [Color] = [
        // Standard colors (0-7)
        Color(red: 0.15, green: 0.15, blue: 0.15),  // 0: Black (slightly lighter for visibility)
        Color(red: 1.00, green: 0.40, blue: 0.40),  // 1: Red
        Color(red: 0.40, green: 1.00, blue: 0.60),  // 2: Green
        Color(red: 1.00, green: 0.90, blue: 0.40),  // 3: Yellow
        Color(red: 0.40, green: 0.70, blue: 1.00),  // 4: Blue
        Color(red: 1.00, green: 0.50, blue: 0.90),  // 5: Magenta
        Color(red: 0.40, green: 0.90, blue: 0.90),  // 6: Cyan
        Color(red: 0.90, green: 0.90, blue: 0.90),  // 7: White

        // Bright colors (8-15)
        Color(red: 0.50, green: 0.50, blue: 0.50),  // 8: Bright Black (Gray)
        Color(red: 1.00, green: 0.55, blue: 0.55),  // 9: Bright Red
        Color(red: 0.55, green: 1.00, blue: 0.70),  // 10: Bright Green
        Color(red: 1.00, green: 0.95, blue: 0.55),  // 11: Bright Yellow
        Color(red: 0.55, green: 0.80, blue: 1.00),  // 12: Bright Blue
        Color(red: 1.00, green: 0.65, blue: 0.95),  // 13: Bright Magenta
        Color(red: 0.55, green: 0.95, blue: 0.95),  // 14: Bright Cyan
        Color(red: 1.00, green: 1.00, blue: 1.00),  // 15: Bright White
    ]

    /// Default foreground color for text
    static let foreground = Color.white

    /// Default background (clear for glass effect)
    static let background = Color.clear

    /// Cursor color
    static let cursor = Color.white.opacity(0.9)

    /// Selection highlight color
    static let selection = Color.blue.opacity(0.4)
}

// MARK: - Color Extensions for Glass

extension Color {
    /// Terminal foreground color optimized for glass
    static let terminalForeground = Color.white

    /// Bright terminal text
    static let terminalBright = Color.white.opacity(0.95)

    /// Dim terminal text
    static let terminalDim = Color.white.opacity(0.6)

    /// ANSI Red optimized for glass
    static let ansiRed = Color(red: 1.0, green: 0.4, blue: 0.4)

    /// ANSI Green optimized for glass
    static let ansiGreen = Color(red: 0.4, green: 1.0, blue: 0.6)

    /// ANSI Yellow optimized for glass
    static let ansiYellow = Color(red: 1.0, green: 0.9, blue: 0.4)

    /// ANSI Blue optimized for glass
    static let ansiBlue = Color(red: 0.4, green: 0.7, blue: 1.0)

    /// ANSI Magenta optimized for glass
    static let ansiMagenta = Color(red: 1.0, green: 0.5, blue: 0.9)

    /// ANSI Cyan optimized for glass
    static let ansiCyan = Color(red: 0.4, green: 0.9, blue: 0.9)
}

// MARK: - Theme Definitions

/// A complete terminal theme
struct TerminalTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let palette: [Color]
    let foreground: Color
    let background: Color
    let cursorColor: Color
    let selectionColor: Color

    static func == (lhs: TerminalTheme, rhs: TerminalTheme) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Default Liquid Glass theme
    static let liquidGlass = TerminalTheme(
        id: "liquid-glass",
        name: "Liquid Glass",
        palette: TerminalColorPalette.standard,
        foreground: .white,
        background: .clear,
        cursorColor: .white.opacity(0.9),
        selectionColor: .blue.opacity(0.4)
    )

    /// Dark theme with slight opacity
    static let dark = TerminalTheme(
        id: "dark",
        name: "Dark",
        palette: [
            // Standard colors
            Color(red: 0.10, green: 0.10, blue: 0.10),
            Color(red: 0.90, green: 0.30, blue: 0.30),
            Color(red: 0.30, green: 0.90, blue: 0.45),
            Color(red: 0.90, green: 0.80, blue: 0.30),
            Color(red: 0.30, green: 0.60, blue: 0.90),
            Color(red: 0.90, green: 0.40, blue: 0.80),
            Color(red: 0.30, green: 0.80, blue: 0.80),
            Color(red: 0.80, green: 0.80, blue: 0.80),
            // Bright colors
            Color(red: 0.45, green: 0.45, blue: 0.45),
            Color(red: 1.00, green: 0.45, blue: 0.45),
            Color(red: 0.45, green: 1.00, blue: 0.60),
            Color(red: 1.00, green: 0.90, blue: 0.45),
            Color(red: 0.45, green: 0.70, blue: 1.00),
            Color(red: 1.00, green: 0.55, blue: 0.90),
            Color(red: 0.45, green: 0.90, blue: 0.90),
            Color(red: 1.00, green: 1.00, blue: 1.00),
        ],
        foreground: Color(white: 0.9),
        background: Color(white: 0.05),
        cursorColor: Color(white: 0.9),
        selectionColor: Color.blue.opacity(0.35)
    )

    /// All available themes
    static let all: [TerminalTheme] = [.liquidGlass, .dark]
}

// MARK: - Font Configuration

/// Terminal font configuration
struct TerminalFont {
    let name: String
    let size: CGFloat

    static let `default` = TerminalFont(name: "Menlo", size: 14)
    static let small = TerminalFont(name: "Menlo", size: 12)
    static let large = TerminalFont(name: "Menlo", size: 16)

    /// Get SwiftUI Font
    var font: Font {
        .system(size: size, design: .monospaced)
    }

    /// Get NSFont for metrics
    var nsFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Character width for this font
    var characterWidth: CGFloat {
        let font = nsFont
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = ("M" as NSString).size(withAttributes: attributes)
        return size.width
    }

    /// Line height for this font (tight spacing for terminal use)
    var lineHeight: CGFloat {
        let font = nsFont
        return font.ascender - font.descender  // No leading for tight terminal spacing
    }
}
