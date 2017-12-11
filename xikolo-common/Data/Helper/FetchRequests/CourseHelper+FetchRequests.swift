//
//  CourseHelper+FetchRequests.swift
//  xikolo-ios
//
//  Created by Max Bothe on 15.11.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import CoreData

extension CourseHelper {

    struct FetchRequest {

        private static let genericPredicate = NSPredicate(format: "external != %@", NSNumber(booleanLiteral: true))
        private static let deletedEnrollmentPrecidate = NSPredicate(format: "enrollment.objectStateValue = %d", ObjectState.deleted.rawValue)
        private static let notDeletedEnrollmentPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: deletedEnrollmentPrecidate)
        private static let rawEnrolledPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "enrollment != nil"), notDeletedEnrollmentPredicate])
        private static let enrolledPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [genericPredicate, rawEnrolledPredicate])
        private static let rawUnenrolledPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(format: "enrollment = nil"), deletedEnrollmentPrecidate])
        private static let unenrolledPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [genericPredicate, rawUnenrolledPredicate])
        private static let announcedPredicate = NSPredicate(format: "status = %@", "announced")
        private static let previewPredicate = NSPredicate(format: "status = %@", "preview")
        private static let activePredicate = NSPredicate(format: "status = %@", "active")
        private static let selfpacedPredicate = NSPredicate(format: "status = %@", "self-paced")
        private static let interestingPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [announcedPredicate, previewPredicate, activePredicate])
        private static let accessiblePredicate = NSPredicate(format: "accessible = %@", NSNumber(booleanLiteral: true))
        private static let completedPredicate = NSPredicate(format: "enrollment.completed = %@", NSNumber(booleanLiteral: true))
        private static let notcompletedPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: completedPredicate)

        private static var genericCoursesRequest: NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            let customOrderSort = NSSortDescriptor(key: "order", ascending: true)
            request.sortDescriptors = [customOrderSort]
            request.predicate = self.genericPredicate
            return request
        }

        static func course(withId courseId: String) -> NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSPredicate(format: "id = %@", courseId)
            request.fetchLimit = 1
            return request
        }

        static func course(withSlug courseSlug: String) -> NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSPredicate(format: "slug = %@", courseSlug)
            request.fetchLimit = 1
            return request
        }

        static var allCourses: NSFetchRequest<Course> {
            return Course.fetchRequest() as NSFetchRequest<Course>
        }

        static var unenrolledCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = self.unenrolledPredicate
            return request
        }

        static var enrolledCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = enrolledPredicate
            return request
        }

        static var interestingCoursesRequest: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unenrolledPredicate, interestingPredicate])
            return request
        }

        static var currentCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [accessiblePredicate, notcompletedPredicate, activePredicate])
            return request
        }

        static var upcomingCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [announcedPredicate, notcompletedPredicate])
            return request
        }

        static var selfpacedCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [selfpacedPredicate])
            return request
        }

        static var pastCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unenrolledPredicate, selfpacedPredicate])
            return request
        }

        static var enrolledAccessibleCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, accessiblePredicate, notcompletedPredicate])
            return request
        }

        static var enrolledCurrentCoursesRequest: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, accessiblePredicate, notcompletedPredicate, activePredicate])
            return request
        }

        static var enrolledSelfPacedCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, accessiblePredicate, notcompletedPredicate, selfpacedPredicate])
            return request
        }

        static var enrolledUpcomingCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, announcedPredicate, notcompletedPredicate])
            return request
        }

        static var enrolledNotCompletedCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, notcompletedPredicate])
            return request
        }

        static var completedCourses: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [enrolledPredicate, completedPredicate])
            return request
        }

        static var allCoursesSectioned: NSFetchRequest<Course> {
            let request = self.genericCoursesRequest
            let enrolledSort = NSSortDescriptor(key: "enrollment", ascending: false)
            let startDateSort = NSSortDescriptor(key: "startsAt", ascending: false)
            request.sortDescriptors = [enrolledSort, startDateSort]
            return request
        }

    }

}
