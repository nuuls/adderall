import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var caffeinate: Process?

    private var keepDisplayAwake: Bool {
        get { UserDefaults.standard.object(forKey: "keepDisplayAwake") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "keepDisplayAwake") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(clicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateIcon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        caffeinate?.terminate()
    }

    // Left click toggles, right click (or ctrl-click) opens the menu.
    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            toggle()
        }
    }

    @objc private func toggle() {
        if caffeinate == nil { start() } else { stop() }
        updateIcon()
    }

    // Restarts caffeinate with the new flags if it's currently running.
    @objc private func toggleKeepDisplayAwake() {
        keepDisplayAwake.toggle()
        if caffeinate != nil {
            stop()
            start()
            updateIcon()
        }
    }

    private func start() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // -d: keep display awake, -i: prevent idle sleep,
        // -w: exit automatically if this app dies.
        process.arguments = [keepDisplayAwake ? "-di" : "-i", "-w", String(ProcessInfo.processInfo.processIdentifier)]
        process.terminationHandler = { [weak self] proc in
            let pid = proc.processIdentifier
            Task { @MainActor in
                guard let self, self.caffeinate?.processIdentifier == pid else { return }
                self.caffeinate = nil
                self.updateIcon()
            }
        }
        do {
            try process.run()
            caffeinate = process
        } catch {
            NSSound.beep()
        }
    }

    private func stop() {
        let process = caffeinate
        caffeinate = nil
        process?.terminate()
    }

    private func showMenu() {
        let menu = NSMenu()
        let toggleItem = menu.addItem(
            withTitle: caffeinate == nil ? "Keep Awake" : "Allow Sleep",
            action: #selector(toggle),
            keyEquivalent: ""
        )
        toggleItem.target = self
        let displayItem = menu.addItem(
            withTitle: "Keep Display Awake",
            action: #selector(toggleKeepDisplayAwake),
            keyEquivalent: ""
        )
        displayItem.target = self
        displayItem.state = keepDisplayAwake ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let on = caffeinate != nil
        let image = NSImage(
            systemSymbolName: on ? "pills.fill" : "pills",
            accessibilityDescription: on ? "Caffeinate on" : "Caffeinate off"
        )
        image?.isTemplate = true
        button.image = image
        button.appearsDisabled = !on
        let display = keepDisplayAwake ? "display stays on" : "display can sleep"
        button.toolTip = on ? "Caffeinate: on, \(display) (click to allow sleep)" : "Caffeinate: off (click to keep awake)"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
