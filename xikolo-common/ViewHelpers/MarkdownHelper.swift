//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Down
import HTMLStyler

struct MarkdownHelper {

    static let parser: Parser = {
        var parser = Parser()
        parser.styleCollection = DefaultStyleCollection(tintColor: Brand.Color.primary)
        return parser
    }()

    static func string(for markdown: String) -> String {
        let html = try? Down(markdownString: markdown).toHTML()
        return self.parser.string(for: html ?? "")
    }

    static func attributedString(for markdown: String) -> Future<NSMutableAttributedString, XikoloError> {
        let html = try? Down(markdownString: markdown).toHTML()
        return Future { complete in
            DispatchQueue.global().async {
                let attributedString = self.parser.attributedString(for: html ?? "")
                complete(.success(attributedString))
            }
        }
    }

    static func trueScheme(for url: URL) -> URL? {
        var url = url
        if url.scheme == "applewebdata" { // replace applewebdata with baseURL for relative urls in markdown
            var absoluteString = url.absoluteString
            let trimmedUrlString = absoluteString.stringByRemovingRegexMatches(pattern: "^(?:applewebdata://[0-9A-Z-]*/?)",
                                                                               replaceWith: Routes.base.absoluteString + "/")
            guard let trimmedString = trimmedUrlString else { return nil }
            guard let trimmedURL = URL(string: trimmedString) else { return nil }
            url = trimmedURL
        }

        guard url.scheme?.hasPrefix("http") ?? false else { return nil }

        return url
    }

}
