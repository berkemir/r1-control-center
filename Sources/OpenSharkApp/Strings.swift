import Foundation

struct Strings {
    let lang: Language

    // MARK: - Common
    var apply:          String { tr("Apply",   "Uygula",          "Aplicar") }
    var discard:        String { tr("Discard", "Vazgeç",          "Descartar") }
    var cancel:         String { tr("Cancel",  "İptal",           "Cancelar") }
    var create:         String { tr("Create",  "Oluştur",         "Criar") }
    var rename:         String { tr("Rename",  "Yeniden Adlandır","Renomear") }
    var unsaved:        String { tr("Unsaved changes", "Kaydedilmemiş değişiklikler", "Alterações não salvas") }
    var connected:      String { tr("Connected",    "Bağlı",          "Conectado") }
    var disconnected:   String { tr("Disconnected", "Bağlantı Kesik", "Desconectado") }
    var syncing:        String { tr("Syncing...",   "Eşitleniyor...", "Sincronizando...") }
    var restoreDefaults:String { tr("Restore Defaults", "Varsayılana Dön", "Restaurar Padrões") }

    // MARK: - Mouse not detected
    var mouseNotDetected:     String { tr("Mouse Not Detected", "Fare Algılanamadı", "Mouse Não Detectado") }
    var mouseNotDetectedDesc: String { tr(
        "Connect the Attack Shark R1 (USB-C or 2.4GHz dongle) and click Reconnect.",
        "Attack Shark R1'i bağlayın (USB-C veya 2.4GHz alıcı) ve Yeniden Bağlan'a tıklayın.",
        "Conecte o Attack Shark R1 (USB-C ou dongle 2.4GHz) e clique em Reconectar."
    )}
    var reconnect: String { tr("Reconnect", "Yeniden Bağlan", "Reconectar") }

    // MARK: - Profiles
    var newProfile:            String { tr("New Profile",    "Yeni Profil",    "Novo Perfil") }
    var newProfileEllipsis:    String { tr("New Profile...", "Yeni Profil...", "Novo Perfil...") }
    var newProfileMessage:     String { tr(
        "The new profile will be created from the current settings.",
        "Yeni profil mevcut ayarlardan oluşturulacak.",
        "O novo perfil será criado com as configurações atuais."
    )}
    var renameProfile:         String { tr("Rename Profile",  "Profili Yeniden Adlandır", "Renomear Perfil") }
    var renameEllipsis:        String { tr("Rename...",       "Yeniden Adlandır...",      "Renomear...") }
    var profileNamePlaceholder:String { tr("Profile name", "Profil adı",  "Nome do perfil") }
    var newNamePlaceholder:    String { tr("New name",     "Yeni ad",     "Novo nome") }
    func deleteProfile(_ name: String) -> String { tr(
        "Delete \"\(name)\"",
        "\"\(name)\" Sil",
        "Excluir \"\(name)\""
    )}

    // MARK: - Tabs
    var buttonsTab:  String { tr("Buttons",  "Tuşlar",        "Botões") }
    var dpiTab:      String { "DPI" }
    var settingsTab: String { tr("Settings", "Ayarlar",       "Configurações") }

    // MARK: - Buttons / Inspector
    var keyShortcut:        String { tr("KEY / SHORTCUT", "TUŞ / KISAYOL",   "TECLA / ATALHO") }
    var keyShortcutHint:    String { "e.g. cmd+c, cmd+left, f13" }
    var setShortcut:        String { tr("Set",    "Ayarla",         "Definir") }
    var invalidShortcut:    String { tr(
        "Invalid shortcut — try cmd+c, cmd+left, f13…",
        "Geçersiz kısayol — cmd+c, cmd+left, f13 deneyin…",
        "Atalho inválido — tente cmd+c, cmd+left, f13…"
    )}

    // MARK: - DPI
    var dpiProfiles:  String { tr("DPI Profiles",  "DPI Profilleri", "Perfis DPI") }
    var activeSlot:   String { tr("Active profile","Aktif profil",   "Perfil ativo") }
    var setAsActive:  String { tr("Set as active profile", "Aktif profil olarak ayarla", "Definir como perfil ativo") }
    func activeDpiHeader(slot: Int, dpi: Int) -> String { tr(
        "Active: Profile \(slot) — \(dpi) DPI",
        "Aktif: Profil \(slot) — \(dpi) DPI",
        "Ativo: Perfil \(slot) — \(dpi) DPI"
    )}
    func slotLabel(_ i: Int) -> String { tr("Profile \(i)", "Profil \(i)", "Perfil \(i)") }

    // MARK: - Settings
    var mouseSettings:     String { tr("Mouse Settings",   "Fare Ayarları",             "Configurações do Mouse") }
    var mouseSettingsDesc: String { tr(
        "Polling rate, sensor behavior and power management",
        "Yoklama hızı, sensör davranışı ve güç yönetimi",
        "Taxa de polling, comportamento do sensor e gerenciamento de energia"
    )}
    var pollingRate:     String { tr("Polling Rate", "Yoklama Hızı",  "Taxa de Polling") }
    var pollingRateDesc: String { tr(
        "How often the mouse reports its position to the host. Higher = lower latency, higher CPU usage.",
        "Farenin konumunu bilgisayara bildirme sıklığı. Yüksek = daha az gecikme, daha fazla CPU kullanımı.",
        "Com que frequência o mouse reporta sua posição. Maior = menor latência, maior uso de CPU."
    )}
    var sensor:            String { tr("Sensor",         "Sensör",           "Sensor") }
    var rippleControl:     String { "Ripple Control" }
    var rippleControlDesc: String { tr(
        "Smooths jittery sensor output at low speeds",
        "Düşük hızlarda sensör titremesini azaltır",
        "Suaviza a saída instável do sensor em baixas velocidades"
    )}
    var angleSnap:     String { "Angle Snap" }
    var angleSnapDesc: String { tr(
        "Corrects diagonal movement toward straight lines",
        "Çapraz hareketi düz çizgiye düzeltir",
        "Corrige movimento diagonal em linhas retas"
    )}
    var powerManagement:     String { tr("Power Management", "Güç Yönetimi",             "Gerenciamento de Energia") }
    var keyResponseTime:     String { tr("Key Response Time","Tuş Yanıt Süresi",         "Tempo de Resposta") }
    var keyResponseTimeDesc: String { tr(
        "Click debounce window — lower = faster, higher = fewer accidental double-clicks",
        "Tıklama gecikme penceresi — düşük = hızlı, yüksek = daha az çift tıklama",
        "Janela de debounce — menor = mais rápido, maior = menos cliques duplos acidentais"
    )}
    var sleepAfter:     String { tr("Sleep After",      "Uyku Süresi",      "Dormir Após") }
    var sleepAfterDesc: String { tr(
        "Idle time before the mouse enters light sleep",
        "Farenin uyku moduna girmeden önceki bekleme süresi",
        "Tempo ocioso antes do mouse entrar em modo de espera"
    )}
    var deepSleepAfter:     String { tr("Deep Sleep After",  "Derin Uyku Süresi", "Sono Profundo Após") }
    var deepSleepAfterDesc: String { tr(
        "Time in light sleep before entering deep sleep (lower power draw)",
        "Derin uykuya geçmeden önceki uyku süresi (daha düşük güç tüketimi)",
        "Tempo em espera antes do sono profundo (menor consumo de energia)"
    )}
    var language: String { tr("Language", "Dil", "Idioma") }

    // MARK: - Status messages
    var statusApplied:         String { tr("Applied ✓",              "Uygulandı ✓",                 "Aplicado ✓") }
    var statusDpiApplied:      String { tr("DPI Applied ✓",          "DPI Uygulandı ✓",             "DPI Aplicado ✓") }
    var statusSettingsApplied: String { tr("Settings Applied ✓",     "Ayarlar Uygulandı ✓",         "Configurações Aplicadas ✓") }
    var statusDefaultsRestored:String { tr("Defaults Restored ✓",    "Varsayılana Döndürüldü ✓",    "Padrões Restaurados ✓") }
    var statusPollApplied:     String { tr("Polling Rate Applied ✓", "Yoklama Hızı Uygulandı ✓",    "Taxa de Polling Aplicada ✓") }
    func statusProfileApplied(_ name: String) -> String { tr(
        "Profile '\(name)' Applied ✓",
        "Profil '\(name)' Uygulandı ✓",
        "Perfil '\(name)' Aplicado ✓"
    )}
    func statusProfileCreated(_ name: String) -> String { tr(
        "Profile '\(name)' Created ✓",
        "Profil '\(name)' Oluşturuldu ✓",
        "Perfil '\(name)' Criado ✓"
    )}

    // MARK: - Helper
    private func tr(_ en: String, _ tr: String, _ pt: String) -> String {
        switch lang {
        case .english:    return en
        case .turkish:    return tr
        case .portuguese: return pt
        }
    }
}
