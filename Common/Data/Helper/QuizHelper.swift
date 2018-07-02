//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation

struct QuizHelper {

    @discardableResult static func syncQuiz(_ quiz: Quiz) -> Future<SyncEngine.SyncSingleResult, XikoloError> {
        let fetchRequest = QuizHelper.FetchRequest.quiz(withId: quiz.id)
        var query = SingleResourceQuery(resource: quiz)
        query.include("questions")
        query.include("submission")
        return SyncEngine.shared.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }

}
