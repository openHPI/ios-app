//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import Foundation

class CourseItemWebViewController: WebViewController {

    var courseItem: CourseItem! {
        didSet {
            self.setURL()
        }
    }

    private func setURL() {
        guard let courseId = self.courseItem.section?.course?.id else { return }
        self.url = Routes.courses.appendingPathComponents([courseId, "items", courseItem.id])
    }

}

extension CourseItemWebViewController: CourseItemContentPresenter {

    var item: CourseItem? {
        return self.courseItem
    }

    func configure(for item: CourseItem) {
        self.courseItem = item
    }

}
