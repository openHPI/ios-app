//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Stockpile

extension CourseHelper {

    public enum FetchRequest {

        private static let visiblePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status != %@", "preparation"),
        ])

        private static let deletedEnrollmentPredicate = NSPredicate(format: "enrollment.objectStateValue = %d", ObjectState.deleted.rawValue)
        private static let notDeletedEnrollmentPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: deletedEnrollmentPredicate)

        private static let enrolledPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "enrollment != nil"),
            notDeletedEnrollmentPredicate,
        ])
        private static let notEnrolledPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "enrollment = nil"),
            deletedEnrollmentPredicate,
        ])

        private static let completedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            enrolledPredicate,
            NSPredicate(format: "enrollment.completed = %@", NSNumber(value: true)),
        ])
        private static let notCompletedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSCompoundPredicate(andPredicateWithSubpredicates: [
                enrolledPredicate,
                NSPredicate(format: "enrollment.completed = %@", NSNumber(value: false)),
            ]),
            notEnrolledPredicate,
        ])

        private static let futurePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "startsAt = nil"),
            NSPredicate(format: "startsAt > now()"),
        ])
        private static let pastPredicate: NSPredicate = {
            if Brand.default.showCurrentCoursesInSelfPacedSection {
                return NSCompoundPredicate(notPredicateWithSubpredicate: futurePredicate)
            } else {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "endsAt != nil"),
                    NSPredicate(format: "endsAt < now()"),
                ])
            }
        }()

        private static let currentCoursesPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            visiblePredicate,
            NSCompoundPredicate(notPredicateWithSubpredicate: futurePredicate),
            NSCompoundPredicate(notPredicateWithSubpredicate: pastPredicate),
        ])
        private static let upcomingCoursesPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            visiblePredicate,
            futurePredicate,
        ])
        private static let selfPacedCoursesPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            visiblePredicate,
            pastPredicate,
        ])
        private static let searchableCoursesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            currentCoursesPredicate,
            upcomingCoursesPredicate,
            selfPacedCoursesPredicate,
        ])

        private static let customOrderSortDescriptor = NSSortDescriptor(keyPath: \Course.order, ascending: true)

        private static var visibleCoursesRequest: NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.sortDescriptors = [self.customOrderSortDescriptor]
            request.predicate = self.visiblePredicate
            return request
        }

        static func course(withId courseId: String) -> NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSPredicate(format: "id = %@", courseId)
            request.fetchLimit = 1
            return request
        }

        public static func course(withSlugOrId slugOrId: String) -> NSFetchRequest<Course> {
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "slug = %@", slugOrId),
                NSPredicate(format: "id = %@", slugOrId),
            ])
            request.fetchLimit = 1
            return request
        }

        static var allCourses: NSFetchRequest<Course> {
            return Course.fetchRequest() as NSFetchRequest<Course>
        }

        public static var visibleCourses: NSFetchRequest<Course> {
            let request = Course.fetchRequest() as NSFetchRequest<Course>
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.startsAt, ascending: false)]
            return request
        }

        public static var currentCourses: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = self.currentCoursesPredicate
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.startsAt, ascending: true),
                NSSortDescriptor(keyPath: \Course.title, ascending: true),
            ]
            return request
        }

        public static var upcomingCourses: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = self.upcomingCoursesPredicate
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.startsAt, ascending: true),
                NSSortDescriptor(keyPath: \Course.title, ascending: true),
            ]
            return request
        }

        public static var selfpacedCourses: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = self.selfPacedCoursesPredicate
            return request
        }

        public static var searchableCourses: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = self.searchableCoursesPredicate
            return request
        }

        public static var enrolledCurrentCoursesRequest: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                visiblePredicate,
                enrolledPredicate,
                notCompletedPredicate,
            ])
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.lastVisited, ascending: false),
                self.customOrderSortDescriptor,
            ]
            return request
        }

        public static var completedCourses: NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                visiblePredicate,
                enrolledPredicate,
                completedPredicate,
            ])
            return request
        }

        public static func currentCourses(for channel: Channel) -> NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.currentCoursesPredicate,
                NSPredicate(format: "channel = %@", channel),
            ])
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.startsAt, ascending: true),
                NSSortDescriptor(keyPath: \Course.title, ascending: true),
            ]
            return request
        }

        public static func upcomingCourses(for channel: Channel) -> NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.upcomingCoursesPredicate,
                NSPredicate(format: "channel = %@", channel),
            ])
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.startsAt, ascending: true),
                NSSortDescriptor(keyPath: \Course.title, ascending: true),
            ]
            return request
        }

        public static func selfpacedCourses(for channel: Channel) -> NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.selfPacedCoursesPredicate,
                NSPredicate(format: "channel = %@", channel),
            ])
            return request
        }

        public static func searchableCourses(for channel: Channel) -> NSFetchRequest<Course> {
            let request = self.visibleCoursesRequest
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.searchableCoursesPredicate,
                NSPredicate(format: "channel = %@", channel),
            ])
            return request
        }

        public static var distinctLanguages: NSFetchRequest<NSDictionary> {
            let entityName = Course.entity().name!
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
            fetchRequest.predicate = self.visiblePredicate
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = [NSString(string: "language")]
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.returnsDistinctResults = true
            return fetchRequest
        }

        public static var categories: NSFetchRequest<NSDictionary> {
            let entityName = Course.entity().name!
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                 self.visiblePredicate,
                 NSPredicate(format: "categories != nil"),
            ])
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = [NSString(string: "categories")]
            fetchRequest.returnsObjectsAsFaults = false
            return fetchRequest
        }

        public static var topics: NSFetchRequest<NSDictionary> {
            let entityName = Course.entity().name!
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.visiblePredicate,
                NSPredicate(format: "topics != nil"),
            ])
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = [NSString(string: "topics")]
            fetchRequest.returnsObjectsAsFaults = false
            return fetchRequest
        }

    }

}
