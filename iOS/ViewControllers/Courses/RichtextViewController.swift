//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import SafariServices
import UIKit

class RichtextViewController: UIViewController {

    @IBOutlet private weak var titleView: UILabel!
    @IBOutlet private weak var textView: UITextView!

    private var courseItemObserver: ManagedObjectObserver?

    var courseItem: CourseItem! {
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

        self.textView.delegate = self
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0

        ErrorManager.shared.remember(self.courseItem.id, forKey: "item_id")

        CourseItemHelper.syncCourseItemWithContent(self.courseItem)
    }

    private func updateView() {
        self.titleView.text = self.courseItem.title

        guard let richText = self.courseItem.content as? RichText, let markdown = richText.text else {
            self.textView.isHidden = true
            return
        }

        MarkdownHelper.attributedString(for: markdown).onSuccess(DispatchQueue.main.context) { attributedString in
            self.textView.attributedText = attributedString
            self.textView.isHidden = false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let typedInfo = R.segue.richtextViewController.openInWebView(segue: segue) {
            typedInfo.destination.courseItem = self.courseItem
        }
    }

}

extension RichtextViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return !AppNavigator.handle(url: URL, on: self)
    }

}
