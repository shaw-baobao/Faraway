import Foundation

public struct RestClock {
    public enum Phase: Equatable { case working, resting, paused }
    public private(set) var phase: Phase = .working
    public private(set) var deadline: TimeInterval
    public private(set) var completed = 0
    public var interval: TimeInterval
    public var duration: TimeInterval
    private var pausedRemaining: TimeInterval = 0

    public init(now: TimeInterval, interval: TimeInterval = 1200, duration: TimeInterval = 20) {
        self.interval = interval
        self.duration = duration
        self.deadline = now + interval
    }
    public func remaining(at now: TimeInterval) -> TimeInterval {
        phase == .paused ? pausedRemaining : max(0, deadline - now)
    }
    public mutating func tick(at now: TimeInterval) {
        guard phase != .paused, now >= deadline else { return }
        if phase == .working { startBreak(at: now) }
        else { completed += 1; restart(at: now) }
    }
    public mutating func startBreak(at now: TimeInterval) {
        phase = .resting
        deadline = now + duration
    }
    public mutating func restart(at now: TimeInterval) {
        phase = .working
        deadline = now + interval
    }
    public mutating func snooze(at now: TimeInterval) {
        phase = .working
        deadline = now + 300
    }
    public mutating func togglePause(at now: TimeInterval) {
        if phase == .paused {
            phase = .working
            deadline = now + pausedRemaining
        } else if phase == .working {
            pausedRemaining = remaining(at: now)
            phase = .paused
        }
    }
    // A sleeping/locked display is not evidence that a break was completed.
    public mutating func suspend(at now: TimeInterval) {
        if phase == .resting { restart(at: now) }
        if phase == .working { togglePause(at: now) }
    }
}
