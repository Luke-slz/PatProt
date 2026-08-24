# Design: Navigation-Fix & Startseite-Individualisierung

**Datum:** 2026-05-19  
**Status:** Approved

---

## Scope

Drei unabhängige Änderungen an der PatProt-App (iPhone-Flow):

1. Import-Navigation nach Meldezettel-Import korrigieren
2. Neuen Einstellungsbereich „Startseite" hinzufügen
3. StartView die konfigurierten Texte anzeigen lassen

---

## 1 – Import-Navigation Fix

**Datei:** `ContentView 2.swift`, Methode `handleScreenshot(_:)`, Zeile 182

**Ist-Zustand:** Nach erfolgreichem OCR-Import wird `path = [.einsatzOrt, .abcde]` gesetzt — der Nutzer landet in der ABCDE-Übersicht.

**Soll-Zustand:** `path = [.einsatzOrt]` — der Nutzer landet in der EinsatzOrtView, sieht die importierten Felder (Adresse, Einsatznummer, Stichwort, Zeiten usw.) und navigiert selbst weiter.

**Begründung:** Sofortige Kontrolle der importierten Daten ist wichtiger als schnelles Vorwärtsnavigieren.

---

## 2 – Einstellungen: Startseite-Abschnitt

**Datei:** `Views/SettingsView.swift`

Neuer `Section` ganz oben (vor dem E-Mail-Abschnitt):

```
Section header: Label("Startseite", systemImage: "house.fill")
footer: "Name und Untertitel werden auf der Startseite angezeigt."

  TextField("Einheitenname", text: $einheitenname)
  TextField("Untertitel", text: $startseiteUntertitel)
```

**AppStorage-Keys:**
- `"einheitenname"` — Standardwert `"First Responder Geesthacht"`
- `"startseiteUntertitel"` — Standardwert `"Einsatzprotokollierung First Responder"`

Beide Keys werden als `@AppStorage` direkt in `SettingsView` deklariert.

---

## 3 – StartView anpassen

**Datei:** `Views/Startview.swift`

Die beiden hardcodierten Strings werden durch `@AppStorage`-Lesungen ersetzt:

```swift
@AppStorage("einheitenname") private var einheitenname = "First Responder Geesthacht"
@AppStorage("startseiteUntertitel") private var startseiteUntertitel = "Einsatzprotokollierung First Responder"
```

Leere Felder → Fallback auf den jeweiligen Standardwert (via `.isEmpty`-Check mit `??`-Logik oder direkt über `@AppStorage`-Default).

Der `Text`-Block in `StartView.body` ersetzt die beiden Literale durch diese Variablen.

---

## Navigations-Audit

Alle Views wurden geprüft. Ergebnis: kein Handlungsbedarf.
- Explizite `onBack`-Closures rufen überall `path.removeLast()` auf.
- `ReanimationView` hat keinen expliziten Back-Button, nutzt aber den automatischen NavigationStack-Back-Button — korrekt.
- `AbschlussView` nutzt `@Environment(\.dismiss)` für Sheet-Contexts — korrekt.

---

## Was nicht geändert wird

- Buttons auf der Startseite (Reihenfolge/Sichtbarkeit) — bleiben fest
- iPad-Flow (`iPadMainView`) — kein Scope
- Backend/Services — kein Scope
