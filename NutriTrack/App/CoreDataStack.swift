import CoreData
import Foundation

// MARK: - CoreDataStack

final class CoreDataStack: @unchecked Sendable {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentContainer(name: "NutriTrack")

        container.loadPersistentStores { _, error in
            if let error {
                self.loadError = error
            }
        }

        guard loadError == nil else { return }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }

    // MARK: - Background context

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        return ctx
    }

    // MARK: - Save

    @discardableResult
    func saveViewContext() -> Error? {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return nil }
        do {
            try ctx.save()
            return nil
        } catch {
            ctx.rollback()
            return error
        }
    }

    @discardableResult
    func save(context: NSManagedObjectContext) -> Error? {
        guard context.hasChanges else { return nil }
        do {
            try context.save()
            return nil
        } catch {
            context.rollback()
            return error
        }
    }
}
