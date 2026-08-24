# Navigation-Fix & Startseite-Individualisierung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Meldezettel-Import navigiert zur EinsatzOrtView; Name/Untertitel der Startseite sind in den Einstellungen änderbar.

**Architecture:** Drei unabhängige Änderungen: (1) eine Zeile in `handleScreenshot` korrigieren, (2) neuen `Section` in `SettingsView` hinzufügen mit zwei `@AppStorage`-Feldern, (3) `StartView` liest diese Felder statt hartcodierter Strings.

**Tech Stack:** SwiftUI, `@AppStorage` (UserDefaults-Wrapper)

---

## File Map

| Datei | Aktion | Änderung |
|---|---|---|
| `ContentView 2.swift` | Modify | Zeile 182: `path = [.einsatzOrt]` |
| `Views/SettingsView.swift` | Modify | 2 neue `@AppStorage`-Deklarationen + neuer `Section` oben in `body` |
| `Views/Startview.swift` | Modify | 2 neue `@AppStorage`-Deklarationen + Texte ersetzen |

---

## Task 1: Import-Navigation korrigieren

**Files:**
- Modify: `PatProt/PatProt/PatProt/ContentView 2.swift` (Methode `handleScreenshot`, ca. Zeile 176–185)

- [ ] **Schritt 1: Zeile 182 anpassen**

Aktuelle Zeile in `handleScreenshot(_:)`:
```swift
path = [.einsatzOrt, .abcde]
```

Ersetzen durch:
```swift
path = [.einsatzOrt]
```

Der vollständige Block nach der Änderung:
```swift
private func handleScreenshot(_ image: UIImage) {
    isParsing = true
    Task {
        let daten = await ScreenshotParser.parse(image)
        await MainActor.run {
            applyToCurrentProtokoll(daten)
            isParsing = false
            path = [.einsatzOrt]
        }
    }
}
```

- [ ] **Schritt 2: Manuell testen**

Simulator starten → Meldezettel importieren (Foto aus Bibliothek wählen) → App muss nach dem Ladeoverlay in der **EinsatzOrtView** landen (nicht in ABCDE).

- [ ] **Schritt 3: Commit**

```bash
git add "PatProt/PatProt/PatProt/ContentView 2.swift"
git commit -m "fix: Meldezettel-Import navigiert zu EinsatzOrtView"
```

---

## Task 2: AppStorage-Felder in SettingsView hinzufügen

**Files:**
- Modify: `PatProt/PatProt/PatProt/Views/SettingsView.swift`

- [ ] **Schritt 1: Zwei AppStorage-Eigenschaften deklarieren**

In `SettingsView`, direkt unter den bestehenden `@AppStorage`-Zeilen (nach Zeile 8):

```swift
@AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
@AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"
```

- [ ] **Schritt 2: Neuen Section ganz oben in Form einfügen**

In `body`, vor dem bestehenden `// E-Mail`-Kommentar (vor Zeile 37), neuen Abschnitt einfügen:

```swift
// Startseite
Section {
    TextField("Einheitenname", text: $einheitenname)
        .autocorrectionDisabled(true)
    TextField("Untertitel", text: $startseiteUntertitel)
        .autocorrectionDisabled(true)
} header: {
    Label("Startseite", systemImage: "house.fill")
} footer: {
    Text("Name und Untertitel werden auf der Startseite angezeigt.")
        .font(.footnote).foregroundStyle(.secondary)
}
```

- [ ] **Schritt 3: Im Simulator prüfen**

Einstellungen öffnen → oben erscheint neuer Abschnitt „Startseite" mit zwei Textfeldern, vorausgefüllt mit den Standardwerten.

- [ ] **Schritt 4: Commit**

```bash
git add "PatProt/PatProt/PatProt/Views/SettingsView.swift"
git commit -m "feat: Einstellungen – Startseite-Abschnitt mit Einheitenname und Untertitel"
```

---

## Task 3: StartView die konfigurierten Texte anzeigen lassen

**Files:**
- Modify: `PatProt/PatProt/PatProt/Views/Startview.swift`

- [ ] **Schritt 1: AppStorage-Eigenschaften in StartView deklarieren**

In `StartView`, direkt nach den bestehenden `@State`-Zeilen (nach Zeile 13):

```swift
@AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
@AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"
```

- [ ] **Schritt 2: Hartcodierte Strings ersetzen**

Bestehender Code (Zeilen 27–34):
```swift
Text("First Responder\nGeesthacht")
    .font(.largeTitle).fontWeight(.bold)
    .multilineTextAlignment(.center)

Text("Einsatzprotokollierung\nFirst Responder")
    .font(.subheadline)
    .foregroundColor(.secondary)
    .multilineTextAlignment(.center)
```

Ersetzen durch:
```swift
Text(einheitenname.isEmpty ? "First Responder Geesthacht" : einheitenname)
    .font(.largeTitle).fontWeight(.bold)
    .multilineTextAlignment(.center)

Text(startseiteUntertitel.isEmpty ? "Einsatzprotokollierung First Responder" : startseiteUntertitel)
    .font(.subheadline)
    .foregroundColor(.secondary)
    .multilineTextAlignment(.center)
```

- [ ] **Schritt 3: End-to-End testen**

1. Einstellungen öffnen → „Startseite"-Felder auf eigene Werte ändern, z.B. „FR Geesthacht" / „Lauenburg"
2. Zurück zur Startseite → geänderter Name wird angezeigt
3. Felder leeren → Standardwerte erscheinen (kein leerer Screen)

- [ ] **Schritt 4: Commit**

```bash
git add "PatProt/PatProt/PatProt/Views/Startview.swift"
git commit -m "feat: Startseite zeigt konfigurierten Einheitenname und Untertitel"
```
