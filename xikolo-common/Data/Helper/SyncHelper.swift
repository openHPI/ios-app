//
//  SyncHelper.swift
//  xikolo-ios
//
//  Created by Jan Renz and Max Bothe
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation
import CoreData


class SyncHelper {
    static let standard = SyncHelper()

    func startObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataChange(note:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: CoreDataHelper.viewContext)
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: CoreDataHelper.viewContext)
    }

    //support for videos should follow once they contain the seo texts
    
    @objc func coreDataChange(note: Notification) {
        if let updated = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updated.count > 0 {
            for case let course as Course in updated {
                SearchHelper.addSearchIndex(for: course)
            }
        }

        if let deleted = note.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, deleted.count > 0 {
            for case let course as Course in deleted {
                SearchHelper.removeSearchIndex(for: course)
            }
        }

        if let inserted = note.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserted.count > 0 {
            for case let course as Course in inserted {
                SearchHelper.addSearchIndex(for: course)
            }
        }
    }
}
