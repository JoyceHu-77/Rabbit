//
//  PersistenceController.swift
//  Rabbit_iOS
//

import CoreData

final class PersistenceController: @unchecked Sendable {
    nonisolated static let shared = PersistenceController()

    let container: NSPersistentContainer

    nonisolated init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RabbitModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    nonisolated func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Save failed: \(error)")
        }
    }
}
