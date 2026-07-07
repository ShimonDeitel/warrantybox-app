import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var items: [WarrantyBoxItem] = []
    @Published var isPro: Bool = false

    /// Free tier limit. Kept comfortably above seed count so a fresh install
    /// never immediately hits the paywall.
    static let freeLimit = 8

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("warrantybox_items.json")
        load()
    }

    var canAddMore: Bool {
        isPro || items.count < Store.freeLimit
    }

    func add(_ item: WarrantyBoxItem) {
        items.append(item)
        save()
    }

    func update(_ item: WarrantyBoxItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: WarrantyBoxItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func seedIfNeeded() -> [WarrantyBoxItem] {
        [
            WarrantyBoxItem(name: "Refrigerator", detail: "Best Buy", extra: 24, date: Date()),
            WarrantyBoxItem(name: "Washing Machine", detail: "Home Depot", extra: 12, date: Date()),
            WarrantyBoxItem(name: "Laptop", detail: "Apple Store", extra: 12, date: Date())
        ]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([WarrantyBoxItem].self, from: data) else {
            items = seedIfNeeded()
            save()
            return
        }
        items = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
