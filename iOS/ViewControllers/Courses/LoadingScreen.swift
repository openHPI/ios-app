//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import Foundation
import UIKit

public class LoadingScreen: UIViewController {

    @IBOutlet private weak var progressView: CircularProgressView!

    override public func viewDidLoad() {
        super.viewDidLoad()

        let progressValue: CGFloat? = nil
        progressView.updateProgress(progressValue)
    }

}
