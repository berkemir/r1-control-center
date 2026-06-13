# Attack Shark R1 — reverse-engineered protocol

Everything here was recovered by static analysis of the official Windows app + verified by writing to a real device and observing behavior. No vendor binaries are redistributed.

## Device

| | |
|---|---|
| Vendor ID | `0x1D57` (ODM "LXDDZ") |
| Product ID | `0xFA60` (2.4 GHz dongle) · `0xFA61` (wired) |
| Sensor / MCU | PixArt PAW3311 · Beken BK3633/BK52820 |

The dongle exposes **4 HID interfaces**. The one used for configuration is **usage page 1, usage `0x80`, `MaxFeatureReportSize = 64`**. The others are the standard mouse (usage 2), keyboard (usage 6) and consumer (usage 6) collections.

## Transport (macOS)

Config commands are plain **HID feature reports** — on macOS, `IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, reportID, …)` via `IOHIDManager`. No libusb / DriverKit needed. The Windows app uses `hidapi` (`hid_send_feature_report`); the byte format is identical.

Accessing the device requires the **Input Monitoring** TCC permission (the device enumerates as keyboard/mouse). `IOHIDManagerOpen` returns `0xE00002E2` (kIOReturnNotPermitted) without it.

## Button remap — feature report `0x08` (59 bytes)

```
offset  size  meaning
[0x00]   1    0x08   report id
[0x01]   1    0x3B   length (59)
[0x02]   1    0x01   subcommand / profile bank
[0x03]   54   18 button slots × 3 bytes  → slot i at [0x03 + i*3 .. +2]  (b0 b1 b2)
[0x39]   1    checksum HIGH
[0x3A]   1    checksum LOW
```

### Slot → physical button (verified on hardware)

| Button | Slot | Bytes |
|---|---|---|
| Left | 0 | `[3..5]` |
| Right | 1 | `[6..8]` |
| Middle / wheel | 2 | `[9..11]` |
| DPI | 3 | `[12..14]` |
| Side front (forward) | 6 | `[21..23]` |
| Side rear (back) | 7 | `[24..26]` |

Unused slots (4, 5, 8–17) are `00 00 00`.

### Action encoding (3 bytes per slot, `b0 b1 b2`)

- **Mouse / system** — single `b0`, `b1=b2=0`:
  `disabled=0x01, left=0x02, right=0x03, wheel=0x04, backward=0x05, forward=0x06, double-click=0x07, fire=0x08, scroll-up=0x09, scroll-down=0x0A, tilt-left=0x0B, tilt-right=0x0C, dpi-cycle=0x0D, dpi-up=0x0E, dpi-down=0x0F`
- **Media** — single `b0`: `prev=0x16, next=0x17, play/pause=0x18, stop=0x19, mute=0x1A, vol-up=0x1B, vol-down=0x1C`
- **Keyboard / shortcut** — `b0=0x11, b1=modifier mask, b2=HID usage`.
  Modifier bits: `ctrl=0x01, shift=0x02, alt=0x04, cmd/gui=0x08`. Example: Ctrl+C = `11 01 06`.
- **Macro** — `b0=0x11`-family with the macro body sent in a separate report `0x09` (3 × 64-byte chunks). *Not yet reverse-engineered here.*

> The firmware's own "browser back/forward" action codes (`0x21`/`0x20`) do **not** produce page navigation on macOS. Map the side buttons to the keyboard shortcuts `Cmd+Left` / `Cmd+Right` instead.

### Checksum

16-bit additive sum of bytes `[0x03..0x38]`. `[0x39] = sum >> 8`, `[0x3A] = sum & 0xFF`. Header bytes (0,1,2) are excluded. The same algorithm is used by the DPI (`0x04`) and sleep (`0x05`) reports.

## Status / ACK — report `0x03` (input, 5 bytes)

The firmware reports events on report id `0x03`; byte[2] is the event type:

| byte[2] | meaning |
|---|---|
| `0x50` | command ACK (byte[4] echoes the command's report id) |
| `0x40` | heartbeat / status |
| `0x10` | DPI button pressed |

Capture via `IOHIDDeviceRegisterInputReportCallback`. ACKs arrive on a different interface than the config one, so register on all matched interfaces. Capture is timing-sensitive — retry the write a few times.

## Read behavior

`GetReport(feature)` **echoes the last `SetReport` buffer** rather than returning stored config — the device is effectively write-only. Keep the canonical state in the app and persist it to disk.

## Other reports (from the community Linux driver)

`0x04` DPI (56B, with checksum), `0x06` polling rate (9B), `0x05` sleep/timers (15B). See [xb-bx/attack-shark-r1-driver](https://github.com/xb-bx/attack-shark-r1-driver).

## Scroll inversion (not a firmware feature)

The R1 firmware has no scroll-direction option. We invert on the macOS side with a `CGEventTap` (`.cgSessionEventTap`), negating `scrollWheelEventDeltaAxis1` / `pointDeltaAxis1` / `fixedPtDeltaAxis1`.

To invert **only the mouse** (and leave the trackpad alone), filter on the mouse's signature: `IsContinuous == 0 && scrollPhase == 0 && momentumPhase == 0`. Trackpad scroll is `IsContinuous == 1`.

Requires the **Accessibility** TCC permission.

## Methodology

1. The official installer is **Inno Setup 6**; extracted with `innoextract` (no execution).
2. The app uses `hidapi`; the report-building logic lives in `AttackShark.exe`. Decompiled with **radare2 + r2ghidra** to recover report `0x08`'s layout, the action tables, and the checksum.
3. Every claim was confirmed by writing to a real R1 and observing the result (e.g. remapping each slot to a distinct key and pressing each physical button to confirm the slot↔button mapping).
