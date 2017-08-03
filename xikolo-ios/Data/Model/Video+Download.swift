//
//  Video+Download.swift
//  xikolo-ios
//
//  Created by Max Bothe on 26/07/17.
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation

extension Video {

    enum DownloadState: String {

        // The asset is not downloaded at all.
        case notDownloaded

        // The asset is waiting to be downloaded.
        case pending

        // The asset has a download in progress.
        case downloading

        // The asset is downloaded and saved on disk.
        case downloaded
    }

}

extension Video {

    struct Keys {

        static let id = "VideoIdKey"

        static let downloadState = "VideoDownloadStateKey"

        static let precentDownload = "VideoPrecentDownloadKey"

    }

}
