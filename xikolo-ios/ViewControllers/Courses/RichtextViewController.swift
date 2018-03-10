//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import SafariServices
import UIKit

class RichtextViewController : AbstractItemRichtextViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0
        CrashlyticsHelper.shared.setObjectValue(self.courseItem.id, forKey: "item_id")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openInWebView" {
            let webView = segue.destination.require(toHaveType: CourseItemWebViewController.self)
            webView.courseItem = self.courseItem
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

}

extension RichtextViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var url = URL
        if (URL.scheme == "applewebdata") { // replace applewebdata with baseURL for relative urls in markdown
            var absoluteString = URL.absoluteString
            let trimmedUrlString = absoluteString.stringByRemovingRegexMatches(pattern: "^(?:applewebdata://[0-9A-Z-]*/?)", replaceWith: Brand.BaseURL + "/")
            guard let trimmedString = trimmedUrlString else { return false }
            guard let trimmedURL = getURL(forString: trimmedString) else { return false }
            url = trimmedURL
        }
        if !(url.scheme?.hasPrefix("http") ?? false) { // abort if it still isnt http
            return false
        }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
        safariVC.preferredControlTintColor = Brand.windowTintColor
        return false
    }

    func getURL(forString string: String) -> URL? {
        return URL(string: string) // necessary because someone clever put the argument in CAPS in the function above
    }

}
