import ServiceManagement
import SwiftUI

private struct PointerOnHover: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension View {
    func pointerOnHover() -> some View {
        modifier(PointerOnHover())
    }
}

struct SettingsPanel: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 14) {
            // Back button
            HStack {
                Button(action: { viewModel.showSettings = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Back")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .pointerOnHover()
                Spacer()
            }

            // App icon
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Divider()

            // Temperature unit
            HStack {
                Text("Temperature")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.useFahrenheit },
                    set: { _ in viewModel.toggleTemperatureUnit() }
                )) {
                    Text("\u{00B0}C").tag(false)
                    Text("\u{00B0}F").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .pointerOnHover()
            }

            Divider()

            // Launch at Login
            HStack {
                Text("Launch at Login")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .pointerOnHover()
                    .onChange(of: launchAtLogin) {
                        do {
                            if launchAtLogin {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Divider()

            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit Cat Monitor")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .pointerOnHover()
        }
        .padding(16)
    }
}
