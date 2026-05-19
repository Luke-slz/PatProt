import SwiftUI
import UIKit
import Combine

// MARK: - App-weiter State für Screenshot-Import

@MainActor
class AppState: ObservableObject {
    @Published var pendingImage: UIImage? = nil
    static let shared = AppState()

    private init() {
        // iCloud-Sync deaktiviert (Personal Team). Für Option A (paid Developer Account):
        // syncFromiCloud() aufrufen und den NotificationCenter-Observer einkommentieren.
        // syncFromiCloud()
        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(iCloudDidChange),
        //     name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        //     object: NSUbiquitousKeyValueStore.default
        // )
    }

    // Für Option A: Methode einkommentieren und in init() aufrufen
    // @objc private func iCloudDidChange() {
    //     DispatchQueue.main.async { self.syncFromiCloud() }
    // }

    // Personalnamen werden bewusst NICHT synchronisiert (DSGVO: bleiben lokal auf dem Gerät)
    // Für Option A: beide Methoden einkommentieren und Entitlement wieder aktivieren
    // private func syncFromiCloud() {
    //     let kvs = NSUbiquitousKeyValueStore.default
    //     for key in ["recipientEmail", "customFahrzeuge", "standardFahrzeugNamen"] {
    //         if let val = kvs.string(forKey: key), !val.isEmpty {
    //             UserDefaults.standard.set(val, forKey: key)
    //         }
    //     }
    // }

    // static func pushSettingsToiCloud() {
    //     let kvs = NSUbiquitousKeyValueStore.default
    //     for key in ["recipientEmail", "customFahrzeuge", "standardFahrzeugNamen"] {
    //         if let val = UserDefaults.standard.string(forKey: key) {
    //             kvs.set(val, forKey: key)
    //         }
    //     }
    // }
}

// MARK: - App Entry Point

@main
struct PatProtApp: App {
    @ObservedObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.isFileURL else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        var image: UIImage?
        if let data = try? Data(contentsOf: url) {
            image = UIImage(data: data)
        }

        if let img = image {
            DispatchQueue.main.async {
                AppState.shared.pendingImage = img
            }
        }
    }
}
