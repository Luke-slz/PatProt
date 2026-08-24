# PDF-Aufwertung & Foto-Anhang — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PDF aufwerten (ABCDE "o.B.", SAMPLER bedingt), Medikamentenplan + Patientenfotos als PDF-Anhang-Seiten, Foto-Aufnahme in SAMPLER M-Feld, PDF-Positionshinweise in ABCDE- und SAMPLER-Eingabefeldern.

**Architecture:** Sieben unabhängige, sequentielle Tasks. Datenmodell zuerst (Task 1), dann neue UI-Komponente (Task 2), dann Views (Tasks 3–5), zuletzt PDF-Logik (Tasks 6–7). Jeder Task ist eigenständig kompilierbar.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit (UIImagePickerController), PhotosUI (PHPickerViewController), UIGraphicsPDFRenderer, Swift Testing (`@Test`, `#expect`)

---

## Dateien-Übersicht

| Datei | Aktion |
|-------|--------|
| `PatProtTests/PatProtTests.swift` | Modify — neue Tests für Modell |
| `Models/Models.swift` | Modify — `medikamentFotos` + `reset()` |
| `Views/MedikamentFotoView.swift` | **Create** — Kamera/Bibliothek-Wrapper + Thumbnail-View |
| `Views/SAMPLERView.swift` | Modify — M-Sektion ersetzen, neues Binding, Hinweise |
| `ContentView 2.swift` | Modify — SAMPLERView Aufruf aktualisieren |
| `Views/iPadMainView.swift` | Modify — SAMPLERView Aufruf aktualisieren |
| `Views/ABCDEDetailViews.swift` | Modify — PDF-Hinweise in allen 5 Views |
| `Services/PDFGenerator.swift` | Modify — ABCDE o.B., SAMPLER bedingt, drawFotoPages |

---

## Task 1: Datenmodell — medikamentFotos

**Files:**
- Modify: `Models/Models.swift` (Zeilen ~143–179)
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Failing-Tests schreiben**

Öffne `PatProtTests/PatProtTests.swift` und füge am Ende des `PatProtTests`-Structs ein:

```swift
@Test func medikamentFotosInitialisierenLeer() {
    let p = EinsatzProtokoll()
    #expect(p.medikamentFotos.isEmpty)
}

@Test func resetLeertMedikamentFotos() {
    let p = EinsatzProtokoll()
    // Füge ein Dummy-FotoEintrag hinzu (ohne echte Datei)
    p.medikamentFotos.append(FotoEintrag(bildDateiname: "test.jpg"))
    p.reset()
    #expect(p.medikamentFotos.isEmpty)
}
```

- [ ] **Schritt 2: Tests fehlschlagen lassen**

In Xcode: Product → Test (⌘U).  
Erwartet: Kompilierungsfehler „Value of type 'EinsatzProtokoll' has no member 'medikamentFotos'"

- [ ] **Schritt 3: Feld hinzufügen**

In `Models/Models.swift`, nach Zeile 144 (`@Published var fotos: [FotoEintrag] = []`) einfügen:

```swift
// Medikamentenplan-Fotos (in-app only, nicht archiviert)
@Published var medikamentFotos: [FotoEintrag] = []
```

- [ ] **Schritt 4: reset() aktualisieren**

In `Models/Models.swift`, in `reset()` nach `fotos.forEach { $0.loeschen() }` / `fotos = []` (Zeilen ~178–179) einfügen:

```swift
medikamentFotos.forEach { $0.loeschen() }
medikamentFotos = []
```

- [ ] **Schritt 5: Tests laufen lassen**

Product → Test (⌘U).  
Erwartet: `medikamentFotosInitialisierenLeer` ✓, `resetLeertMedikamentFotos` ✓

- [ ] **Schritt 6: Commit**

```bash
git add PatProtTests/PatProtTests.swift "PatProt/Models/Models.swift"
git commit -m "feat: add medikamentFotos field to EinsatzProtokoll"
```

---

## Task 2: Neue MedikamentFotoView-Komponente

**Files:**
- Create: `Views/MedikamentFotoView.swift`

Diese Komponente stellt zwei UIViewControllerRepresentable-Wrapper bereit (`CameraImagePicker`, `PhotoLibraryPicker`) und eine SwiftUI-View `MedikamentFotoSektion`, die in SAMPLERView eingebettet wird.

- [ ] **Schritt 1: Datei erstellen**

Erstelle `Views/MedikamentFotoView.swift` mit folgendem Inhalt:

```swift
import SwiftUI
import PhotosUI

// MARK: - Kamera-Picker

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var fotos: [FotoEintrag]
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                let filename = "medifoto_\(UUID().uuidString).jpg"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try? data.write(to: url)
                DispatchQueue.main.async {
                    self.parent.fotos.append(FotoEintrag(bildDateiname: filename))
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Fotobibliothek-Picker

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var fotos: [FotoEintrag]
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    guard let image = obj as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.85) else { return }
                    let filename = "medifoto_\(UUID().uuidString).jpg"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    try? data.write(to: url)
                    DispatchQueue.main.async {
                        self.parent.fotos.append(FotoEintrag(bildDateiname: filename))
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail-Zeile + Buttons

struct MedikamentFotoSektion: View {
    @Binding var fotos: [FotoEintrag]
    @State private var zeigeKamera = false
    @State private var zeigeBibliothek = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !fotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(fotos) { foto in
                            ZStack(alignment: .topTrailing) {
                                Group {
                                    if let image = UIImage(contentsOfFile: foto.bildURL.path) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.secondary.opacity(0.2)
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    fotos.removeAll { $0.id == foto.id }
                                    foto.loeschen()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, Color.black.opacity(0.6))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 92)
            }

            HStack(spacing: 12) {
                Button {
                    zeigeKamera = true
                } label: {
                    Label("Kamera", systemImage: "camera")
                }
                .buttonStyle(.bordered)

                Button {
                    zeigeBibliothek = true
                } label: {
                    Label("Bibliothek", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }

            Text("→ PDF S. 3ff. · Foto-Anhang")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $zeigeKamera) {
            CameraImagePicker(fotos: $fotos)
        }
        .sheet(isPresented: $zeigeBibliothek) {
            PhotoLibraryPicker(fotos: $fotos)
        }
    }
}
```

- [ ] **Schritt 2: In Xcode zur Target-Membership hinzufügen**

In Xcode: Die neue Datei `MedikamentFotoView.swift` im Project Navigator auswählen → File Inspector rechts → Target Membership → „PatProt" ✓ setzen (falls nicht automatisch gesetzt).

- [ ] **Schritt 3: Kompilierung prüfen**

Product → Build (⌘B).  
Erwartet: Build Succeeded (keine Fehler).

- [ ] **Schritt 4: Commit**

```bash
git add "PatProt/Views/MedikamentFotoView.swift"
git commit -m "feat: add MedikamentFotoView with camera and library pickers"
```

---

## Task 3: SAMPLERView — M-Sektion ersetzen + neues Binding + Hinweise

**Files:**
- Modify: `Views/SAMPLERView.swift`

- [ ] **Schritt 1: Struct-Signatur erweitern**

In `SAMPLERView.swift`, die Struct-Definition ändern von:

```swift
struct SAMPLERView: View {
    @Binding var befund: SAMPLERBefund
    var onZurueck: () -> Void
```

zu:

```swift
struct SAMPLERView: View {
    @Binding var befund: SAMPLERBefund
    @Binding var medikamentFotos: [FotoEintrag]
    var onZurueck: () -> Void
```

- [ ] **Schritt 2: M-Sektion ersetzen**

Die gesamte bestehende M-Sektion:

```swift
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("M — Medikamente").font(.subheadline.bold())
        Text("Aktuelle Medikation").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.medikamente).frame(minHeight: 70)
    }
}
```

ersetzen durch:

```swift
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("M — Medikamente (Foto)").font(.subheadline.bold())
        Text("Aktuelle Medikation als Foto dokumentieren")
            .font(.caption).foregroundColor(.secondary)
        MedikamentFotoSektion(fotos: $medikamentFotos)
    }
}
```

- [ ] **Schritt 3: PDF-Hinweise zu den restlichen Feldern hinzufügen**

Für jede verbleibende SAMPLER-Sektion (S, A, P, L, E, R) den jeweiligen Hinweis-Text **nach** dem TextEditor/TextField einfügen. Die finale Struktur aller 6 Sektionen:

```swift
// S
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("S — Symptome").font(.subheadline.bold())
        Text("Hauptbeschwerde des Patienten").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.symptome).frame(minHeight: 70)
        Text("→ PDF S. 1 · SAMPLER · S").font(.caption2).foregroundColor(.secondary)
    }
}
// A
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("A — Allergien").font(.subheadline.bold())
        Text("Bekannte Allergien und Unverträglichkeiten").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.allergien).frame(minHeight: 60)
        Text("→ PDF S. 1 · SAMPLER · A").font(.caption2).foregroundColor(.secondary)
    }
}
// (M-Sektion: bereits in Schritt 2 erledigt)
// P
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("P — Patientenvorgeschichte").font(.subheadline.bold())
        Text("Relevante Vorerkrankungen und Operationen").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
        Text("→ PDF S. 1 · SAMPLER · P").font(.caption2).foregroundColor(.secondary)
    }
}
// L
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("L — Letzte Mahlzeit").font(.subheadline.bold())
        Text("Wann und was zuletzt gegessen/getrunken").font(.caption).foregroundColor(.secondary)
        TextField("z.B. heute Morgen, Brot und Kaffee", text: $befund.letztesMahl)
        Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
    }
}
// E
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("E — Ereignis").font(.subheadline.bold())
        Text("Was hat zum Notfall geführt?").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.ereignis).frame(minHeight: 70)
        Text("→ PDF S. 1 · SAMPLER · E").font(.caption2).foregroundColor(.secondary)
    }
}
// R
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("R — Risikofaktoren").font(.subheadline.bold())
        Text("Bekannte Risikofaktoren").font(.caption).foregroundColor(.secondary)
        TextEditor(text: $befund.risikofaktoren).frame(minHeight: 60)
        Text("→ PDF S. 1 · SAMPLER · R").font(.caption2).foregroundColor(.secondary)
    }
}
```

- [ ] **Schritt 4: Kompilierung prüfen**

Product → Build (⌘B).  
Erwartet: Kompilierungsfehler an den SAMPLERView-Aufrufstellen wegen fehlendem `medikamentFotos`-Parameter — das ist erwartet, wird in Task 4 behoben.

- [ ] **Schritt 5: Commit**

```bash
git add "PatProt/Views/SAMPLERView.swift"
git commit -m "feat: replace SAMPLER M text field with photo capture, add PDF hints"
```

---

## Task 4: Aufrufstellen von SAMPLERView aktualisieren

**Files:**
- Modify: `ContentView 2.swift` (Zeile ~121)
- Modify: `Views/iPadMainView.swift` (Zeile ~417)

- [ ] **Schritt 1: ContentView 2.swift aktualisieren**

In `ContentView 2.swift`, die Zeile:

```swift
SAMPLERView(befund: $protokoll.sampler) { path.removeLast() }
```

ersetzen durch:

```swift
SAMPLERView(befund: $protokoll.sampler,
            medikamentFotos: $protokoll.medikamentFotos) { path.removeLast() }
```

- [ ] **Schritt 2: iPadMainView.swift aktualisieren**

In `Views/iPadMainView.swift`, die Zeile:

```swift
SAMPLERView(befund: $protokoll.sampler) { selectedSection = .sinnhaft }
```

ersetzen durch:

```swift
SAMPLERView(befund: $protokoll.sampler,
            medikamentFotos: $protokoll.medikamentFotos) { selectedSection = .sinnhaft }
```

- [ ] **Schritt 3: Kompilierung prüfen**

Product → Build (⌘B).  
Erwartet: Build Succeeded (keine Fehler).

- [ ] **Schritt 4: Manuell testen**

App starten → SAMPLER öffnen → M-Sektion zeigt Foto-Buttons (kein TextEditor mehr) → Kamera-Button öffnet Kamera-Sheet (auf echtem Gerät oder Simulator mit Camera-Fallback) → Foto erscheint als Thumbnail → X-Button löscht Thumbnail.

- [ ] **Schritt 5: Commit**

```bash
git add "PatProt/ContentView 2.swift" "PatProt/Views/iPadMainView.swift"
git commit -m "feat: update SAMPLERView call sites with medikamentFotos binding"
```

---

## Task 5: ABCDEDetailViews — PDF-Positionshinweise

**Files:**
- Modify: `Views/ABCDEDetailViews.swift`

In jedem der 5 Views den PDF-Hinweis **innerhalb der Freitext-Section nach dem TextEditor** einfügen.

- [ ] **Schritt 1: AirwayView — Freitext-Section anpassen**

Suche in `ABCDEDetailViews.swift` nach:

```swift
Section {
    TextEditor(text: $befund.freitext)
        .frame(minHeight: 80)
} header: { Text("Freitext / Notizen") }
```

(Das ist die Section in `AirwayView`.)  
Ersetzen durch:

```swift
Section {
    TextEditor(text: $befund.freitext)
        .frame(minHeight: 80)
    Text("→ PDF S. 1 · ABCDE · A")
        .font(.caption2)
        .foregroundColor(.secondary)
} header: { Text("Freitext / Notizen") }
```

- [ ] **Schritt 2: BreathingView — Freitext-Section anpassen**

Suche nach der Freitext-Section in `BreathingView` (hat `.frame(minHeight: 80)` im TextEditor, direkt vor `.safeAreaInset` von BreathingView):

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
} header: { Text("Freitext / Notizen") }
```

Ersetzen durch:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
    Text("→ PDF S. 1 · ABCDE · B")
        .font(.caption2)
        .foregroundColor(.secondary)
} header: { Text("Freitext / Notizen") }
```

- [ ] **Schritt 3: CirculationView — Freitext-Section anpassen**

Gleiche Section in `CirculationView`:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
} header: { Text("Freitext / Notizen") }
```

Ersetzen durch:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
    Text("→ PDF S. 1 · ABCDE · C")
        .font(.caption2)
        .foregroundColor(.secondary)
} header: { Text("Freitext / Notizen") }
```

- [ ] **Schritt 4: DisabilityView — Freitext-Section anpassen**

Gleiche Section in `DisabilityView`:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
} header: { Text("Freitext / Notizen") }
```

Ersetzen durch:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
    Text("→ PDF S. 1 · ABCDE · D")
        .font(.caption2)
        .foregroundColor(.secondary)
} header: { Text("Freitext / Notizen") }
```

- [ ] **Schritt 5: ExposureView — Freitext-Section anpassen**

Gleiche Section in `ExposureView`:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
} header: { Text("Freitext / Notizen") }
```

Ersetzen durch:

```swift
Section {
    TextEditor(text: $befund.freitext).frame(minHeight: 80)
    Text("→ PDF S. 1 · ABCDE · E")
        .font(.caption2)
        .foregroundColor(.secondary)
} header: { Text("Freitext / Notizen") }
```

- [ ] **Schritt 6: Kompilierung + Sichtprüfung**

Product → Build (⌘B). App starten → A–E-Views öffnen → grauer Hinweis-Text `→ PDF S. 1 · ABCDE · [Buchstabe]` erscheint unter dem TextEditor.

- [ ] **Schritt 7: Commit**

```bash
git add "PatProt/Views/ABCDEDetailViews.swift"
git commit -m "feat: add PDF location hints to ABCDE freitext fields"
```

---

## Task 6: PDFGenerator — ABCDE "o.B." + SAMPLER bedingte Darstellung

**Files:**
- Modify: `Services/PDFGenerator.swift` (Funktion `drawPage1`, ca. Zeilen 372–395 und 717–735)

- [ ] **Schritt 1: ABCDE — "o.B." für leere Felder**

In `drawPage1`, suche die `abcdeVals`-Definition (Zeilen ~374–380):

```swift
let abcdeVals = [
    p.airway.freitext,
    p.breathing.freitext,
    p.circulation.freitext,
    p.disability.freitext,
    p.exposure.freitext,
]
```

Ersetzen durch:

```swift
let abcdeRaw = [
    p.airway.freitext,
    p.breathing.freitext,
    p.circulation.freitext,
    p.disability.freitext,
    p.exposure.freitext,
]
let abcdeVals  = abcdeRaw.map { $0.isEmpty ? "o.B." : $0 }
let abcdeColors = abcdeRaw.map { $0.isEmpty ? UIColor.lightGray : UIColor.black }
```

- [ ] **Schritt 2: ABCDE-Loop — Farbe übergeben**

Im selben ABCDE-Loop, suche die `txt()`-Zeile für den Inhalt (ca. Zeile 391):

```swift
txt(abcdeVals[i], CGRect(x:lx+14,y:ry+3,width:cw-4,height:rowH-6), font:f7)
```

Ersetzen durch:

```swift
txt(abcdeVals[i], CGRect(x:lx+14,y:ry+3,width:cw-4,height:rowH-6),
    font: abcdeColors[i] == UIColor.lightGray ? UIFont.italicSystemFont(ofSize: 7) : f7,
    color: abcdeColors[i])
```

- [ ] **Schritt 3: SAMPLER — bedingtes Rendering**

Suche den SAMPLER-Block in `drawPage1` (Zeilen ~719–735):

```swift
if y + 80 < pageSize.height - 15 {
    secHeader("SAMPLER-Anamnese", x:lx, y:y, w:rx-lx)
    y += 11
    let samplerData: [(String,String)] = [
        ("S – Symptome", p.sampler.symptome),
        ("A – Allergien", p.sampler.allergien),
        ("M – Medikamente", p.sampler.medikamente),
        ("P – Vorgeschichte", p.sampler.patientenVorgeschichte),
        ("L – Letztes Essen", p.sampler.letztesMahl),
        ("E – Ereignis", p.sampler.ereignis),
        ("R – Risikofaktoren", p.sampler.risikofaktoren),
    ]
    for (label, value) in samplerData {
        guard y + 11 < pageSize.height - 15 else { break }
        field(label, value, x:lx, y:y, w:rx-lx, h:11, lw:85)
        y += 11
    }
}
```

Ersetzen durch:

```swift
if y + 80 < pageSize.height - 15 {
    secHeader("SAMPLER-Anamnese", x:lx, y:y, w:rx-lx)
    y += 11

    var samplerData: [(String, String)] = []
    if !p.sampler.symptome.isEmpty            { samplerData.append(("S – Symptome",      p.sampler.symptome)) }
    if !p.sampler.allergien.isEmpty           { samplerData.append(("A – Allergien",     p.sampler.allergien)) }
    if !p.medikamentFotos.isEmpty {
        samplerData.append(("M – Medikamente", "Medikamentenplan: Foto-Anhang (S. 3ff.)"))
    } else if !p.sampler.medikamente.isEmpty {
        samplerData.append(("M – Medikamente", p.sampler.medikamente))
    }
    if !p.sampler.patientenVorgeschichte.isEmpty { samplerData.append(("P – Vorgeschichte", p.sampler.patientenVorgeschichte)) }
    if !p.sampler.letztesMahl.isEmpty            { samplerData.append(("L – Letztes Essen", p.sampler.letztesMahl)) }
    if !p.sampler.ereignis.isEmpty               { samplerData.append(("E – Ereignis",      p.sampler.ereignis)) }
    if !p.sampler.risikofaktoren.isEmpty         { samplerData.append(("R – Risikofaktoren", p.sampler.risikofaktoren)) }

    if samplerData.isEmpty {
        if y + 11 < pageSize.height - 15 {
            fillRect(CGRect(x: lx, y: y, width: rx - lx, height: 11), .white)
            strokeRect(CGRect(x: lx, y: y, width: rx - lx, height: 11))
            txt("– nicht erhoben –", CGRect(x: lx + 3, y: y + 2, width: rx - lx - 6, height: 7),
                font: f7, color: .lightGray)
            y += 11
        }
    } else {
        for (label, value) in samplerData {
            guard y + 11 < pageSize.height - 15 else { break }
            field(label, value, x: lx, y: y, w: rx - lx, h: 11, lw: 85)
            y += 11
        }
    }
}
```

- [ ] **Schritt 4: Kompilierung**

Product → Build (⌘B). Erwartet: Build Succeeded.

- [ ] **Schritt 5: Manuell testen**

App starten → leeres Protokoll → PDF exportieren:
- ABCDE-Grid: Alle 5 Zeilen zeigen "o.B." in grau kursiv
- SAMPLER-Block: Zeigt "– nicht erhoben –"

Dann Felder befüllen → PDF erneut exportieren:
- Befüllte ABCDE-Felder zeigen Text in schwarz, leere weiter "o.B."
- Nur befüllte SAMPLER-Zeilen erscheinen

- [ ] **Schritt 6: Commit**

```bash
git add "PatProt/Services/PDFGenerator.swift"
git commit -m "feat: ABCDE shows o.B. for empty fields, SAMPLER skips empty rows"
```

---

## Task 7: PDFGenerator — drawFotoPages + generate() aktualisieren

**Files:**
- Modify: `Services/PDFGenerator.swift`

- [ ] **Schritt 1: drawFotoPages Methode einfügen**

Füge direkt vor `drawFooter` am Ende von `PDFGenerator` (vor Zeile ~1178) ein:

```swift
// ─────────────────────────────────────────────────────
// MARK: - Foto-Anhang Seiten
// ─────────────────────────────────────────────────────

private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                   mediFotos: [FotoEintrag],
                                   patFotos: [FotoEintrag],
                                   erstelltAm: Date) {
    let groups: [(String, [FotoEintrag])] = [
        ("Medikamentenplan", mediFotos),
        ("Patientenfoto",    patFotos),
    ].filter { !$1.isEmpty }

    for (label, fotos) in groups {
        for (i, foto) in fotos.enumerated() {
            guard let image = UIImage(contentsOfFile: foto.bildURL.path) else { continue }
            ctx.beginPage()

            // Header
            let hh: CGFloat = 22
            fillRect(CGRect(x: 0, y: 0, width: pageSize.width, height: hh), colBlue)
            txt("\(label) – Foto \(i + 1) / \(fotos.count)",
                CGRect(x: lx, y: 3, width: pageSize.width - lx - 4, height: 16),
                font: f13b, color: .white)

            // Foto: aspect-fit in verfügbarem Bereich
            let footerH: CGFloat = 14
            let availW = rx - lx
            let availH = pageSize.height - hh - footerH - 8
            let imageArea = CGRect(x: lx, y: hh + 4, width: availW, height: availH)

            let imgSize = image.size
            guard imgSize.width > 0, imgSize.height > 0 else {
                drawFooter(erstelltAm: erstelltAm)
                continue
            }
            let scale = min(imageArea.width / imgSize.width, imageArea.height / imgSize.height)
            let scaledW = imgSize.width * scale
            let scaledH = imgSize.height * scale
            let drawRect = CGRect(
                x: imageArea.midX - scaledW / 2,
                y: imageArea.midY - scaledH / 2,
                width: scaledW,
                height: scaledH
            )
            image.draw(in: drawRect)
            drawFooter(erstelltAm: erstelltAm)
        }
    }
}
```

- [ ] **Schritt 2: generate() aktualisieren**

Suche die `generate()` Methode (Zeilen ~168–185). Den `renderer.writePDF`-Block:

```swift
try renderer.writePDF(to: url) { ctx in
    ctx.beginPage()
    drawPage1(p: protokoll)
    ctx.beginPage()
    drawPage2(p: protokoll)
}
```

ersetzen durch:

```swift
try renderer.writePDF(to: url) { ctx in
    ctx.beginPage()
    drawPage1(p: protokoll)
    ctx.beginPage()
    drawPage2(p: protokoll)
    drawFotoPages(ctx: ctx,
                  mediFotos: protokoll.medikamentFotos,
                  patFotos: protokoll.fotos,
                  erstelltAm: protokoll.erstelltAm)
}
```

- [ ] **Schritt 3: Kompilierung**

Product → Build (⌘B). Erwartet: Build Succeeded.

- [ ] **Schritt 4: Manuell testen — End-to-End**

App starten → Protokoll mit Daten befüllen:
1. In SAMPLER → M → Kamera-Button → Foto aufnehmen → Thumbnail erscheint
2. Allgemeines Foto in der Foto-Sektion der App aufnehmen (falls verfügbar)
3. PDF exportieren
4. PDF öffnen:
   - Seite 1: SAMPLER M-Zeile zeigt „Medikamentenplan: Foto-Anhang (S. 3ff.)"
   - Seite 3: Medikamentenplan-Foto mit blauem Header „Medikamentenplan – Foto 1 / 1"
   - Seite 4 (falls allg. Foto): „Patientenfoto – Foto 1 / 1"

Ohne Fotos: PDF hat nur 2 Seiten (kein leerer Anhang).

- [ ] **Schritt 5: Alle Tests laufen lassen**

Product → Test (⌘U). Alle bisherigen Tests müssen grün bleiben.

- [ ] **Schritt 6: Commit**

```bash
git add "PatProt/Services/PDFGenerator.swift"
git commit -m "feat: append medication and patient photos as PDF pages"
```

---

## Selbst-Review

**Spec-Abdeckung:**
- [x] ABCDE "o.B." für leere Felder → Task 6, Schritt 1–2
- [x] SAMPLER leere Felder weglassen → Task 6, Schritt 3
- [x] SAMPLER M mit Foto-Hinweis → Task 6, Schritt 3
- [x] SAMPLER "– nicht erhoben –" wenn alles leer → Task 6, Schritt 3
- [x] Medikamentenfoto-Aufnahme in SAMPLERView → Tasks 2–3
- [x] Beliebig viele Fotos → Task 2 (PHPicker `selectionLimit = 0`)
- [x] Fotos als eigene PDF-Seiten → Task 7
- [x] Allgemeine App-Fotos ebenfalls angehängt → Task 7 (`patFotos: protokoll.fotos`)
- [x] PDF-Positionshinweise in ABCDE-Views → Task 5
- [x] PDF-Positionshinweise in SAMPLER-Views → Task 3
- [x] `medikamentFotos` im Modell → Task 1
- [x] `reset()` bereinigt `medikamentFotos` → Task 1
- [x] SAMPLERView Aufrufstellen aktualisiert → Task 4
