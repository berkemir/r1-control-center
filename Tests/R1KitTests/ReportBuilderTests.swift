import XCTest
@testable import R1Kit

final class ReportBuilderTests: XCTestCase {

    /// Golden vector: o report padrão deve bater byte-a-byte com o que validamos no hardware.
    /// (L=02 R=03 meio=04 DPI=0D ; slot6 forward=06 ; slot7 back=05 ; checksum sum=0x21)
    func testDefaultReportGoldenVector() {
        let report = ReportBuilder.buildButtonReport(.default)
        var expected = [UInt8](repeating: 0, count: 59)
        expected[0] = 0x08; expected[1] = 0x3b; expected[2] = 0x01
        expected[3] = 0x02            // slot0 left
        expected[6] = 0x03            // slot1 right
        expected[9] = 0x04            // slot2 middle
        expected[12] = 0x0D           // slot3 dpi-cycle
        expected[21] = 0x06           // slot6 forward
        expected[24] = 0x05           // slot7 back
        expected[0x39] = 0x00         // checksum high
        expected[0x3a] = 0x21         // checksum low (0x02+0x03+0x04+0x0D+0x06+0x05)
        XCTAssertEqual(report, expected)
    }

    func testReportLengthAndHeader() {
        let r = ReportBuilder.buildButtonReport(.default)
        XCTAssertEqual(r.count, 59)
        XCTAssertEqual(r[0], 0x08)
        XCTAssertEqual(r[1], 0x3b)
        XCTAssertEqual(r[2], 0x01)
    }

    /// Remapear o lateral traseiro (slot7) para Ctrl+C → bytes 11 01 06 e checksum recalculado.
    func testKeyboardActionEncoding() {
        let ctrlC = Action.key([.control], 0x06, label: "key:ctrl+c")
        let profile = Profile.default.setting(.back, to: ctrlC)
        let r = ReportBuilder.buildButtonReport(profile)
        XCTAssertEqual(Array(r[24...26]), [0x11, 0x01, 0x06])    // slot7
        // checksum = default(0x21) - back_default(0x05) + (0x11+0x01+0x06)
        let expectedSum = 0x21 - 0x05 + 0x11 + 0x01 + 0x06
        XCTAssertEqual(Int(r[0x39]) << 8 | Int(r[0x3a]), expectedSum)
    }

    func testParserKeyCombo() {
        let a = ActionParser.parse("key:cmd+shift+4")
        XCTAssertEqual(a?.b0, 0x11)
        XCTAssertEqual(a?.b1, KeyModifiers([.command, .shift]).rawValue)  // 0x08|0x02 = 0x0A
        XCTAssertEqual(a?.b2, 0x21)   // '4' = 0x1E+3
    }

    func testParserNamed() {
        XCTAssertEqual(ActionParser.parse("back"), .backward)
        XCTAssertEqual(ActionParser.parse("media-next"), .mediaNext)
        XCTAssertNil(ActionParser.parse("nonsense"))
    }
}
