import Testing
import AudioToolbox
@testable import FineTune

// MARK: - Software-tier seeding while HAL reports device not alive (issue #375)

/// A power-cycled DP/USB-C/HDMI display mints a NEW AudioDeviceID for the same
/// UID, and such displays routinely enumerate present-but-not-alive during
/// reconnect. The software tier reads only persisted UID-keyed settings — no
/// HAL access — so it must seed even while the device is not alive; otherwise
/// the new AudioDeviceID never gets a volumes[] entry and consumers default it
/// to 1.0 (full volume). AudioDeviceID(0) is invalid: HAL reports it as
/// not-alive, and outputVolumeBackend resolves it to .software.
@MainActor
@Suite("DeviceVolumeMonitor — software seeding while not alive")
struct DeviceVolumeMonitorSoftwareSeedingTests {
    @Test("A not-alive software-tier device still gets its persisted volume seeded")
    func seedsPersistedVolumeWhileNotAlive() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let settings = SettingsManager(directory: tempDir)

        // The user had this display at 25% software volume before it dropped off.
        // No tier override is needed: AudioDeviceID(0) is invalid, so
        // outputVolumeBackend resolves it to .software before any override lookup.
        settings.setSoftwareDeviceVolume(for: "uid-hdmi", to: 0.25)

        let monitor = MockAudioDeviceMonitor()
        let deadDisplayID = AudioDeviceID(0)
        monitor.addOutputDevice(AudioDevice(
            id: deadDisplayID,
            uid: "uid-hdmi",
            name: "HDMI Display",
            icon: nil,
            supportsAutoEQ: false
        ))

        let dvm = DeviceVolumeMonitor(deviceMonitor: monitor, settingsManager: settings)
        dvm.refreshOutputDeviceStates()

        #expect(dvm.volumes[deadDisplayID] == 0.25)
        #expect(dvm.muteStates[deadDisplayID] == false)
    }
}
