//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import CoreData

protocol PersistenceManager: AnyObject {

    associatedtype Resource : NSManagedObject & Pullable
    associatedtype Session : URLSession

    static var shared: Self { get }

    var persistentContainerQueue: OperationQueue { get }
    var session: Session { get }
    var keyPath: ReferenceWritableKeyPath<Resource, NSData?> { get }
    var fetchRequest: NSFetchRequest<Resource> { get }

    var activeDownloads: [URLSessionTask: String] { get set }
    var progresses: [String: Double] { get set }
    var didRestorePersistenceManager: Bool { get set }

    func restoreDownloads()
    func startDownload(with url: URL, for resource: Resource)
    func downloadState(for resource: Resource) -> DownloadState
    func downloadProgress(for resource: Resource) -> Double?
    func deleteDownload(for resource: Resource)
    func cancelDownload(for resource: Resource)
    func localFileLocation(for resource: Resource) -> URL?

    func downloadTask(with url: URL, for resource: Resource, on session: Session) -> URLSessionTask?

    func resourceModificationAfterStartingDownload(for resource: Resource)
    func resourceModificationAfterDeletingDownload(for resource: Resource)

    func didCompleteDownloadTask(_ task: URLSessionTask, with error: Error?)
    func didFinishDownloadTask(_ task: URLSessionTask, to location: URL)

    func didFailToDownloadResource(_ resource: Resource, with error: NSError)

}

extension PersistenceManager {

    func startListeningToDownloadProgressChanges() {
        NotificationCenter.default.addObserver(forName: NotificationKeys.DownloadStateDidChange, object: nil, queue: nil) { notification in
            guard let resourceType = notification.userInfo?[DownloadNotificationKey.type] as? String,
                let resourceId = notification.userInfo?[DownloadNotificationKey.id] as? String,
                let progress = notification.userInfo?[DownloadNotificationKey.downloadProgress] as? Double,
                resourceType == Resource.type else { return }

            self.progresses[resourceId] = progress
        }
    }

    func createPersistenceContainerQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }

    func restoreDownloads() {
        guard !self.didRestorePersistenceManager else { return }
        self.didRestorePersistenceManager = true

        self.session.getAllTasks { tasks in
            for task in tasks{
                guard let resourceId = task.taskDescription else { break }
                self.activeDownloads[task] = resourceId
            }
        }
    }

    func localFileLocation(for resource: Resource) -> URL? {
        guard let bookmarkData = resource[keyPath: self.keyPath] as Data? else {
            return nil
        }

        var bookmarkDataIsStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &bookmarkDataIsStale) ?? nil else {
            return nil
        }

        if bookmarkDataIsStale {
            return nil
        }

        return url
    }

    func startDownload(with url: URL, for resource: Resource) {
        guard let task = self.downloadTask(with: url, for: resource, on: self.session) else {
            return
        }

        task.taskDescription = resource.id
        self.activeDownloads[task] = resource.id

        task.resume()
//        XXX
//        TrackingHelper.createEvent(.videoDownloadStart, resourceType: .video, resourceId: video.id)

        self.persistentContainerQueue.addOperation {
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            context.performAndWait {
                self.resourceModificationAfterStartingDownload(for: resource)
                try? context.save()
            }

            var userInfo: [String: Any] = [:]
            userInfo[DownloadNotificationKey.type] = Resource.type
            userInfo[DownloadNotificationKey.id] = resource.id
            userInfo[DownloadNotificationKey.downloadState] = DownloadState.downloading.rawValue

            NotificationCenter.default.post(name: NotificationKeys.DownloadStateDidChange, object: nil, userInfo: userInfo)
        }
    }

    func downloadState(for resource: Resource) -> DownloadState {
        if let localFileLocation = self.localFileLocation(for: resource), FileManager.default.fileExists(atPath: localFileLocation.path) {
            return .downloaded
        }

        for (_, resourceId) in self.activeDownloads where resource.id == resourceId {
            return self.progresses[resourceId] != nil ? .downloading : .pending
        }

        return .notDownloaded
    }

    func downloadProgress(for resource: Resource) -> Double? {
        return self.progresses[resource.id]
    }

    func deleteDownload(for resource: Resource) {
        let objectId = resource.objectID
        self.persistentContainerQueue.addOperation {
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            context.performAndWait {
                guard let refreshedResource = context.existingTypedObject(with: objectId) as? Resource else { return }
                self.deleteDownload(for: refreshedResource, in: context)
            }
        }
    }

    func deleteDownload(for resource: Resource, in context: NSManagedObjectContext) {
        guard let localFileLocation = self.localFileLocation(for: resource) else { return }

        do {
            try FileManager.default.removeItem(at: localFileLocation)
            resource[keyPath: self.keyPath] = nil
            self.resourceModificationAfterDeletingDownload(for: resource)
            try context.save()
        } catch {
            CrashlyticsHelper.shared.setObjectValue(resource.id, forKey: "video_id")
            CrashlyticsHelper.shared.recordError(error)
            log.error("An error occured deleting the file: \(error)")
        }

        var userInfo: [String: Any] = [:]
        userInfo[DownloadNotificationKey.type] = Resource.type
        userInfo[DownloadNotificationKey.id] = resource.id
        userInfo[DownloadNotificationKey.downloadState] = DownloadState.notDownloaded.rawValue

        NotificationCenter.default.post(name: NotificationKeys.DownloadStateDidChange, object: nil, userInfo: userInfo)
    }

    func cancelDownload(for resource: Resource) {
        var task: URLSessionTask?

        for (downloadtask, resourceId) in self.activeDownloads where resource.id == resourceId {
//            XXX
//            TrackingHelper.createEvent(.videoDownloadCanceled, resourceType: .video, resourceId: video.id)
            task = downloadtask
            break
        }

        task?.cancel()
    }

    func resourceModificationAfterStartingDownload(for resource: Resource) {}
    func resourceModificationAfterDeletingDownload(for resource: Resource) {}

    func didCompleteDownloadTask(_ task: URLSessionTask, with error: Error?) {
        guard let resourceId = self.activeDownloads.removeValue(forKey: task) else { return }

        self.progresses.removeValue(forKey: resourceId)

        var userInfo: [String: Any] = [:]
        userInfo[DownloadNotificationKey.type] = Resource.type
        userInfo[DownloadNotificationKey.id] = resourceId

        self.persistentContainerQueue.addOperation {
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            context.performAndWait {
                if let error = error as NSError? {
                    let fetchRequest = self.fetchRequest
                    fetchRequest.predicate = NSPredicate(format: "id == %@", resourceId)
                    fetchRequest.fetchLimit = 1

                    switch context.fetchSingle(fetchRequest) {
                    case let .success(resource):
                        if let localFileLocation = self.localFileLocation(for: resource) {
                            do {
                                try FileManager.default.removeItem(at: localFileLocation)
                                resource[keyPath: self.keyPath] = nil
                                self.resourceModificationAfterDeletingDownload(for: resource)
                                try context.save()
                            } catch {
//                                XXX
//                                CrashlyticsHelper.shared.setObjectValue(resourseId, forKey: "video_id")
                                CrashlyticsHelper.shared.recordError(error)
                                log.error("An error occured deleting the file: \(error)")
                            }
                        }

                        self.didFailToDownloadResource(resource, with: error)

                        userInfo[DownloadNotificationKey.downloadState] = DownloadState.notDownloaded.rawValue
                    case .failure(let error):
//                        XXX
//                        CrashlyticsHelper.shared.setObjectValue(resourceId, forKey: "video_id")
                        CrashlyticsHelper.shared.recordError(error)
                        log.error("Failed to complete download for video \(resourceId) : \(error)")
                    }
                } else {
                    userInfo[DownloadNotificationKey.downloadState] = DownloadState.downloaded.rawValue
//                    XXX
//                    let context = ["video_download_pref": String(describing: UserDefaults.standard.videoQualityForDownload.rawValue)]
//                    TrackingHelper.createEvent(.videoDownloadFinished, resourceType: .video, resourceId: resourceId, context: context)
                }

                NotificationCenter.default.post(name: NotificationKeys.DownloadStateDidChange, object: nil, userInfo: userInfo)
            }
        }
    }

    func didFinishDownloadTask(_ task: URLSessionTask, to location: URL) {
        guard let resourceId = self.activeDownloads[task] else { return }

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        context.performAndWait {
            let request = self.fetchRequest
            request.predicate = NSPredicate(format: "id == %@", resourceId)
            request.fetchLimit = 1

            switch context.fetchSingle(fetchRequest) {
            case let .success(resource):
                do {
                    let bookmark = try location.bookmarkData()
                    resource[keyPath: self.keyPath] = NSData(data: bookmark)
                    try context.save()
                } catch {
                    // Failed to create bookmark for location
                    self.deleteDownload(for: resource, in: context)
                }
            case let .failure(error):
                // XXX
                // CrashlyticsHelper.shared.setObjectValue(videoId, forKey: "video_id")
                CrashlyticsHelper.shared.recordError(error)
                // log.error("Failed to finish download for video \(videoId) : \(error)")
            }
        }
    }

}
