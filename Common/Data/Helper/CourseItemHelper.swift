//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation
import SyncEngine

public enum CourseItemHelper {

    public static func syncCourseItems(forSection section: CourseSection) -> Future<SyncMultipleResult, XikoloError> {
        let fetchRequest = Self.FetchRequest.orderedCourseItems(forSection: section)
        var query = MultipleResourcesQuery(type: CourseItem.self)
        query.addFilter(forKey: "section", withValue: section.id)
        return XikoloSyncEngine().synchronize(withFetchRequest: fetchRequest, withQuery: query)
    }

    public static func syncCourseItems(forCourse course: Course) -> Future<SyncMultipleResult, XikoloError> {
        let fetchRequest = Self.FetchRequest.courseItems(forCourse: course)
        var query = MultipleResourcesQuery(type: CourseItem.self)
        query.addFilter(forKey: "course", withValue: course.id)
        query.include("content")
        return XikoloSyncEngine().synchronize(withFetchRequest: fetchRequest, withQuery: query)
    }

    @discardableResult public static func syncCourseItems(forCourse course: Course,
                                                          withContentType type: String) -> Future<SyncMultipleResult, XikoloError> {
        let fetchRequest = Self.FetchRequest.courseItems(forCourse: course, withContentType: type)
        var query = MultipleResourcesQuery(type: CourseItem.self)
        query.addFilter(forKey: "course", withValue: course.id)
        query.addFilter(forKey: "content_type", withValue: type)
        query.include("content")
        return XikoloSyncEngine().synchronize(withFetchRequest: fetchRequest, withQuery: query, deleteNotExistingResources: false)
    }

    @discardableResult public static func syncCourseItems(forSection section: CourseSection,
                                                          withContentType type: String) -> Future<SyncMultipleResult, XikoloError> {
        let fetchRequest = Self.FetchRequest.courseItems(forSection: section, withContentType: type)
        var query = MultipleResourcesQuery(type: CourseItem.self)
        query.addFilter(forKey: "section", withValue: section.id)
        query.addFilter(forKey: "content_type", withValue: type)
        query.include("content")
        return XikoloSyncEngine().synchronize(withFetchRequest: fetchRequest, withQuery: query, deleteNotExistingResources: false)
    }

    @discardableResult public static func syncCourseItemWithContent(_ courseItem: CourseItem) -> Future<SyncSingleResult, XikoloError> {
        let fetchRequest = Self.FetchRequest.courseItem(withId: courseItem.id)
        var query = SingleResourceQuery(resource: courseItem)
        query.include("content")
        return XikoloSyncEngine().synchronize(withFetchRequest: fetchRequest, withQuery: query)
    }

    @discardableResult public static func markAsVisited(_ item: CourseItem) -> Future<Void, XikoloError> {
        guard !item.visited else {
            return Future(value: ())
        }

        let promise = Promise<Void, XikoloError>()

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            guard let courseItem = context.existingTypedObject(with: item.objectID) as? CourseItem else {
                promise.failure(.missingResource(ofType: CourseItem.self))
                return
            }

            courseItem.visited = true
            courseItem.objectState = .modified
            promise.complete(context.saveWithResult())
        }

        return promise.future
    }

}
