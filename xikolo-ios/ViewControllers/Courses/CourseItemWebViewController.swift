//
//  CourseItemWebViewController.swift
//  xikolo-ios
//
//  Created by Max Bothe on 28.11.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation


class CourseItemWebViewController: WebViewController {

    var courseItem: CourseItem! {
        didSet {
            self.setURL()
        }
    }

    private func setURL() {
        if self.courseItem.content != nil {
            self.url = self.quizURL(for: self.courseItem)
            return
        }

        CourseItemHelper.syncCourseItemWithContent(self.courseItem).onSuccess { objectId in
            CoreDataHelper.viewContext.perform {
                let item = CoreDataHelper.viewContext.object(with: objectId) as CourseItem
                self.url = self.quizURL(for: item)
            }
        }.onFailure { error in
            print("Error: \(error)")
        }
    }

    private func quizURL(for courseItem: CourseItem) -> String {
        let courseURL = Routes.COURSES_URL + (self.courseItem.section?.course?.id ?? "")
        let quizpathURL = "/items/" + courseItem.id
        return courseURL + quizpathURL
    }

}
