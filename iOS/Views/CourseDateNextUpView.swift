//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class CourseDateNextUpView: UIStackView {

    @IBOutlet private weak var container: UIView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var courseLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private var widthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.container.layer.cornerRadius = 6.0

        self.courseLabel.textColor = Brand.default.colors.secondary
        self.isHidden = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedOnView))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    func loadData() {
        if let courseDate = CoreDataHelper.viewContext.fetchSingle(CourseDateHelper.FetchRequest.nextCourseDate).value {
            self.dateLabel.text = courseDate.formattedDateWithTimeZone
            self.courseLabel.text = courseDate.course?.title
            self.titleLabel.text = courseDate.contextAwareTitle
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }

    @objc func tappedOnView() {
        if let course = CoreDataHelper.viewContext.fetchSingle(CourseDateHelper.FetchRequest.nextCourseDate).value?.course {
            if #available(iOS 13.0, *) {
                let sceneDelegate = self.superview?.window?.windowScene?.delegate as! SceneDelegate
                sceneDelegate.appNavigator.show(course: course)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let cellWidth = CourseCell.minimalWidth(for: self.traitCollection)
        self.widthConstraint.constant = cellWidth - 2 * CourseCell.cardInset
    }

}
