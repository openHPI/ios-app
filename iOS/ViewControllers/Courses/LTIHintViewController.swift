//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class LTIHintViewController: UIViewController {

    private static let pointsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    @IBOutlet private weak var itemTitleLabel: UILabel!
    @IBOutlet private weak var instructionsView: UITextView!
    @IBOutlet private weak var typeView: UILabel!
    @IBOutlet private weak var pointsView: UILabel!
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var minimumTextViewHeightContraint: NSLayoutConstraint!
    
    weak var delegate: CourseItemViewController?

    private var courseItemObserver: ManagedObjectObserver?

    private var courseItem: CourseItem! {
        didSet {
            self.courseItemObserver = ManagedObjectObserver(object: self.courseItem) { [weak self] type in
                guard type == .update else { return }
                DispatchQueue.main.async {
                    self?.updateView()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.startButton.layer.roundCorners(for: .default)

        self.instructionsView.delegate = self
        self.instructionsView.textContainerInset = UIEdgeInsets.zero
        self.instructionsView.textContainer.lineFragmentPadding = 0

        self.updateView()
        CourseItemHelper.syncCourseItemWithContent(self.courseItem)
    }

    func updateView() {
        guard let ltiExercise = self.courseItem?.content as? LTIExercise else { return }

        self.itemTitleLabel.text = self.courseItem?.title
        self.startButton.backgroundColor = Brand.default.colors.primary

        self.instructionsView.setMarkdownWithImages(from: ltiExercise.instructions, minimumHeightContraint: self.minimumTextViewHeightContraint)


        switch self.courseItem.exerciseType {
        case "main":
            self.typeView.text = NSLocalizedString("course.item.exercise-type.disclaimer.main", comment: "course item main type")
        case "bonus":
            self.typeView.text = NSLocalizedString("course.item.exercise-type.disclaimer.bonus", comment: "course item bonus type")
        case "selftest":
            self.typeView.text = NSLocalizedString("course.item.exercise-type.disclaimer.ungraded", comment: "course item ungraded type")
        default:
            self.typeView.isHidden = true
        }

        let format = NSLocalizedString("course-item.max-points", comment: "maximum points for course item")
        let number = NSNumber(value: self.courseItem.maxPoints)
        self.pointsView.text = Self.pointsFormatter.string(from: number).flatMap { String.localizedStringWithFormat(format, $0) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let item = self.courseItem, let ltiExercise = item.content as? LTIExercise else { return }
        if let typedInfo = R.segue.ltiHintViewController.openLTIURL(segue: segue) {
            typedInfo.destination.url = ltiExercise.launchURL
        }
    }
}

extension LTIHintViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let appNavigator = self.appNavigator else { return false }
        return !appNavigator.handle(url: URL, on: self)
    }

}

extension LTIHintViewController: CourseItemContentPresenter {

    var item: CourseItem? {
        return self.courseItem
    }

    func configure(for item: CourseItem) {
        self.courseItem = item
    }

}
