//
//  NewsArticleViewController.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 04.07.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import UIKit

class NewsArticleViewController : UIViewController {

    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateView: UILabel!

    var newsArticle: NewsArticle!

    override func viewDidLoad() {
        super.viewDidLoad()

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        let date = newsArticle.published_at!

        dateView.text = dateFormatter.stringFromDate(date)
        titleView.text = newsArticle.title
        if let newsText = newsArticle.text {
            textView.attributedText = MarkdownParser.parse(newsText)
        }
    }

}
