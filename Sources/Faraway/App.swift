import SwiftUI
import AppKit
import Observation
import ServiceManagement
import RestCore

@main
struct FarawayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        MenuBarExtra {
            MenuView(model: delegate.model)
        } label: {
            Label(delegate.model.menuTitle, systemImage: "eye")
        }
        .menuBarExtraStyle(.window)
        Settings { PreferencesView(model: delegate.model) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model.start()
    }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        model.showPanel(); return true
    }
}

@MainActor @Observable
final class AppModel {
    private var clock: RestClock
    private(set) var remaining = 1200
    private(set) var phase = RestClock.Phase.working
    private(set) var completed: Int
    var intervalMinutes: Int {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: "interval"); clock.interval = Double(intervalMinutes * 60); reset() }
    }
    var breakSeconds: Int {
        didSet { UserDefaults.standard.set(breakSeconds, forKey: "duration"); clock.duration = Double(breakSeconds); reset() }
    }
    var soundEnabled: Bool { didSet { UserDefaults.standard.set(soundEnabled, forKey: "sound") } }
    var loginError: String?
    var loginEnabled = SMAppService.mainApp.status == .enabled
    private var timer: Timer?
    private var windows: [NSWindow] = []
    private var observers: [NSObjectProtocol] = []
    private var suspension = SuspensionGate()
    private var day: String
    private var previousApp: NSRunningApplication?
    private var preview = false
    private var controlPanel: NSWindow?
    private var preferencesPanel: NSWindow?
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
    private static func dayKey() -> String { ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date())) }

    init() {
        let defaults = UserDefaults.standard
        let interval = defaults.integer(forKey: "interval")
        let duration = defaults.integer(forKey: "duration")
        let selectedInterval = [20, 30, 45, 60].contains(interval) ? interval : 20
        intervalMinutes = selectedInterval
        let selectedDuration = [20, 30, 60].contains(duration) ? duration : 20
        breakSeconds = selectedDuration
        soundEnabled = defaults.bool(forKey: "sound")
        let currentDay = Self.dayKey()
        day = currentDay
        completed = defaults.string(forKey: "statsDay") == currentDay ? defaults.integer(forKey: "completed") : 0
        clock = RestClock(now: ProcessInfo.processInfo.systemUptime, interval: Double(selectedInterval * 60), duration: Double(selectedDuration))
        remaining = selectedInterval * 60
    }
    var menuTitle: String { phase == .paused ? "已暂停" : String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    var progress: Double { 1 - Double(remaining) / Double(max(1, intervalMinutes * 60)) }
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        let center = NSWorkspace.shared.notificationCenter
        let events: [(Notification.Name, SuspensionGate.Reason, Bool)] = [
            (NSWorkspace.willSleepNotification, .system, true),
            (NSWorkspace.didWakeNotification, .system, false),
            (NSWorkspace.screensDidSleepNotification, .display, true),
            (NSWorkspace.screensDidWakeNotification, .display, false),
            (NSWorkspace.sessionDidResignActiveNotification, .session, true),
            (NSWorkspace.sessionDidBecomeActiveNotification, .session, false)
        ]
        for (name, reason, entering) in events {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    if entering { self?.suspend(reason) } else { self?.wake(reason) }
                }
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if self?.phase == .resting { self?.showBreak() } }
        })
        if CommandLine.arguments.contains("--preview") { preview = true; startBreak() }
        else if !UserDefaults.standard.bool(forKey: "hasLaunched") || CommandLine.arguments.contains("--panel") {
            showPanel()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }
    func showPanel() {
        if controlPanel == nil {
            let host = NSHostingView(rootView: MenuView(model: self, settingsAction: { [weak self] in self?.showPreferences() }))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 340, height: 540), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "远眺 · Faraway"
            window.isReleasedWhenClosed = false
            window.contentView = host
            window.setContentSize(host.fittingSize)
            window.center()
            controlPanel = window
        }
        controlPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    private func showPreferences() {
        if preferencesPanel == nil {
            let host = NSHostingView(rootView: PreferencesView(model: self))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 450, height: 510), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "远眺偏好设置"
            window.isReleasedWhenClosed = false
            window.contentView = host
            window.setContentSize(host.fittingSize)
            window.center()
            preferencesPanel = window
        }
        preferencesPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func stop() {
        timer?.invalidate()
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        closeBreak()
    }
    private func tick() {
        let currentDay = Self.dayKey()
        if currentDay != day { day = currentDay; completed = 0; saveStats() }
        let before = clock.phase
        let count = clock.completed
        clock.tick(at: now)
        sync()
        if before != .resting && phase == .resting { showBreak() }
        if before == .resting && phase != .resting {
            if clock.completed > count && !preview { completed += 1; saveStats() }
            preview = false
            closeBreak()
            if soundEnabled { NSSound(named: "Glass")?.play() }
        }
    }
    private func saveStats() {
        UserDefaults.standard.set(day, forKey: "statsDay")
        UserDefaults.standard.set(completed, forKey: "completed")
    }
    private func sync() { phase = clock.phase; remaining = Int(ceil(clock.remaining(at: now))) }
    func startBreak() { clock.startBreak(at: now); sync(); showBreak() }
    func snooze() { clock.snooze(at: now); preview = false; sync(); closeBreak() }
    func togglePause() { clock.togglePause(at: now); sync() }
    func reset() { clock.restart(at: now); sync(); closeBreak() }
    private func suspend(_ reason: SuspensionGate.Reason) {
        guard suspension.begin(reason, wasRunning: phase != .paused) else { return }
        clock.suspend(at: now); preview = false; sync(); closeBreak()
    }
    private func wake(_ reason: SuspensionGate.Reason) {
        guard suspension.end(reason) else { return }
        if phase == .paused { clock.togglePause(at: now); sync() }
    }
    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            loginError = SMAppService.mainApp.status == .requiresApproval ? "请在系统设置 → 通用 → 登录项中允许远眺。" : nil
        } catch { loginEnabled = SMAppService.mainApp.status == .enabled; loginError = error.localizedDescription }
    }
    private func showBreak() {
        if windows.isEmpty { previousApp = NSWorkspace.shared.frontmostApplication }
        windows.forEach { $0.orderOut(nil) }; windows.removeAll()
        for screen in NSScreen.screens {
            let window = RestWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: BreakView(model: self).preferredColorScheme(.light))
            window.setFrame(screen.frame, display: true)
            window.onEscape = { [weak self] in self?.snooze() }
            windows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    private func closeBreak() {
        let hadWindows = !windows.isEmpty
        windows.forEach { $0.orderOut(nil) }; windows.removeAll()
        if hadWindows { previousApp?.activate(options: []); previousApp = nil }
    }
}

final class RestWindow: NSWindow {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?() } else { super.keyDown(with: event) }
    }
}
