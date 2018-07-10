//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation

public class AnnouncementHelper {

    public static let shared = AnnouncementHelper()

    public weak var delegate: AnnouncementHelperDelegate?

    private init() {}

    @discardableResult public func syncAllAnnouncements() -> Future<SyncEngine.SyncMultipleResult, XikoloError> {
        let fetchRequest = AnnouncementHelper.FetchRequest.allAnnouncements
        var query = MultipleResourcesQuery(type: Announcement.self)
        query.addFilter(forKey: "global", withValue: "true")
        return SyncEngine.shared.syncResources(withFetchRequest: fetchRequest, withQuery: query).onComplete { _ in
            self.delegate?.updateUnreadAnnouncementsBadge()
        }
    }

    @discardableResult public func syncAnnouncements(for course: Course) -> Future<SyncEngine.SyncMultipleResult, XikoloError> {
        let fetchRequest = AnnouncementHelper.FetchRequest.allAnnouncements
        var query = MultipleResourcesQuery(type: Announcement.self)
        query.addFilter(forKey: "course", withValue: course.id)
        return SyncEngine.shared.syncResources(withFetchRequest: fetchRequest, withQuery: query, deleteNotExistingResources: false).onComplete { _ in
            self.delegate?.updateUnreadAnnouncementsBadge()
        }
    }

    @discardableResult public func markAsVisited(_ item: Announcement) -> Future<Void, XikoloError> {
        guard UserProfileHelper.shared.isLoggedIn && !item.visited else {
            return Future(value: ())
        }

        let promise = Promise<Void, XikoloError>()

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            guard let announcement = context.existingTypedObject(with: item.objectID) as? Announcement else {
                promise.failure(.missingResource(ofType: Announcement.self))
                return
            }

            announcement.visited = true
            announcement.objectState = .modified
            promise.complete(context.saveWithResult())
            self.delegate?.updateUnreadAnnouncementsBadge()
        }

        return promise.future
    }

}

public protocol AnnouncementHelperDelegate: AnyObject {

    func updateUnreadAnnouncementsBadge()

}
