import SwiftUI

// MARK: - Protokoll-Archiv

struct ArchivView: View {
    @ObservedObject private var archiv = ProtokollArchiv.shared
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @Environment(\.dismiss) private var dismiss

    var onLaden: (() -> Void)?

    @State private var zuLoeschen: ProtokollDaten? = nil
    @State private var ladeError: String? = nil

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if archiv.protokolle.isEmpty {
                    ContentUnavailableView(
                        "Keine gespeicherten Protokolle",
                        systemImage: "doc.text",
                        description: Text("Protokolle können beim Abschluss gespeichert werden.")
                    )
                } else {
                    List {
                        ForEach(archiv.protokolle) { p in
                            ArchivZeile(daten: p, dateFmt: dateFmt)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    protokoll.apply(from: p)
                                    onLaden?()
                                    dismiss()
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        zuLoeschen = p
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Protokoll-Archiv")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .confirmationDialog(
                "Protokoll löschen?",
                isPresented: Binding(get: { zuLoeschen != nil }, set: { if !$0 { zuLoeschen = nil } }),
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let p = zuLoeschen { archiv.loeschen(p.id) }
                    zuLoeschen = nil
                }
                Button("Abbrechen", role: .cancel) { zuLoeschen = nil }
            } message: {
                if let p = zuLoeschen {
                    Text("Das Protokoll vom \(dateFmt.string(from: p.erstelltAm)) wird unwiderruflich gelöscht.")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Archiv Zeile

private struct ArchivZeile: View {
    let daten: ProtokollDaten
    let dateFmt: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(patientName).font(.headline)
                Spacer()
                if daten.kritisch {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
            }
            HStack(spacing: 8) {
                Label(dateFmt.string(from: daten.erstelltAm), systemImage: "calendar")
                    .font(.caption).foregroundStyle(.secondary)
                if !daten.einsatzOrt.stichwort.isEmpty {
                    Text("·").foregroundStyle(.secondary)
                    Text(daten.einsatzOrt.stichwort).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if !daten.einsatzOrt.adresse.isEmpty {
                Text(daten.einsatzOrt.adresse).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var patientName: String {
        let v = daten.patientDaten.vorname
        let n = daten.patientDaten.nachname
        if v.isEmpty && n.isEmpty { return "Unbekannter Patient" }
        if v.isEmpty { return n }
        if n.isEmpty { return v }
        return "\(n), \(v)"
    }
}
