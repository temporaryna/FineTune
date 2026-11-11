import Foundation

@MainActor
protocol AudioProcessMonitoring: AnyObject {
    var activeApps: [AudioApp] { get }
    /// PIDs whose CoreAudio process object is currently streaming (isRunning).
    /// Computed once per refresh — consumers must use this instead of reading
    /// the HAL property per object on hot paths.
    var streamingPIDs: Set<pid_t> { get }
    var onAppsChanged: (([AudioApp]) -> Void)? { get set }

    func start()
    func stop()
}
