import Foundation

/// Fachada de alto nível: aplica um perfil de botões ao mouse.
public final class R1 {
    private let transport: HidTransport

    public init(transport: HidTransport) {
        self.transport = transport
    }

    /// Conveniência: abre o transporte real (IOHIDManager).
    public convenience init() throws {
        self.init(transport: try IOHIDTransport())
    }

    /// Builds and sends report 0x08 (button map), waits for ACK.
    @discardableResult
    public func apply(_ profile: Profile, retries: Int = 5) throws -> Bool {
        let report = ReportBuilder.buildButtonReport(profile)
        let ok = transport.applyWithAck(report, retries: retries)
        if !ok { throw R1Error.noAck }
        return ok
    }

    /// Builds and sends report 0x04 (DPI profiles), waits for ACK.
    @discardableResult
    public func applyDpi(_ profile: DpiProfile, retries: Int = 5) throws -> Bool {
        let report = DpiReportBuilder.build(profile)
        let ok = transport.applyWithAck(report, retries: retries)
        if !ok { throw R1Error.noAck }
        return ok
    }

    /// Sends report 0x06 (polling rate, 9 bytes), waits for ACK.
    @discardableResult
    public func applyPollingRate(_ rate: PollingRate, retries: Int = 5) throws -> Bool {
        let report = rate.buildReport()
        let ok = transport.applyWithAck(report, retries: retries)
        if !ok { throw R1Error.noAck }
        return ok
    }

    /// Sends report 0x05 (power management + key response, 15 bytes), waits for ACK.
    @discardableResult
    public func applySettings(_ settings: MouseSettings, retries: Int = 5) throws -> Bool {
        let report = settings.buildReport()
        let ok = transport.applyWithAck(report, retries: retries)
        if !ok { throw R1Error.noAck }
        return ok
    }
}
