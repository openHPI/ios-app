//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Down

public enum MarkdownHelper {

    static func makeDynamicFont(for font: UIFont) -> UIFont {
        if #available(iOS 11, *) {
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        } else {
            return font
        }
    }

    static let dynamicCodeFont: DownFont = {
        if #available(iOS 12, *) {
            return .monospacedSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        } else if let menlo = UIFont(name: "menlo", size: UIFont.labelFontSize) {
            return menlo
        } else if let courierNew = UIFont(name: "Courier New", size: UIFont.labelFontSize) {
            return courierNew
        } else {
            return .systemFont(ofSize: UIFont.labelFontSize)
        }
    }()

    static let dynamicFontCollection = StaticFontCollection(
        heading1: Self.makeDynamicFont(for: .systemFont(ofSize: UIFont.labelFontSize * 1.30, weight: .bold)),
        heading2: Self.makeDynamicFont(for: .systemFont(ofSize: UIFont.labelFontSize * 1.25, weight: .bold)),
        heading3: Self.makeDynamicFont(for: .systemFont(ofSize: UIFont.labelFontSize * 1.20, weight: .bold)),
        body: .preferredFont(forTextStyle: .body),
        code: dynamicCodeFont,
        listItemPrefix: Self.makeDynamicFont(for: DownFont.monospacedDigitSystemFont(ofSize: UIFont.labelFontSize * 1.0, weight: .regular))
    )

    static let dynamicTypeStylerConfiguration = DownStylerConfiguration(
        fonts: dynamicFontCollection
    )

    static func dataTask(for url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask {
        guard let absoluteURL = URL(string: url.absoluteString, relativeTo: Routes.base) else {
            return URLSession.shared.dataTask(with: url, completionHandler: completionHandler)
        }

        return URLSession.shared.dataTask(with: absoluteURL, completionHandler: completionHandler)
    }

    public static func string(for markdown: String) -> String {
        let down = Down(markdownString: markdown)
        let attributedString = try? down.toAttributedString()
        return attributedString?.string ?? ""
    }

    public static func attributedString(for markdown: String) -> NSAttributedString {
        let down = Down(markdownString: markdown)
        let styler = NoImagesStyler(configuration: self.dynamicTypeStylerConfiguration)
        let attributedString = try? down.toAttributedString(.smartUnsafe, styler: styler)
        return attributedString ?? NSAttributedString()
    }

    public static func attributedStringWithImages(for markdown: String, layoutChangeHandler: (() -> Void)? = nil) -> NSAttributedString {
        let down = Down(markdownString: markdown)
        let styler = AsyncImagesStyler(imageLoader: self.dataTask(for:completionHandler:), layoutChangeHandler: layoutChangeHandler, configuration: self.dynamicTypeStylerConfiguration)
        let attribtuedString = try? down.toAttributedString(.smartUnsafe, styler: styler)
        return attribtuedString ?? NSAttributedString()
    }

}

