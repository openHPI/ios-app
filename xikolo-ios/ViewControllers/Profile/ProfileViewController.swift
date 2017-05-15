//
//  ProfileViewController.swift
//  xikolo-ios
//
//  Created by Jonas Müller on 08.07.15.
//  Copyright © 2015 HPI. All rights reserved.
//

import UIKit
import SDWebImage

class ProfileViewController: AbstractTabContentViewController {

    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var profileImage: UIImageView!

    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var emailView: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var versionView: UILabel!
    @IBOutlet weak var buildView: UILabel!

    @IBAction func logout(_ sender: UIButton) {
        UserProfileHelper.logout()
    }

    var user: UserProfile?

    override func viewDidLoad() {
        super.viewDidLoad()
        versionView.text = NSLocalizedString("Version", comment: "app version") + ": " + UIApplication.appVersion()
        buildView.text = NSLocalizedString("Build", comment: "app version") + ": " + UIApplication.appBuild()
    }

    override func updateUIAfterLoginLogoutAction() {
        super.updateUIAfterLoginLogoutAction()

        if UserProfileHelper.isLoggedIn() {
            nameView.isHidden = false
            emailView.isHidden = false
            logoutButton.isHidden = false

            UserProfileHelper.getUser().onSuccess { user in
                self.nameView.text = user.firstName + " " + user.lastName
                self.emailView.text = user.email
                self.profileImage.sd_setImage(with: URL(string: user.visual))
            }
        } else {
            nameView.isHidden = true
            emailView.isHidden = true
            logoutButton.isHidden = true
            profileImage.image = UIImage(named: "avatar")
        }
    }

}
