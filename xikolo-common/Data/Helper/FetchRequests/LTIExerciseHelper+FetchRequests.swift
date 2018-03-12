//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

extension LTIExerciseHelper {

    struct FetchRequest {

        static func ltiExercise(withId id: String) -> NSFetchRequest<LTIExercise> {
            let request: NSFetchRequest<LTIExercise> = LTIExercise.fetchRequest()
            return request
        }

    }

}
