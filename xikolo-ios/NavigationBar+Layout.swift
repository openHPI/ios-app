//
//  NavigationBar+Layout.swift
//  xikolo-ios
//
//  Created by Max Bothe on 28.11.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import UIKit

class XikoloNavigationController : UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.barTintColor = UIColor.white
        self.navigationBar.isTranslucent = true
        self.navigationBar.shadowImage = UIImage()

        if #available(iOS 11.0, *) {
            // Nothing to do here
        } else {
            self.hideShadowImage(inView: self.view)
        }
    }

    func fixShadowImage() {
        self.hideShadowImage(inView: self.view)
    }

    @discardableResult func hideShadowImage(inView view: UIView) -> Bool {
        if let imageView = view as? UIImageView {
            let size = imageView.bounds.size.height
            if size <= 1 && size > 0 && imageView.subviews.count == 0 {
                let forcedBackground = UIView(frame: imageView.bounds)
                forcedBackground.backgroundColor = .white
                imageView.addSubview(forcedBackground)
                forcedBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                return true
            }
        }
        for subview in view.subviews {
            if self.hideShadowImage(inView: subview) {
                break
            }
        }
        return false
    }

}
