//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.textLabel?.adjustsFontForContentSizeCategory = true
        self.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        self.detailTextLabel?.adjustsFontForContentSizeCategory = true

        self.addDefaultPointerInteraction()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
