import Foundation
import R1Kit

@MainActor
final class MouseModel: ObservableObject {

    // MARK: - Profiles

    @Published var profiles: [DeviceProfile]
    @Published var activeProfileID: UUID

    var activeProfile: DeviceProfile {
        profiles.first { $0.id == activeProfileID } ?? profiles[0]
    }

    // MARK: - Live settings (mirror of active profile, kept separate so views can
    //         maintain their own dirty-tracking against these values)

    @Published var profile: Profile
    @Published var dpiProfile: DpiProfile
    @Published var pollingRate: PollingRate
    @Published var mouseSettings: MouseSettings

    // MARK: - Connection

    @Published var connected: Bool = false
    @Published var isApplying: Bool = false
    @Published var status: String = ""
    @Published var selectedButton: R1Kit.Button = .left

    private var transport: IOHIDTransport?

    // MARK: - Init

    init() {
        let (profs, activeID) = DeviceProfileStore.load()
        profiles = profs
        activeProfileID = activeID

        let active = profs.first { $0.id == activeID } ?? profs[0]
        profile = active.buttons
        dpiProfile = active.dpi
        pollingRate = active.pollingRate
        mouseSettings = active.settings
    }

    // MARK: - Connection

    func checkConnection() {
        do {
            let t = try IOHIDTransport()
            t.onDpiSlotChange = { [weak self] slot in
                Task { @MainActor in self?.dpiProfile.activeIndex = slot }
            }
            transport = t
            connected = true
        } catch {
            transport = nil
            connected = false
        }
    }

    // MARK: - Button mapping

    func set(_ button: Button, to action: Action) {
        profile = profile.setting(button, to: action)
        applyButtons()
    }

    func applyButtonProfile(_ p: Profile) {
        profile = p
        applyButtons()
    }

    private var s: Strings { LanguageManager.shared.s }

    func applyButtons() {
        updateActiveProfile()
        withTransport { r1 in
            try r1.apply(self.profile)
            self.status = self.s.statusApplied
        }
    }

    // MARK: - DPI

    func applyDpiAll(levels: [Int], activeIndex: Int) {
        dpiProfile.levels = levels
        dpiProfile.activeIndex = activeIndex
        updateActiveProfile()
        withTransport { r1 in
            try r1.applyDpi(self.dpiProfile)
        }
    }

    func applyDpiActiveIndex(_ index: Int) {
        dpiProfile.activeIndex = index
        updateActiveProfile()
        withTransport(quiet: true) { r1 in
            try r1.applyDpi(self.dpiProfile)
        }
    }

    func applyDpiFlags(rippleControl: Bool, angleSnap: Bool) {
        dpiProfile.rippleControl = rippleControl
        dpiProfile.angleSnap = angleSnap
        updateActiveProfile()
        withTransport { r1 in
            try r1.applyDpi(self.dpiProfile)
            self.status = self.s.statusSettingsApplied
        }
    }

    // MARK: - Polling rate

    func applyPollingRate(_ rate: PollingRate) {
        pollingRate = rate
        updateActiveProfile()
        withTransport { r1 in
            try r1.applyPollingRate(self.pollingRate)
            self.status = self.s.statusPollApplied
        }
    }

    // MARK: - Power / timing settings

    func applyMouseSettings(_ settings: MouseSettings) {
        mouseSettings = settings
        updateActiveProfile()
        withTransport { r1 in
            try r1.applySettings(self.mouseSettings)
            self.status = self.s.statusSettingsApplied
        }
    }

    // MARK: - Restore defaults

    func restoreDefaults() {
        profile = .default
        dpiProfile = .default
        pollingRate = .hz1000
        mouseSettings = .default
        updateActiveProfile()
        applyAll(statusMessage: s.statusDefaultsRestored)
    }

    // MARK: - Profile management

    func activateProfile(id: UUID) {
        guard let p = profiles.first(where: { $0.id == id }) else { return }
        activeProfileID = id
        profile = p.buttons
        dpiProfile = p.dpi
        pollingRate = p.pollingRate
        mouseSettings = p.settings
        saveProfiles()
        applyAll(statusMessage: s.statusProfileApplied(p.name))
    }

    func addProfile(name: String) {
        let new = DeviceProfile(
            name: name,
            buttons: profile,
            dpi: dpiProfile,
            pollingRate: pollingRate,
            settings: mouseSettings
        )
        profiles.append(new)
        activeProfileID = new.id
        saveProfiles()
        status = s.statusProfileCreated(name)
        scheduleStatusClear()
    }

    func deleteProfile(id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if activeProfileID == id {
            activateProfile(id: profiles[0].id)
        } else {
            saveProfiles()
        }
    }

    func renameProfile(id: UUID, name: String) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].name = name
        saveProfiles()
    }

    // MARK: - Internals

    private func updateActiveProfile() {
        guard let idx = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        profiles[idx].buttons = profile
        profiles[idx].dpi = dpiProfile
        profiles[idx].pollingRate = pollingRate
        profiles[idx].settings = mouseSettings
        saveProfiles()
    }

    private func saveProfiles() {
        try? DeviceProfileStore.save(profiles: profiles, activeID: activeProfileID)
    }

    private func applyAll(statusMessage: String) {
        withTransport { r1 in
            try r1.apply(self.profile)
            try r1.applyDpi(self.dpiProfile)
            try r1.applyPollingRate(self.pollingRate)
            try r1.applySettings(self.mouseSettings)
            self.status = statusMessage
        }
    }

    private func withTransport(quiet: Bool = false, _ work: @escaping (R1) throws -> Void) {
        if !quiet { isApplying = true }
        do {
            if transport == nil { checkConnection() }
            guard let t = transport else { throw R1Error.deviceNotFound }
            let r1 = R1(transport: t)
            try work(r1)
            connected = true
            if !quiet { isApplying = false }
        } catch {
            transport = nil
            status = ""
            if quiet { connected = false } else { scheduleAutoReconnect() }
        }
        scheduleStatusClear()
    }

    private func scheduleAutoReconnect() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            self.checkConnection()
            self.isApplying = false
        }
    }

    private func scheduleStatusClear() {
        let message = status
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if self.status == message { self.status = "" }
        }
    }
}
