//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import Foundation
import UIKit

extension CourseDateListViewController {

    public func courseDatesNavigationController(for course: Course) -> UINavigationController {
            self.course = course
            let navigationController = XikoloNavigationController(rootViewController: self)
            navigationController.navigationBar.barTintColor = ColorCompatibility.systemBackground
            return navigationController
        }

}
