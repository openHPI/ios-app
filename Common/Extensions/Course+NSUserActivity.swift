//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

extension Course {

    public var openCourseUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: Bundle.main.activityTypeOpenCourse.require())
        userActivity.title = title
        userActivity.userInfo = ["courseID": id ]
        return userActivity
    }

}
