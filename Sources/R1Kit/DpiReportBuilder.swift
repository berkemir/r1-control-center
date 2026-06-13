import Foundation

/// Builds feature report 0x04 (56 bytes) for DPI configuration.
/// Format reverse-engineered from xb-bx/attack-shark-r1-driver (set_dpis in main.odin).
public enum DpiReportBuilder {
    public static let reportID: UInt8 = 0x04

    public static func build(_ profile: DpiProfile) -> [UInt8] {
        // Initial payload — fixed bytes. Color slots at [25..49] are default white.
        var p: [UInt8] = [
            0x04, 0x38, 0x01, 0x00, 0x00, 0x3f, 0x00, 0x00, // [0..7]  header
            0x02, 0x02, 0x02, 0x02, 0x02, 0x02,              // [8..13] DPI values (overwritten)
            0x00, 0x00,                                        // [14..15]
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00,              // [16..21] middle-range flags (overwritten)
            0x00, 0x00,                                        // [22..23]
            0x01,                                              // [24]    active DPI slot (overwritten)
            0xff, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00,  // [25..32] color data (fixed)
            0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0xff,  // [33..40]
            0x00, 0xff, 0xff, 0x40, 0x00, 0xff, 0xff, 0xff,  // [41..48]
            0x02,                                              // [49]
            0x00, 0x00,                                        // [50..51] checksum (overwritten)
            0x00, 0x00, 0x00, 0x00,                           // [52..55]
        ]

        // Base checksum = sum of fixed non-zero bytes that are always included:
        // [5]=0x3f, [24]=0x01 initial active, [25..49] color bytes.
        // Verified: 0x3f + 0x01 + sum([25..49]) = 0x0d75.
        var checksum: UInt16 = 0x0d75

        for i in 0..<DpiProfile.slotCount {
            let dpi = profile.levels[i]
            let encoded = DpiProfile.encode(dpi)
            p[8 + i] = encoded
            checksum &+= UInt16(encoded)
        }

        if profile.angleSnap {
            p[3] = 1
            checksum &+= 1
        }
        if profile.rippleControl {
            p[4] = 1
            checksum &+= 1
        }

        p[24] = UInt8(profile.activeIndex + 1)  // firmware uses 1-based index
        checksum &+= UInt16(profile.activeIndex) // adds (active - 1) relative to base

        p[50] = UInt8(checksum >> 8)
        p[51] = UInt8(checksum & 0xff)

        return p
    }
}
