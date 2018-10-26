//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

extension CourseSectionHelper {

    public enum FetchRequest {

        static func orderedCourseSections(forCourse course: Course) -> NSFetchRequest<CourseSection> {
            let request: NSFetchRequest<CourseSection> = CourseSection.fetchRequest()
            let coursePredicate = NSPredicate(format: "course = %@", course)
            let accessiblePredicate = NSPredicate(format: "accessible == true")
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [coursePredicate, accessiblePredicate])
            let positionSort = NSSortDescriptor(key: "position", ascending: true)
            request.sortDescriptors = [positionSort]
            return request
        }

        static func allCourseSections(forCourse course: Course) -> NSFetchRequest<CourseSection> {
            let request: NSFetchRequest<CourseSection> = CourseSection.fetchRequest()
            request.predicate = NSPredicate(format: "course = %@", course)
            return request
        }

        public static func nextUnpublishedSection(for course: Course) -> NSFetchRequest<CourseSection> {
            let request: NSFetchRequest<CourseSection> = CourseSection.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "course = %@", course),
                NSPredicate(format: "startsAt > %@", NSDate()),
            ])
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CourseSection.startsAt, ascending: true)]
            request.fetchLimit = 1
            return request
        }

    }

}
