//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

public extension LastVisitHelper {

    enum FetchRequest {

        public static func lastVisit(forCourse course: Course) -> NSFetchRequest<LastVisit> {
            let request: NSFetchRequest<LastVisit> = LastVisit.fetchRequest()
            request.predicate = NSPredicate(format: "id = %@", course.id)
            request.fetchLimit = 1
            return request
        }

    }

}
