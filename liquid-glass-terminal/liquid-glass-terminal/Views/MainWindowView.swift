//
//  MainWindowView.swift
//  liquid-glass-terminal
//
//  Root view with Liquid Glass styling.
//

import SwiftUI
import AppKit

/// Main window view with Liquid Glass effect
struct MainWindowView: View {
    @State private var terminalState = TerminalState()
    @State private var isHoveringTopArea = false
    @State private var isHoveringBottomArea = false

    /// Safe area height for traffic lights (close/minimize/zoom buttons)
    private let trafficLightSafeArea: CGFloat = 28
    /// Height of the hover detection area at bottom
    private let bottomHoverHeight: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content - terminal fills entire space
                VStack(spacing: 0) {
                    // Safe area spacer for traffic lights with hover detection
                    Color.clear
                        .frame(height: trafficLightSafeArea)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHoveringTopArea = hovering
                            updateTrafficLightVisibility(hovering)
                        }

                    // Terminal content area - takes all remaining space
                    TerminalContentView(state: terminalState)
                }

                // Bottom hover area and status bar overlay
                VStack {
                    Spacer()

                    // Invisible hover detection area
                    Color.clear
                        .frame(height: bottomHoverHeight)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHoveringBottomArea = hovering
                            }
                        }
                        .overlay(alignment: .bottom) {
                            // Status bar appears on hover
                            if isHoveringBottomArea {
                                StatusBarView(state: terminalState)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                }
            }
            .onAppear {
                // Hide traffic lights after a short delay to ensure window is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hideTrafficLights()
                }
            }
        }
        .glassEffect(.regular, in: .rect)  // Rectangular edge-to-edge glass
        .ignoresSafeArea()
        .frame(minWidth: 400, minHeight: 300)
    }

    // MARK: - Traffic Light Control

    private func updateTrafficLightVisibility(_ visible: Bool) {
        guard let window = NSApplication.shared.keyWindow else { return }
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        buttons.forEach { buttonType in
            window.standardWindowButton(buttonType)?.isHidden = !visible
        }
    }

    private func hideTrafficLights() {
        updateTrafficLightVisibility(false)
    }
}

#Preview {
    MainWindowView()
        .frame(width: 800, height: 600)
}
