import Foundation
import R1Kit

let args = Array(CommandLine.arguments.dropFirst())

func hex(_ b: [UInt8]) -> String { b.map { String(format: "%02X", $0) }.joined(separator: " ") }

func printUsage() {
    print("""
    r1 — Attack Shark R1 button configurator (macOS)

    Usage:
      r1 show                       show the current profile
      r1 set <button> <action>      remap a button and apply
      r1 reset                      restore factory defaults
      r1 apply                      re-apply the saved profile (use after reconnect)
      r1 actions                    list available actions
      r1 scroll-invert              invert mouse scroll direction (trackpad unchanged)

    Buttons: left, right, middle, dpi, forward, back
    Actions: left-click right-click middle-click back forward double-click
             scroll-up scroll-down dpi-cycle dpi-up dpi-down disabled
             media-next media-prev play mute volume-up volume-down
             key:<combo>   e.g. key:ctrl+c  key:cmd+shift+4  key:f13  key:a
    """)
}

func applyAndReport(_ profile: Profile) {
    do {
        let r1 = try R1()
        try r1.apply(profile)
        try ProfileStore.save(profile)
        print("✓ applied and saved.")
    } catch {
        FileHandle.standardError.write(Data("error: \(error)\n".utf8))
        exit(1)
    }
}

func showProfile(_ p: Profile) {
    print("Current profile:")
    for b in Button.allCases {
        print(String(format: "  %-8@ → %@", b.rawValue as NSString, p.action(for: b).label as NSString))
    }
}

guard let cmd = args.first else { printUsage(); exit(0) }

switch cmd {
case "show":
    showProfile(ProfileStore.load())

case "actions":
    print("Named:    " + ActionParser.named.keys.sorted().joined(separator: ", "))
    print("Keyboard: key:<combo> (mods: ctrl shift alt cmd) — e.g. key:ctrl+c, key:f13")

case "reset":
    applyAndReport(.default)

case "apply":
    applyAndReport(ProfileStore.load())

case "set":
    guard args.count >= 3, let button = Button(rawValue: args[1].lowercased()) else {
        FileHandle.standardError.write(Data("usage: r1 set <left|right|middle|dpi|forward|back> <action>\n".utf8))
        exit(2)
    }
    guard let action = ActionParser.parse(args[2]) else {
        FileHandle.standardError.write(Data("invalid action: \(args[2])  (see 'r1 actions')\n".utf8))
        exit(2)
    }
    let updated = ProfileStore.load().setting(button, to: action)
    print("set \(button.rawValue) → \(action.label)")
    applyAndReport(updated)

case "scroll-invert", "scroll":
    if !ScrollInverter.isTrusted(prompt: true) {
        FileHandle.standardError.write(Data("Waiting for Accessibility permission… grant it in System Settings → Privacy & Security → Accessibility (select the terminal or r1 binary).\n".utf8))
        while !ScrollInverter.isTrusted(prompt: false) { Thread.sleep(forTimeInterval: 2) }
        print("✓ permission granted.")
    }
    let inverter = ScrollInverter()
    guard inverter.start(hidLevel: args.contains("--hid")) else {
        FileHandle.standardError.write(Data("failed to create event tap (Accessibility permission?).\n".utf8))
        exit(1)
    }
    print("✓ inverting mouse scroll (trackpad unchanged). Press Ctrl+C to stop.")
    inverter.run()

case "scroll-zero":
    _ = ScrollInverter.isTrusted(prompt: true)
    let z = ScrollInverter()
    let hid = args.contains("--hid")
    guard z.startZeroTest(hidLevel: hid) else {
        FileHandle.standardError.write(Data("tap failed (local hid=\(hid)).\n".utf8)); exit(1)
    }
    print("✓ zeroing mouse scroll (local: \(hid ? "HID" : "session")). Press Ctrl+C to stop.")
    z.run()

case "scroll-debug":
    if !ScrollInverter.isTrusted(prompt: true) {
        FileHandle.standardError.write(Data("No Accessibility permission — grant it in System Settings → Privacy & Security → Accessibility and run again.\n".utf8))
        exit(3)
    }
    let dbg = ScrollInverter()
    let logPath = "/tmp/r1scroll.log"
    guard dbg.startDebug(logPath: logPath) else {
        FileHandle.standardError.write(Data("event tap failed.\n".utf8)); exit(1)
    }
    print("✓ permission OK. Logging to \(logPath).")
    print("Scroll the MOUSE a few times (up and down), then the TRACKPAD, then press Ctrl+C.")
    dbg.run()

default:
    printUsage()
}
