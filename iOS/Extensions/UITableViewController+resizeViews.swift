//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

extension UITableView {

    func resizeTableHeaderView() {
        self.resizeSupplementaryView(withKeyPath: \UITableView.tableHeaderView)
    }

    func resizeTableFooterView() {
        self.resizeSupplementaryView(withKeyPath: \UITableView.tableFooterView)
    }

    private func resizeSupplementaryView(withKeyPath keyPath: ReferenceWritableKeyPath<UITableView, UIView?>) {
        guard let view = self[keyPath: keyPath] else { return }
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        guard view.frame.size.height != size.height else { return }
        view.frame.size.height = size.height
        self[keyPath: keyPath] = view

        if self.window != nil {
            self.layoutIfNeeded()
        }
    }

}
