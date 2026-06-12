import Foundation
import CoreData
import Combine
import SwiftUI

final class DataStore: ObservableObject {
    static let shared = DataStore()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TrackModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("CoreData load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let ctx = container.viewContext
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                // print("save error \(error)")
            }
        }
    }

    func delete(_ session: Session) {
        container.viewContext.delete(session)
        save()
    }

    func allSessions() -> [Session] {
        let req: NSFetchRequest<Session> = Session.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Session.startTime, ascending: false)]
        return (try? container.viewContext.fetch(req)) ?? []
    }
}
