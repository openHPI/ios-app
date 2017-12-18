//
//  CoreDataHelper.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 02.06.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import CoreData
import BrightFutures
import Result

class CoreDataHelper {

    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "xikolo")
        container.loadPersistentStores { (storeDescription, error) in
            // TODO: check for space etc
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
        return container
    }()

    static let viewContext = persistentContainer.viewContext

    static func createResultsController<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>,
                                                            sectionNameKeyPath: String?) -> NSFetchedResultsController<T> {
        // TODO: Add cache name
        return NSFetchedResultsController<T>(fetchRequest: fetchRequest,
                                             managedObjectContext: self.persistentContainer.viewContext,
                                             sectionNameKeyPath: sectionNameKeyPath,
                                             cacheName: nil)
    }

    static func clearCoreDataStorage() -> Future<Void, XikoloError> {
        return self.persistentContainer.managedObjectModel.entitiesByName.keys.traverse { entityName in
            return self.clearCoreDataEntity(entityName)
        }.asVoid()
    }

    private static func clearCoreDataEntity(_ entityName: String) -> Future<Void, XikoloError> {
        let promise = Promise<Void, XikoloError>()

        self.persistentContainer.performBackgroundTask { privateManagedObjectContext in
            privateManagedObjectContext.shouldDeleteInaccessibleFaults = true
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try privateManagedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult
                guard let objectIDArray = result?.result as? [NSManagedObjectID] else { return }
                let changes = [NSDeletedObjectsKey : objectIDArray]
                print("Try to delete all enities of \(entityName) (\(objectIDArray.count) enities)")
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                try privateManagedObjectContext.save()

                promise.success(())
            } catch {
                print("Failed to bulk delete all enities of \(entityName) - \(error)")
                promise.failure(.coreData(error))
            }
        }

        return promise.future
    }

}


extension NSManagedObjectContext {

    func fetchSingle<T>(_ fetchRequest: NSFetchRequest<T>) -> Result<T, XikoloError> where T: NSManagedObject {
        do {
            let objects = try self.fetch(fetchRequest)

            guard objects.count < 2 else {
                return .failure(.coreDataObjectNotFound)
            }

            guard let object = objects.first else {
                return .failure(.coreDataMoreThanOneObjectFound)
            }

            return .success(object)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func fetchMultiple<T>(_ fetchRequest: NSFetchRequest<T>) -> Result<[T], XikoloError> where T: NSManagedObject {
        do {
            let objects = try self.fetch(fetchRequest)
            return .success(objects)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func typedObject<T>(with id: NSManagedObjectID) -> T where T: NSManagedObject {
        let managedObject = self.object(with: id)
        guard let object = managedObject as? T else {
            fatalError("Type mismatch for NSManagedObject (expected: \(T.self), found: \(type(of: managedObject)))")
        }

        return object
    }

    func existingTypedObject<T>(with id: NSManagedObjectID) -> T? where T: NSManagedObject {
        guard let managedObject = try? self.existingObject(with: id) else {
            print("Info: NSManagedObject could not be retrieved by id (\(id))")
            return nil
        }

        guard let object = managedObject as? T else {
            print("Error: Type mismatch for NSManagedObject (expected: \(T.self), found: \(type(of: managedObject)))")
            return nil
        }

        return object
    }

    func saveWithResult() -> Result<Void, XikoloError> {
        do {
            if self.hasChanges {
                try self.save()
            }
            return .success(())
        } catch {
            return .failure(.coreData(error))
        }
    }

}
