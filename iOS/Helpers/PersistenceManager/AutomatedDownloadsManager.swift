//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BackgroundTasks
import BrightFutures
import Common
import UserNotifications

@available(iOS 13, *)
enum AutomatedDownloadsManager {

    static let taskIdentifier = "de.xikolo.ios.background.download"

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            self.performNextBackgroundProcessingTasks(task: task)
        }
    }

    // - schedule next background task (find next sections/course -> start change date for existing bgtask or cancel | setup new bgtask)
    static func scheduleNextBackgroundProcessingTask() {
        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            // Find next date for background processing
            let fetchRequest = CourseHelper.FetchRequest.coursesWithAutomatedDownloads
            let courses = try? context.fetch(fetchRequest)
            let nextDates = courses?.compactMap { course -> Date? in
                let dates = course.sections.compactMap(\.startsAt) + [course.startsAt, course.endsAt].compactMap { $0 }
                let filteredDates = dates.filter { $0 > Date() }
                return filteredDates.min()
            }

            guard let dateForNextBackgroundProcessing = nextDates?.min() else {
                return
            }

            // Cancel current task request
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)

            // Setup new task request
            let automatedDownloadTaskRequest = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
            automatedDownloadTaskRequest.earliestBeginDate = dateForNextBackgroundProcessing
            automatedDownloadTaskRequest.requiresNetworkConnectivity = true

            do {
              try BGTaskScheduler.shared.submit(automatedDownloadTaskRequest)
            } catch {
              print("Unable to submit task: \(error.localizedDescription)")
            }
        }
    }

    static func performNextBackgroundProcessingTasks(task: BGTask) {
        self.postLocalPushNotificationIfApplicable()
        let downloadFuture = self.downloadNewContent()

        // TODO: delete old content

        self.scheduleNextBackgroundProcessingTask()

        downloadFuture.onComplete { result in
            task.setTaskCompleted(success: result.value != nil)
        }
    }

    // Download content (find courses -> find sections -> start downloads)
    private static func postLocalPushNotificationIfApplicable() {
        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            let fetchRequest = CourseHelper.FetchRequest.coursesWithAutomatedDownloads
            let courses = try? context.fetch(fetchRequest)
            let numberOfCoursesWithNotification = courses?.filter { $0.automatedDownloadSettings?.downloadOption == .notification }.count ?? 0
            // TODO: not the correct set of courses, check for new content (course end not applicable)

            if numberOfCoursesWithNotification > 0 {
                let center = UNUserNotificationCenter.current()

                let downloadAction = UNNotificationAction(identifier: "UYLDownload", title: "Download now", options: [])
                let category = UNNotificationCategory(identifier: "UYLDownloadCategory", actions: [downloadAction], intentIdentifiers: [])
                center.setNotificationCategories([category])

                center.getNotificationSettings { settings in
                    guard settings.authorizationStatus == .authorized else { return }
                    let content = UNMutableNotificationContent()
                    content.title = "Download new course material"
                    content.body = "New content was released in \(numberOfCoursesWithNotification) courses"
                    content.categoryIdentifier = "UYLDownloadCategory"
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

                    let identifier = "UYLLocalNotification"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            // Something went wrong
                        }
                    })
                }
            }
        }
    }

    // Delete older content (find courses -> find old sections -> delete content)
    @discardableResult
    static func downloadNewContent() -> Future<Void, XikoloError> {
        let promise = Promise<Void, XikoloError>()

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            let fetchRequest = CourseHelper.FetchRequest.coursesWithAutomatedDownloads
            let courses = try? context.fetch(fetchRequest)

            var downloadFutures: [Future<Void, XikoloError>] = []

            courses?.forEach { course in
                if course.automatedDownloadSettings?.downloadOption == .backgroundDownload {
                    if let materialsToDownload = course.automatedDownloadSettings?.materialTypes {
                        // Find all course sections with the latest start date (which can be nil)
                        let orderedSections = course.sections.filter {
                            ($0.startsAt ?? Date.distantPast) < Date()
                        }.sorted {
                            ($0.startsAt ?? Date.distantPast) < ($1.startsAt ?? Date.distantPast)
                        }

                        let lastSectionStart = orderedSections.last?.startsAt
                        let sectionsToDownload = orderedSections.filter { $0.startsAt == lastSectionStart }

                        // TODO: section have no items
                        sectionsToDownload.forEach { backgroundSection in
                            let section: CourseSection = CoreDataHelper.viewContext.typedObject(with: backgroundSection.objectID)
                            if materialsToDownload.contains(.videos) {
                                let downloadStreamFuture = StreamPersistenceManager.shared.startDownloads(for: section)
                                downloadFutures.append(downloadStreamFuture)
                            }

                            if materialsToDownload.contains(.slides) {
                                let downloadSlidesFuture = SlidesPersistenceManager.shared.startDownloads(for: section)
                                downloadFutures.append(downloadSlidesFuture)
                            }
                        }
                    }
                }
            }

            let combinedDownloadFuture = downloadFutures.sequence().asVoid()
            promise.completeWith(combinedDownloadFuture)
        }

        return promise.future
    }

}
