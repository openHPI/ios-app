//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import AVFoundation
import CoreData
import Foundation
import UIKit


final class StreamPersistenceManager: NSObject, PersistenceManager {

//    typealias Resource = Video
    typealias Session = AVAssetDownloadURLSession

    let keyPath: ReferenceWritableKeyPath<Video, NSData?> = \Video.localFileBookmark

    var activeDownloads: [URLSessionTask : String] = [:]
    var progresses: [String : Double] = [:]
    var didRestorePersistenceManager: Bool = false

    lazy var persistentContainerQueue = self.createPersistenceContainerQueue()
    lazy var session: AVAssetDownloadURLSession = {
        let sessionIdentifier = "asset-download"
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        return AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                         assetDownloadDelegate: self,
                                         delegateQueue: OperationQueue.main)
    }()

    var fetchRequest: NSFetchRequest<Video> {
        return Video.fetchRequest()
    }

    static var shared = StreamPersistenceManager()

    override init() {
        super.init()
        self.startListeningToDownloadProgressChanges()
    }

    func downloadTask(with url: URL, for resource: Video, on session: AVAssetDownloadURLSession) -> URLSessionTask? {
        let assetTitleCourse = resource.item?.section?.course?.slug ?? "Unknown course"
        let assetTitleItem = resource.item?.title ?? "Untitled video"
        let assetTitle = "\(assetTitleItem) (\(assetTitleCourse))".safeAsciiString() ?? "Untitled video"
        let asset = AVURLAsset(url: url)
        let options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: UserDefaults.standard.videoQualityForDownload.rawValue]

        return session.makeAssetDownloadTask(asset: asset, assetTitle: assetTitle, assetArtworkData: resource.posterImageData, options: options)
    }

    func startDownload(for video: Video) {
        guard let url = video.singleStream?.hlsURL else { return }
        self.startDownload(with: url, for: video)
    }

    func resourceModificationAfterStartingDownload(for resource: Video) {
        resource.downloadDate = Date()
    }

    func resourceModificationAfterDeletingDownload(for resourse: Video) {
        resourse.downloadDate = nil
    }

    func didStartDownload(for resourceId: String) {
        TrackingHelper.createEvent(.videoDownloadStart, resourceType: .video, resourceId: resourceId)
    }

    func didCancelDownload(for resourceId: String) {
        TrackingHelper.createEvent(.videoDownloadCanceled, resourceType: .video, resourceId: resourceId)
    }

    func didFinishDownload(for resourceId: String) {
        let context = ["video_download_pref": String(describing: UserDefaults.standard.videoQualityForDownload.rawValue)]
        TrackingHelper.createEvent(.videoDownloadFinished, resourceType: .video, resourceId: resourceId, context: context)
    }

    func didFailToDownloadResource(_ resource: Video, with error: NSError) {
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            log.debug("Canceled download of video (video id: \(resource.id))")
            return
        }

        CrashlyticsHelper.shared.setObjectValue((Resource.type, resource.id), forKey: "resource")
        CrashlyticsHelper.shared.recordError(error)
        log.error("Unknown asset download error (video id: \(resource.id) | domain: \(error.domain) | code: \(error.code)")

        // show error
        DispatchQueue.main.async {
            let alertTitle = NSLocalizedString("course-item.video-download-action.download-error.title",
                                               comment: "title to download error alert")
            let alertMessage = "Domain: \(error.domain)\nCode: \(error.code)"
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            let actionTitle = NSLocalizedString("global.alert.ok", comment: "title to confirm alert")
            alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
                alert.dismiss(animated: true)
            })

            AppDelegate.instance().tabBarController?.present(alert, animated: true)
        }
    }

}

extension StreamPersistenceManager {

    func startDownloads(for section: CourseSection) {
        self.persistentContainerQueue.addOperation {
            section.items.compactMap { item in
                return item.content as? Video
            }.filter { video in
                return StreamPersistenceManager.shared.downloadState(for: video) == .notDownloaded
            }.forEach { video in
                self.startDownload(for: video)
            }
        }
    }

    func deleteDownloads(for section: CourseSection) {
        self.persistentContainerQueue.addOperation {
            section.items.compactMap { item in
                return item.content as? Video
            }.forEach { video in
                self.deleteDownload(for: video)
            }
        }
    }

    func cancelDownloads(for section: CourseSection) {
        self.persistentContainerQueue.addOperation {
            section.items.compactMap { item in
                return item.content as? Video
            }.filter { video in
                return [.pending, .downloading].contains(StreamPersistenceManager.shared.downloadState(for: video))
            }.forEach { video in
                self.cancelDownload(for: video)
            }
        }
    }
}


//class VideoPersistenceManager: NSObject {
//
//    static let shared = VideoPersistenceManager()
//
//    private var assetDownloadURLSession: AVAssetDownloadURLSession!
//    private var activeDownloadsMap: [AVAssetDownloadTask: String] = [:]
//    private var progressMap: [String: Double] = [:]
//    private let persistentContainerQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        return queue
//    }()
//
//    private var didRestorePersistenceManager = false
//
//    override private init() {
//        super.init()
//        let sessionIdentifier = "\(UIApplication.bundleIdentifier).asset-download"
//        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
//        self.assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
//                                                                 assetDownloadDelegate: self,
//                                                                 delegateQueue: OperationQueue.main)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handleAssetDownloadProgressNotification(_:)),
//                                               name: NotificationKeys.VideoDownloadStateChangedKey,
//                                               object: nil)
//    }
//
//    func restorePersistenceManager() {
//        guard !self.didRestorePersistenceManager else { return }
//
//        self.didRestorePersistenceManager = true
//
//        self.assetDownloadURLSession.getAllTasks { tasks in
//            for task in tasks {
//                guard let assetDownloadTask = task as? AVAssetDownloadTask, let videoId = task.taskDescription else { break }
//                self.activeDownloadsMap[assetDownloadTask] = videoId
//            }
//        }
//    }
//
//    func downloadStream(for video: Video) {
//        guard let url = video.singleStream?.hlsURL else { return }
//
//        let assetTitleCourse = video.item?.section?.course?.slug ?? "Unknown course"
//        let assetTitleItem = video.item?.title ?? "Untitled video"
//        let assetTitle = "\(assetTitleItem) (\(assetTitleCourse))".safeAsciiString() ?? "Untitled video"
//        let options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: UserDefaults.standard.videoQualityForDownload.rawValue]
//
//        guard let task = self.assetDownloadURLSession.makeAssetDownloadTask(asset: AVURLAsset(url: url),
//                                                                            assetTitle: assetTitle,
//                                                                            assetArtworkData: video.posterImageData,
//                                                                            options: options) else { return }
//        TrackingHelper.createEvent(.videoDownloadStart, resourceType: .video, resourceId: video.id)
//        task.taskDescription = video.id
//
//        self.activeDownloadsMap[task] = video.id
//
//        task.resume()
//
//        self.persistentContainerQueue.addOperation {
//            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
//            context.performAndWait {
//                video.downloadDate = Date()
//                do {
//                    try context.save()
//                } catch {
//                    CrashlyticsHelper.shared.setObjectValue(video.id, forKey: "video_id")
//                    CrashlyticsHelper.shared.recordError(error)
//                    log.error("Failed to save video (start)")
//                }
//            }
//
//            var userInfo: [String: Any] = [:]
//            userInfo[Video.Keys.id] = video.id
//            userInfo[Video.Keys.downloadState] = Video.DownloadState.downloading.rawValue
//
//            NotificationCenter.default.post(name: NotificationKeys.VideoDownloadStateChangedKey, object: nil, userInfo: userInfo)
//        }
//
//    }
//
//    func localAsset(for video: Video) -> AVURLAsset? {
//        guard let localFileLocation = video.localFileBookmark as Data? else { return nil }
//
//        var asset: AVURLAsset?
//        var bookmarkDataIsStale = false
//        do {
//            guard let url = try URL(resolvingBookmarkData: localFileLocation, bookmarkDataIsStale: &bookmarkDataIsStale) else {
//                return nil
//            }
//
//            if bookmarkDataIsStale {
//                return nil
//            }
//
//            asset = AVURLAsset(url: url)
//
//            return asset
//        } catch {
//            return nil
//        }
//    }
//
//    func downloadState(for video: Video) -> Video.DownloadState {
//        if let localFileLocation = self.localAsset(for: video)?.url {
//            if FileManager.default.fileExists(atPath: localFileLocation.path) {
//                return .downloaded
//            }
//        }
//
//        for (_, downloadingVideoId) in self.activeDownloadsMap where video.id == downloadingVideoId {
//            return self.progressMap[video.id] != nil ? .downloading : .pending
//        }
//
//        return .notDownloaded
//    }
//
//    func progress(for video: Video) -> Double? {
//        return self.progressMap[video.id]
//    }
//
//    func deleteAsset(for video: Video) {
//        let objectId = video.objectID
//        self.persistentContainerQueue.addOperation {
//            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
//            context.performAndWait {
//                guard let video = context.existingTypedObject(with: objectId) as? Video else {
//                    return
//                }
//
//                self.deleteAsset(for: video, in: context)
//            }
//        }
//    }
//
//    private func deleteAsset(for video: Video, in context: NSManagedObjectContext) {
//        guard let localFileLocation = self.localAsset(for: video)?.url else { return }
//
//        do {
//            try FileManager.default.removeItem(at: localFileLocation)
//            video.downloadDate = nil
//            video.localFileBookmark = nil
//            try context.save()
//        } catch {
//            CrashlyticsHelper.shared.setObjectValue(video.id, forKey: "video_id")
//            CrashlyticsHelper.shared.recordError(error)
//            log.error("An error occured deleting the file: \(error)")
//        }
//
//        var userInfo: [String: Any] = [:]
//        userInfo[Video.Keys.id] = video.id
//        userInfo[Video.Keys.downloadState] = Video.DownloadState.notDownloaded.rawValue
//
//        NotificationCenter.default.post(name: NotificationKeys.VideoDownloadStateChangedKey, object: nil, userInfo: userInfo)
//    }
//
//    func cancelDownload(for video: Video) {
//        var task: AVAssetDownloadTask?
//
//        for (donwloadTask, downloadingVideoId) in activeDownloadsMap where video.id == downloadingVideoId {
//            TrackingHelper.createEvent(.videoDownloadCanceled, resourceType: .video, resourceId: video.id)
//            task = donwloadTask
//            break
//        }
//
//        task?.cancel()
//    }
//
//    @objc func handleAssetDownloadProgressNotification(_ notification: Notification) {
//        guard let videoId = notification.userInfo?[Video.Keys.id] as? String,
//            let progress = notification.userInfo?[Video.Keys.precentDownload] as? Double else { return }
//
//        self.progressMap[videoId] = progress
//    }
//
//    // MARK: course sections
//
//    func downloadVideos(for section: CourseSection) {
//        self.persistentContainerQueue.addOperation {
//            section.items.compactMap { item in
//                return item.content as? Video
//            }.filter { video in
//                return VideoPersistenceManager.shared.downloadState(for: video) == .notDownloaded
//            }.forEach { video in
//                self.downloadStream(for: video)
//            }
//        }
//    }
//
//    func deleteVideos(for section: CourseSection) {
//        self.persistentContainerQueue.addOperation {
//            section.items.compactMap { item in
//                return item.content as? Video
//            }.forEach { video in
//                self.deleteAsset(for: video)
//            }
//        }
//    }
//
//    func cancelVideoDownloads(for section: CourseSection) {
//        self.persistentContainerQueue.addOperation {
//            section.items.compactMap { item in
//                return item.content as? Video
//            }.filter { video in
//                return [.pending, .downloading].contains(VideoPersistenceManager.shared.downloadState(for: video))
//            }.forEach { video in
//                self.cancelDownload(for: video)
//            }
//        }
//    }
//
//}

extension StreamPersistenceManager: AVAssetDownloadDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.didCompleteDownloadTask(task, with: error)
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        self.didFinishDownloadTask(assetDownloadTask, to: location)
    }

    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange) {
        guard let videoId = self.activeDownloads[assetDownloadTask] else { return }

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }

        var userInfo: [String: Any] = [:]
        userInfo[DownloadNotificationKey.type] = Resource.type
        userInfo[DownloadNotificationKey.id] = videoId
        userInfo[DownloadNotificationKey.downloadProgress] = percentComplete

        NotificationCenter.default.post(name: NotificationKeys.DownloadProgressDidChange, object: nil, userInfo: userInfo)
    }

}