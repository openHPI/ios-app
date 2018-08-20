//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class CourseDocumentHeader: UITableViewHeaderFooterView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var tagsLabel: UILabel!

    func configure(for document: Document) {
        self.titleLabel.text = document.title
        self.descriptionLabel.text = document.documentDescription
        self.tagsLabel.text = document.tags.isEmpty ? nil : document.tags.joined(separator: " · ")
    }

}
