import Foundation
import CoreGraphics
import ApplicationServices

/// Inverte a direção do scroll APENAS do mouse (eventos discretos), deixando o trackpad (contínuo) intacto.
/// Usa um CGEventTap — exige permissão de Acessibilidade. É código nosso, sem terceiros.
public final class ScrollInverter {
    private var tap: CFMachPort?

    public init() {}

    /// Verifica se o processo tem permissão de Acessibilidade (com prompt opcional).
    public static func isTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    /// Inicia o tap. Retorna false se não conseguiu criar (normalmente falta de permissão).
    /// `hidLevel`: tapa no nível HID (antes do transform "natural") em vez do nível de sessão.
    public func start(hidLevel: Bool = false) -> Bool {
        FileManager.default.createFile(atPath: "/tmp/r1invert.log", contents: nil)
        ScrollInverter.debugLog = FileHandle(forWritingAtPath: "/tmp/r1invert.log")
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .scrollWheel,
               event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
               event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
               event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0 {   // assinatura exclusiva do mouse
                // lê os 3 ANTES, escreve os 3 DEPOIS (evita recálculo interno entre campos)
                let d = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
                let p = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
                let f = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
                event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -f)
                event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -p)
                event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -d)
                let line = String(format: "INVERT d=%ld p=%ld f=%.2f\n", d, p, f)
                ScrollInverter.debugLog?.write(Data(line.utf8))
            }
            return Unmanaged.passUnretained(event)
        }
        let location: CGEventTapLocation = hidLevel ? .cghidEventTap : .cgSessionEventTap
        guard let tap = CGEvent.tapCreate(
            tap: location,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else { return false }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    /// Bloqueia rodando o run loop (mantém o tap ativo). Ctrl+C para sair.
    public func run() { CFRunLoopRun() }

    /// Modo diagnóstico: só OBSERVA eventos de scroll e loga no arquivo (não modifica nada).
    public func startDebug(logPath: String) -> Bool {
        FileManager.default.createFile(atPath: logPath, contents: nil)
        ScrollInverter.debugLog = FileHandle(forWritingAtPath: logPath)
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .scrollWheel {
                let cont = event.getIntegerValueField(.scrollWheelEventIsContinuous)
                let sph = event.getIntegerValueField(.scrollWheelEventScrollPhase)
                let mph = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
                let d1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
                let line = String(format: "continuous=%ld scrollPhase=%ld momentumPhase=%ld deltaA1=%ld\n", cont, sph, mph, d1)
                ScrollInverter.debugLog?.write(Data(line.utf8))
            }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
            eventsOfInterest: mask, callback: callback, userInfo: nil
        ) else { return false }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    /// Teste diagnóstico: ZERA o scroll do mouse. Se o mouse parar de rolar, as modificações chegam aos apps.
    /// `hidLevel` escolhe o local do tap: true = .cghidEventTap (antes do natural), false = .cgSessionEventTap.
    public func startZeroTest(hidLevel: Bool) -> Bool {
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .scrollWheel, event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 {
                // FORÇA direção fixa (positiva), ignorando o input — testa controle de direção
                event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 3)
                event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 30)
                event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 3.0)
            }
            return Unmanaged.passUnretained(event)
        }
        let location: CGEventTapLocation = hidLevel ? .cghidEventTap : .cgSessionEventTap
        guard let tap = CGEvent.tapCreate(
            tap: location, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: callback, userInfo: nil
        ) else { return false }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private static var debugLog: FileHandle?
}
