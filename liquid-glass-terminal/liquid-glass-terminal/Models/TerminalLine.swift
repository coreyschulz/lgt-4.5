//
//  TerminalLine.swift
//  liquid-glass-terminal
//
//  Data models for terminal lines and cells.
//

import Foundation
import SwiftUI
import Combine

/// Represents text attributes for a terminal cell
struct CellAttributes: OptionSet, Hashable, Sendable {
    let rawValue: UInt16

    static let bold = CellAttributes(rawValue: 1 << 0)
    static let italic = CellAttributes(rawValue: 1 << 1)
    static let underline = CellAttributes(rawValue: 1 << 2)
    static let strikethrough = CellAttributes(rawValue: 1 << 3)
    static let inverse = CellAttributes(rawValue: 1 << 4)
    static let dim = CellAttributes(rawValue: 1 << 5)
    static let blink = CellAttributes(rawValue: 1 << 6)
    static let hidden = CellAttributes(rawValue: 1 << 7)
}

/// Represents a color in the terminal (ANSI or RGB)
enum TerminalColor: Hashable, Sendable {
    case `default`
    case ansi(UInt8)           // 0-15 standard colors
    case palette(UInt8)        // 16-255 extended palette
    case rgb(UInt8, UInt8, UInt8)  // True color

    /// Convert to SwiftUI Color
    func toColor(isForeground: Bool, colorPalette: [Color]) -> Color {
        switch self {
        case .default:
            return isForeground ? .white : .clear
        case .ansi(let index):
            if Int(index) < colorPalette.count {
                return colorPalette[Int(index)]
            }
            return isForeground ? .white : .clear
        case .palette(let index):
            return color256(Int(index))
        case .rgb(let r, let g, let b):
            return Color(
                red: Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue: Double(b) / 255.0
            )
        }
    }

    /// Generate 256-color palette color
    private func color256(_ index: Int) -> Color {
        if index < 16 {
            // Standard colors - should use palette
            return .white
        } else if index < 232 {
            // 6x6x6 color cube
            let adjusted = index - 16
            let r = adjusted / 36
            let g = (adjusted / 6) % 6
            let b = adjusted % 6

            let toValue: (Int) -> Double = { $0 == 0 ? 0 : (Double($0) * 40 + 55) / 255 }
            return Color(red: toValue(r), green: toValue(g), blue: toValue(b))
        } else {
            // Grayscale
            let gray = Double((index - 232) * 10 + 8) / 255
            return Color(white: gray)
        }
    }
}

/// A single character cell in the terminal
struct TerminalCell: Hashable, Sendable {
    var character: Character = " "
    var foreground: TerminalColor = .default
    var background: TerminalColor = .default
    var attributes: CellAttributes = []
    var width: Int = 1  // For wide characters (CJK, emoji)

    /// Check if this is an empty/default cell
    var isEmpty: Bool {
        character == " " && foreground == .default && background == .default && attributes.isEmpty
    }
}

/// A line of text in the terminal
struct TerminalLine: Identifiable, Hashable, Sendable {
    let id = UUID()
    var cells: [TerminalCell]
    var wrapped: Bool = false  // True if line wrapped from previous line

    init(columns: Int = 80) {
        cells = Array(repeating: TerminalCell(), count: columns)
    }

    init(cells: [TerminalCell]) {
        self.cells = cells
    }

    /// Get the text content of this line
    var text: String {
        String(cells.map { $0.character })
    }

    /// Get text content trimmed of trailing spaces
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespaces)
    }

    /// Convert to AttributedString for SwiftUI rendering
    func toAttributedString(colorPalette: [Color]) -> AttributedString {
        var result = AttributedString()

        // Group consecutive cells with same attributes for efficiency
        var currentRun = AttributedString()
        var currentFg: TerminalColor = .default
        var currentBg: TerminalColor = .default
        var currentAttrs: CellAttributes = []

        for cell in cells {
            let needsNewRun = cell.foreground != currentFg ||
                              cell.background != currentBg ||
                              cell.attributes != currentAttrs

            if needsNewRun && !currentRun.characters.isEmpty {
                applyAttributes(
                    to: &currentRun,
                    fg: currentFg,
                    bg: currentBg,
                    attrs: currentAttrs,
                    palette: colorPalette
                )
                result.append(currentRun)
                currentRun = AttributedString()
            }

            currentRun.append(AttributedString(String(cell.character)))
            currentFg = cell.foreground
            currentBg = cell.background
            currentAttrs = cell.attributes
        }

        // Append final run
        if !currentRun.characters.isEmpty {
            applyAttributes(
                to: &currentRun,
                fg: currentFg,
                bg: currentBg,
                attrs: currentAttrs,
                palette: colorPalette
            )
            result.append(currentRun)
        }

        return result
    }

    private func applyAttributes(
        to string: inout AttributedString,
        fg: TerminalColor,
        bg: TerminalColor,
        attrs: CellAttributes,
        palette: [Color]
    ) {
        // Foreground color
        var fgColor = fg.toColor(isForeground: true, colorPalette: palette)
        var bgColor = bg.toColor(isForeground: false, colorPalette: palette)

        // Handle inverse
        if attrs.contains(.inverse) {
            swap(&fgColor, &bgColor)
            if bgColor == .clear {
                bgColor = .white
            }
            if fgColor == .white {
                fgColor = .black
            }
        }

        // Handle dim
        if attrs.contains(.dim) {
            fgColor = fgColor.opacity(0.6)
        }

        // Handle hidden
        if attrs.contains(.hidden) {
            fgColor = .clear
        }

        string.foregroundColor = fgColor

        if bgColor != .clear {
            string.backgroundColor = bgColor
        }

        // Font weight
        if attrs.contains(.bold) {
            string.font = .system(size: 14, weight: .bold, design: .monospaced)
        } else {
            string.font = .system(size: 14, weight: .regular, design: .monospaced)
        }

        // Italic - combine with existing font
        if attrs.contains(.italic) {
            // SwiftUI doesn't easily support italic monospace, but we try
            string.font = string.font?.italic()
        }

        // Underline
        if attrs.contains(.underline) {
            string.underlineStyle = .single
        }

        // Strikethrough
        if attrs.contains(.strikethrough) {
            string.strikethroughStyle = .single
        }
    }
}

/// Cursor state information
struct CursorState: Equatable, Sendable {
    var row: Int = 0
    var column: Int = 0
    var visible: Bool = true
    var style: CursorStyle = .block

    enum CursorStyle: Sendable {
        case block
        case underline
        case bar
    }
}

/// Terminal screen buffer
class TerminalBuffer: ObservableObject {
    @Published var lines: [TerminalLine] = []
    @Published var cursor: CursorState = CursorState()

    private(set) var rows: Int
    private(set) var columns: Int
    private var scrollbackLimit: Int = 10000

    // Scrollback history
    private var scrollback: [TerminalLine] = []

    // Alternate screen buffer (for vim, less, etc.)
    private var alternateLines: [TerminalLine]?
    private var alternateCursor: CursorState?
    private(set) var isAlternateScreen: Bool = false

    // Current text attributes for new characters
    var currentAttributes: CellAttributes = []
    var currentForeground: TerminalColor = .default
    var currentBackground: TerminalColor = .default

    init(rows: Int = 24, columns: Int = 80) {
        self.rows = rows
        self.columns = columns
        self.lines = (0..<rows).map { _ in TerminalLine(columns: columns) }
    }

    /// Resize the buffer
    func resize(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns

        // Adjust lines array
        while lines.count < rows {
            lines.append(TerminalLine(columns: columns))
        }
        while lines.count > rows {
            let removed = lines.removeFirst()
            if !removed.trimmedText.isEmpty {
                addToScrollback(removed)
            }
        }

        // Adjust line widths
        for i in 0..<lines.count {
            var line = lines[i]
            if line.cells.count < columns {
                line.cells.append(contentsOf: Array(repeating: TerminalCell(), count: columns - line.cells.count))
            } else if line.cells.count > columns {
                line.cells = Array(line.cells.prefix(columns))
            }
            lines[i] = line
        }

        // Clamp cursor
        cursor.row = min(cursor.row, rows - 1)
        cursor.column = min(cursor.column, columns - 1)
    }

    /// Write a character at the current cursor position
    func write(_ char: Character) {
        guard cursor.row < lines.count && cursor.column < columns else { return }

        lines[cursor.row].cells[cursor.column] = TerminalCell(
            character: char,
            foreground: currentForeground,
            background: currentBackground,
            attributes: currentAttributes
        )

        cursor.column += 1
        if cursor.column >= columns {
            cursor.column = 0
            newLine()
        }
    }

    /// Move to a new line
    func newLine() {
        cursor.column = 0
        if cursor.row < rows - 1 {
            cursor.row += 1
        } else {
            scrollUp()
        }
    }

    /// Carriage return (move to start of line)
    func carriageReturn() {
        cursor.column = 0
    }

    /// Scroll the screen up by one line
    func scrollUp() {
        if !lines.isEmpty {
            let removed = lines.removeFirst()
            if !removed.trimmedText.isEmpty {
                addToScrollback(removed)
            }
            lines.append(TerminalLine(columns: columns))
        }
    }

    /// Add a line to scrollback history
    private func addToScrollback(_ line: TerminalLine) {
        scrollback.append(line)
        if scrollback.count > scrollbackLimit {
            scrollback.removeFirst()
        }
    }

    /// Clear the screen
    func clear() {
        lines = (0..<rows).map { _ in TerminalLine(columns: columns) }
        cursor = CursorState()
    }

    /// Clear from cursor to end of line
    func clearToEndOfLine() {
        guard cursor.row < lines.count else { return }
        for i in cursor.column..<columns {
            lines[cursor.row].cells[i] = TerminalCell()
        }
    }

    /// Clear from cursor to end of screen
    func clearToEndOfScreen() {
        clearToEndOfLine()
        for i in (cursor.row + 1)..<rows {
            lines[i] = TerminalLine(columns: columns)
        }
    }

    /// Move cursor to position
    func moveCursor(row: Int, column: Int) {
        cursor.row = max(0, min(row, rows - 1))
        cursor.column = max(0, min(column, columns - 1))
    }

    /// Switch to alternate screen buffer
    func switchToAlternateScreen() {
        guard !isAlternateScreen else { return }
        alternateLines = lines
        alternateCursor = cursor
        lines = (0..<rows).map { _ in TerminalLine(columns: columns) }
        cursor = CursorState()
        isAlternateScreen = true
    }

    /// Switch back to main screen buffer
    func switchToMainScreen() {
        guard isAlternateScreen else { return }
        if let alt = alternateLines {
            lines = alt
        }
        if let altCursor = alternateCursor {
            cursor = altCursor
        }
        alternateLines = nil
        alternateCursor = nil
        isAlternateScreen = false
    }

    /// Get all visible lines including scrollback for display
    var allLines: [TerminalLine] {
        scrollback + lines
    }

    /// Reset all attributes to default
    func resetAttributes() {
        currentAttributes = []
        currentForeground = .default
        currentBackground = .default
    }
}
