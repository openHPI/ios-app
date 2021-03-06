//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common

@available(iOS 11.0, *)
extension CourseItem {

    func dragItem(with previewView: UIView?) -> UIDragItem {
        let itemProvider = NSItemProvider(object: self)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = self

        // Use default preview if no preview view was passed
        dragItem.previewProvider = previewView.flatMap { view -> (() -> UIDragPreview?) in
            return { () -> UIDragPreview? in
                let parameters = UIDragPreviewParameters()
                parameters.visiblePath = UIBezierPath(roundedRect: view.bounds, cornerRadius: CALayer.CornerStyle.default.rawValue)
                return UIDragPreview(view: view, parameters: parameters)
            }
        }

        return dragItem
    }

}
