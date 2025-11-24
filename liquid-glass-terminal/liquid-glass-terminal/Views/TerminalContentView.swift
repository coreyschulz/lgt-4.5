//
//  TerminalContentView.swift
//  liquid-glass-terminal
//
//  Main terminal display area with scrolling and glass effect.
//

import SwiftUI

/// Terminal content display with scrolling text
struct TerminalContentView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.displayLines.enumerated()), id: \.offset) { index, line in
                        TerminalLineView(
                            line: line,
                            colorPalette: viewModel.colorPalette,
                            font: viewModel.font
                        )
                        .id(index)
                    }

                    // Cursor overlay on the current line
                    if viewModel.isRunning {
                        CursorOverlay(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.displayLines.count) { oldCount, newCount in
                if viewModel.autoScroll {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
        }
        // No nested glass effect - let parent's glass show through
        .focusable()
        .focused($isFocused)
        .onKeyPress { keyPress in
            viewModel.handleKeyPress(keyPress)
        }
        .onAppear {
            isFocused = true
        }
        .onTapGesture {
            isFocused = true
        }
    }
}

/// Cursor overlay view positioned at the cursor location
struct CursorOverlay: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        GeometryReader { geometry in
            if viewModel.cursor.visible && viewModel.cursorVisible {
                RoundedRectangle(cornerRadius: 2)
                    .fill(TerminalColorPalette.cursor)
                    .frame(width: viewModel.font.characterWidth, height: viewModel.font.lineHeight)
                    .position(cursorPosition(in: geometry))
                    .animation(.easeInOut(duration: 0.1), value: viewModel.cursor.column)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.cursor.row)
            }
        }
        .allowsHitTesting(false)
    }

    private func cursorPosition(in geometry: GeometryProxy) -> CGPoint {
        let x = 12 + CGFloat(viewModel.cursor.column) * viewModel.font.characterWidth + viewModel.font.characterWidth / 2
        let y = 8 + CGFloat(viewModel.cursor.row + viewModel.buffer.allLines.count - viewModel.buffer.lines.count) * viewModel.font.lineHeight + viewModel.font.lineHeight / 2
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    TerminalContentView(viewModel: TerminalViewModel())
        .frame(width: 800, height: 400)
}
