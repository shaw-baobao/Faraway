/// Coordinates overlapping system, display, and user-session suspension events.
public struct SuspensionGate {
    public enum Reason: Hashable, Sendable { case system, display, session }
    private var reasons: Set<Reason> = []
    private var resumeOnExit = false

    public init() {}

    /// Returns true only when entering the first suspension condition.
    public mutating func begin(_ reason: Reason, wasRunning: Bool) -> Bool {
        let first = reasons.isEmpty
        if first { resumeOnExit = wasRunning }
        reasons.insert(reason)
        return first
    }

    /// Returns true when the final condition clears and the timer was running.
    public mutating func end(_ reason: Reason) -> Bool {
        guard reasons.remove(reason) != nil, reasons.isEmpty else { return false }
        defer { resumeOnExit = false }
        return resumeOnExit
    }
}
