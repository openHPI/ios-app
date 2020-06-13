//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import MobileCoreServices // for kUTTypeURL

@available(iOS 11.0, *)
extension Course {

    func dragItem(for traitCollection: UITraitCollection) -> UIDragItem {
        let userActivity = self.openCourseUserActivity
        let itemProvider = NSItemProvider(object: self)
        itemProvider.registerObject(userActivity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = self

        dragItem.previewProvider = { () -> UIDragPreview? in
            let courseImage = UIImageView()
            courseImage.sd_setImage(with: self.imageURL)
            let previewWidth = CourseCell.minimalWidth(for: traitCollection)
            let previewHeight = previewWidth / 2
            courseImage.frame = CGRect(x: 0, y: 0, width: previewWidth, height: previewHeight)
            courseImage.layer.roundCorners(for: .default)
            courseImage.contentMode = .scaleAspectFill
            return UIDragPreview(view: courseImage)
        }

        return dragItem
    }

}

extension Course: NSItemProviderWriting {
    // MARK: - NSItemProviderWriting

    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [
            kUTTypeUTF8PlainText as String,
            kUTTypeURL as String,
        ]
    }

    public func loadData(withTypeIdentifier typeIdentifier: String,
                         forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        if typeIdentifier == kUTTypeUTF8PlainText as String {
            let titleUrl = [self.title, self.url?.absoluteString].compactMap({ $0 }).joined(separator: "\n")
            completionHandler(titleUrl.data(using: .utf8), nil)
        } else if typeIdentifier == kUTTypeURL as String {
            let dropRepresentation = self.url.flatMap({ URLDropRepresentation(url: $0, title: self.title) })
            let data = try? dropRepresentation.map(PropertyListEncoder().encode)
            completionHandler(data, nil)
        }

        return nil
    }
}

private struct URLDropRepresentation: Encodable {
    let url: URL
    let title: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.url.absoluteString)
        try container.encode("")
        try container.encode(self.metadata)
    }

    private var metadata: [String: String] {
        guard let title = self.title else {
            return [:]
        }

        return ["title": title]
    }
}
