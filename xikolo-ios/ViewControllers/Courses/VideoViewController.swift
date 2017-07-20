//
//  VideoViewController.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 23.05.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoViewController : UIViewController {

    @IBOutlet weak var containerVideoView: UIView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var openSlidesButton: UIButton!
    @IBOutlet var descriptionViewHeightConstraint: NSLayoutConstraint!

    var courseItem: CourseItem?
    var video: Video?
    var videoPlayerConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleView.text = self.courseItem?.title

        guard let video = self.courseItem?.content as? Video else {
            return
        }

        // display local data
        self.show(video: video)

        // refresh data
        VideoHelper.sync(video: video).onSuccess { videoComplete in
            self.show(video: videoComplete)
        }
    }

    func show(video: Video) {
        self.video = video

        // show slides button
        self.openSlidesButton.isHidden = (video.slides_url == nil)

        // show description
        if let summary = video.summary {
            let markDown = try? MarkdownHelper.parse(summary)
            self.descriptionView.attributedText = markDown
            self.descriptionView.isHidden = markDown?.string.isEmpty ?? true

            // update size of description view
            self.descriptionView.textContainerInset = UIEdgeInsets.zero
            let maxSize = CGSize(width: self.descriptionView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)
            let fittingSize = self.descriptionView.sizeThatFits(maxSize)
            self.descriptionViewHeightConstraint.constant = fittingSize.height
            self.descriptionView.needsUpdateConstraints()
        } else {
            self.descriptionView.isHidden = true
        }

        // configure video player
        if !self.videoPlayerConfigured && video.hlsURL != nil {
            self.videoPlayerConfigured = true
            self.performSegue(withIdentifier: "EmbedAVPlayer", sender: nil)
        }
    }

    @IBAction func openSlides(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowSlides", sender: self.video)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "EmbedAVPlayer"?:
            if let destination = segue.destination as? AVPlayerViewController, let url = self.video?.hlsURL {
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                destination.player = AVPlayer(url: url)
            }
        case "ShowSlides"?:
            if let vc = segue.destination as? WebViewController {
                vc.url = self.video?.slides_url?.absoluteString
            }
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
            case "EmbedAVPlayer":
                return self.video?.hlsURL != nil && !self.videoPlayerConfigured
            case "ShowSlides":
                return self.video?.slides_url?.absoluteString != nil
            default:
                return true
        }
    }

}
