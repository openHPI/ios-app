//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation
import SyncEngine

public struct CourseHelper {

    @discardableResult public static func syncAllCourses() -> Future<SyncMultipleResult, XikoloError> {
        var query = MultipleResourcesQuery(type: Course.self)
        query.include("channel")
        query.include("user_enrollment")

        let engine = XikoloSyncEngine()
        return engine.syncResources(withFetchRequest: CourseHelper.FetchRequest.allCourses, withQuery: query).mapError { error -> XikoloError in
            return .synchronization(error)
        }
    }

    @discardableResult public static func syncCourse(_ course: Course) -> Future<SyncSingleResult, XikoloError> {
        var query = SingleResourceQuery(resource: course)
        query.include("channel")
        query.include("user_enrollment")

        let engine = XikoloSyncEngine()
        return engine.syncResource(withFetchRequest: CourseHelper.FetchRequest.course(withId: course.id), withQuery: query).mapError { error -> XikoloError in
            return .synchronization(error)
        }
    }

    @discardableResult public static func syncCourse(forSlugOrId slugOrId: String) -> Future<SyncSingleResult, XikoloError> {
        var query = SingleResourceQuery(type: Course.self, id: slugOrId)
        query.include("channel")
        query.include("user_enrollment")

        let engine = XikoloSyncEngine()
        return engine.syncResource(withFetchRequest: CourseHelper.FetchRequest.course(withSlugOrId: slugOrId), withQuery: query).mapError { error -> XikoloError in
            return .synchronization(error)
        }
    }

    public static func visit(_ course: Course) {
        let courseObjectId = course.objectID
        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            let backgroundCourse = context.existingTypedObject(with: courseObjectId) as? Course
            backgroundCourse?.lastVisited = Date()
            try? context.save()
        }
    }

}
