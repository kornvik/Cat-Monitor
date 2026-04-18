import AppKit
import Combine
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let viewModel = StatsViewModel()
    private var cancellables = Set<AnyCancellable>()

    // Cat animation
    private var catFrames: [NSImage] = []
    private var catFrameIndex = 0
    private var animationTimer: Timer?
    private var lastKeyTime = Date.distantPast

    // Keyboard monitoring
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerLoginItem()
        loadCatFrames()
        setupStatusItem()
        setupPopover()
        setupKeyboardMonitor()
        observeStats()
        promptAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        animationTimer?.invalidate()
    }

    // MARK: - Setup

    private func loadCatFrames() {
        for i in 0...2 {
            guard let original = NSImage(named: "cat_frame_\(i)") else { continue }
            original.size = NSSize(width: 18, height: 18)
            let padded = NSImage(size: NSSize(width: 24, height: 23), flipped: false) { _ in
                original.draw(in: NSRect(x: 6, y: 0, width: 18, height: 18))
                return true
            }
            padded.isTemplate = false
            catFrames.append(padded)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        button.imagePosition = .imageRight
        button.image = catFrames.first
        button.action = #selector(togglePopover)
        button.target = self

        updateMenuBarText(viewModel.stats)
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 360)
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPanel(viewModel: viewModel)
        )
    }

    private func setupKeyboardMonitor() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] _ in
            self?.onKeyDown()
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            self?.onKeyDown()
            return event
        }
    }

    private func onKeyDown() {
        lastKeyTime = Date()
        guard animationTimer == nil else { return }
        animationTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: true
        ) { [weak self] _ in
            self?.updateCatAnimation()
        }
    }

    private func observeStats() {
        viewModel.$stats
            .receive(on: RunLoop.main)
            .sink { [weak self] stats in
                self?.updateMenuBarText(stats)
            }
            .store(in: &cancellables)
    }

    private func registerLoginItem() {
        if SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
        }
    }

    private func promptAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Cat Animation

    private func updateCatAnimation() {
        guard !catFrames.isEmpty else { return }
        let isTyping = Date().timeIntervalSince(lastKeyTime) < 0.5

        if isTyping {
            catFrameIndex = (catFrameIndex + 1) % catFrames.count
            statusItem.button?.image = catFrames[catFrameIndex]
        } else {
            // Idle — reset to frame 0 and stop the timer
            catFrameIndex = 0
            statusItem.button?.image = catFrames[0]
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    // MARK: - Menu Bar Text

    private func updateMenuBarText(_ stats: SystemStatsData) {
        let cpuPct = Int(stats.cpuUsage * 100)
        let gpuPct = Int(viewModel.gpuUsage * 100)
        let memPct = Int(stats.memoryUsage * 100)
        let diskPct = Int(stats.diskUsage * 100)

        let valueFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        let labelFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let labelColor = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark
                ? NSColor(white: 1.0, alpha: 0.9)
                : NSColor(white: 0.0, alpha: 0.9)
        }

        let attributed = NSMutableAttributedString()
        let pairs: [(String, Int)] = [
            ("C", cpuPct),
            ("M", memPct),
            ("G", gpuPct),
            ("D", diskPct),
        ]

        for (i, (label, pct)) in pairs.enumerated() {
            attributed.append(NSAttributedString(
                string: "\(label) ",
                attributes: [.font: labelFont, .foregroundColor: labelColor]
            ))
            let pctStr = String(format: "%2d%%", pct)
            let separator = i < pairs.count - 1 ? " " : ""
            attributed.append(NSAttributedString(
                string: "\(pctStr)\(separator)",
                attributes: [.font: valueFont, .foregroundColor: NSColor.labelColor]
            ))
        }

        attributed.append(NSAttributedString(
            string: " ",
            attributes: [.font: valueFont]
        ))

        statusItem.button?.attributedTitle = attributed
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            viewModel.popoverVisible = false
            viewModel.showSettings = false
        } else {
            viewModel.popoverVisible = true
            viewModel.refreshPopoverData()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
        }
    }
}
