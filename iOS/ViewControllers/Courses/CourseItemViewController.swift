//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import UIKit

import CoreData

class CourseItemViewController: UIPageViewController {

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
        return label
    }()

    private var previousItem: CourseItem?
    private var nextItem: CourseItem?

    var currentItem: CourseItem? {
        didSet {
            self.trackItemVisit()
            ErrorManager.shared.remember(self.currentItem?.id, forKey: "item_id")

            self.previousItem = self.currentItem?.previousItem
            self.nextItem = self.currentItem?.nextItem

            if let item = self.currentItem, let section = item.section {
                self.progressLabel.text = "\(item.position) / \(section.items.count)"
                self.progressLabel.sizeToFit()
            } else {
                self.progressLabel.text = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        self.view.backgroundColor = ColorCompatibility.systemBackground
        self.navigationItem.titleView = self.progressLabel

        guard let item = self.currentItem else { return }
        guard let newViewController = self.viewController(for: item) else { return }
        self.setViewControllers([newViewController], direction: .forward, animated: false)
    }

    func reload(animated: Bool) {
        guard let item = self.currentItem else { return }
        guard let newViewController = self.viewController(for: item) else { return }
        self.setViewControllers([newViewController], direction: .forward, animated: animated)
    }

    private func viewController(for item: CourseItem) -> CourseItemContentViewController? {
        guard !item.isProctoredInProctoredCourse else {
            let viewController = R.storyboard.courseLearningsProctored.instantiateInitialViewController()
            viewController?.configure(for: item)
            return viewController
        }

        guard item.hasAvailableContent else {
            let viewController = R.storyboard.courseLearningsUnavailable.instantiateInitialViewController()
            viewController?.configure(for: item)
            viewController?.delegate = self
            return viewController
        }

        let viewController: CourseItemContentViewController? = {
            switch item.contentType {
            case "video":
                return R.storyboard.courseLearningsVideo.instantiateInitialViewController()
            case "rich_text":
                return R.storyboard.courseLearningsRichtext.instantiateInitialViewController()
            case "lti_exercise":
                return R.storyboard.courseLearningsLTI.instantiateInitialViewController()
            default:
                return R.storyboard.courseLearningsWeb.instantiateInitialViewController()
            }
        }()

        viewController?.configure(for: item)
        return viewController
    }

    private func trackItemVisit() {
        guard let item = self.currentItem else { return }
        guard !item.isProctoredInProctoredCourse else { return }
        guard item.hasAvailableContent else { return }

        CourseItemHelper.markAsVisited(item)
        let context = [
            "content_type": item.contentType,
            "section_id": item.section?.id,
            "course_id": item.section?.course?.id,
        ]
        TrackingHelper.createEvent(.visitedItem, resourceType: .item, resourceId: item.id, on: self, context: context)
    }

}

extension CourseItemViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let item = self.previousItem else { return nil }
        guard let newViewController = self.viewController(for: item) else { return nil }
        return newViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let item = self.nextItem else { return nil }
        guard let newViewController = self.viewController(for: item) else { return nil }
        return newViewController
    }

}

extension CourseItemViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard finished && completed else {
            return
        }

        guard let currentCourseItemContentViewController = self.viewControllers?.first as? CourseItemContentViewController else {
            return
        }

        self.currentItem = currentCourseItemContentViewController.item
    }

}
