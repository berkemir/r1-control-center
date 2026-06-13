import Foundation
import IOKit
import IOKit.hid

public enum R1Error: Error, CustomStringConvertible {
    case deviceNotFound
    case setReportFailed(Int32)
    case noAck

    public var description: String {
        switch self {
        case .deviceNotFound:        return "R1 mouse not found — plug in USB-C or dongle, check Input Monitoring permission"
        case .setReportFailed(let r): return String(format: "Write failed (IOReturn 0x%08X)", UInt32(bitPattern: r))
        case .noAck:                 return "Mouse did not acknowledge the command (no ACK after retries)"
        }
    }
}

/// Contrato de transporte — permite mockar em testes.
public protocol HidTransport {
    /// Envia um feature report (byte[0] = report id). Lança em falha.
    func setFeatureReport(_ bytes: [UInt8]) throws
    /// Envia e aguarda o ACK do firmware (report 0x03, byte[2]==0x50, byte[4]==report id) com retries.
    func applyWithAck(_ bytes: [UInt8], retries: Int) -> Bool
}

/// Transporte real via IOHIDManager. Abre a interface de config (usagePage 1 / feature report 64B).
public final class IOHIDTransport: HidTransport {
    private let manager: IOHIDManager
    private let configDevice: IOHIDDevice
    private var inputBuffers: [UnsafeMutablePointer<UInt8>] = []

    private final class AckBox {
        var reports: [[UInt8]] = []
        var dpiSlotHandler: ((Int) -> Void)?
    }
    private let ackBox = AckBox()

    /// Called when the DPI button on the mouse cycles to a new slot (0-based index).
    public var onDpiSlotChange: ((Int) -> Void)? {
        get { ackBox.dpiSlotHandler }
        set { ackBox.dpiSlotHandler = newValue }
    }

    public init() throws {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        // 0xFA60 = dongle (2.4G Wireless), 0xFA61 = USB-C kablo — her ikisini de tara
        let matchMultiple: [[String: Any]] = [
            [kIOHIDVendorIDKey: 0x1D57, kIOHIDProductIDKey: 0xFA60],
            [kIOHIDVendorIDKey: 0x1D57, kIOHIDProductIDKey: 0xFA61],
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchMultiple as CFArray)

        guard IOHIDManagerOpen(manager, 0) == kIOReturnSuccess,
              let set = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, !set.isEmpty else {
            throw R1Error.deviceNotFound
        }
        let devices = Array(set)
        func featureSize(_ d: IOHIDDevice) -> Int {
            (IOHIDDeviceGetProperty(d, kIOHIDMaxFeatureReportSizeKey as CFString) as? NSNumber)?.intValue ?? 0
        }
        guard let cfg = devices.first(where: { featureSize($0) >= 56 }) else {
            throw R1Error.deviceNotFound
        }
        configDevice = cfg

        // Capture ACKs and hardware events (report 0x03) from any interface.
        let callback: IOHIDReportCallback = { context, _, _, _, _, report, length in
            let box = Unmanaged<AckBox>.fromOpaque(context!).takeUnretainedValue()
            let bytes = Array(UnsafeBufferPointer(start: report, count: min(length, 16)))
            box.reports.append(bytes)
            // DPI button pressed: 03 10 10 <slot> 00 — slot is byte[3] (1-based)
            if bytes.count >= 4 && bytes[0] == 0x03 && bytes[2] == 0x10 {
                let slot = Int(bytes[3])
                if slot >= 1 && slot <= 6 {
                    box.dpiSlotHandler?(slot - 1)
                }
            }
        }
        let ctx = Unmanaged.passUnretained(ackBox).toOpaque()
        for d in devices {
            _ = IOHIDDeviceOpen(d, 0)
            let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
            buf.initialize(repeating: 0, count: 64)
            inputBuffers.append(buf)
            IOHIDDeviceRegisterInputReportCallback(d, buf, 64, callback, ctx)
            IOHIDDeviceScheduleWithRunLoop(d, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        }
    }

    public func setFeatureReport(_ bytes: [UInt8]) throws {
        let r = bytes.withUnsafeBufferPointer {
            IOHIDDeviceSetReport(configDevice, kIOHIDReportTypeFeature, CFIndex(bytes[0]), $0.baseAddress!, bytes.count)
        }
        if r != kIOReturnSuccess { throw R1Error.setReportFailed(r) }
    }

    public func applyWithAck(_ bytes: [UInt8], retries: Int) -> Bool {
        for _ in 0..<max(1, retries) {
            ackBox.reports.removeAll()
            try? setFeatureReport(bytes)
            let deadline = Date().addingTimeInterval(0.4)
            while Date() < deadline { CFRunLoopRunInMode(.defaultMode, 0.05, true) }
            if ackBox.reports.contains(where: { $0.count >= 5 && $0[0] == 0x03 && $0[2] == 0x50 && $0[4] == bytes[0] }) {
                return true
            }
        }
        return false
    }
}
