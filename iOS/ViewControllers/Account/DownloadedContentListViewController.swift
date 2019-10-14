//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import CoreData
import Foundation
import UIKit

class DownloadedContentListViewController: UITableViewController {

    @IBOutlet private var tableViewHeader: UIView!
    @IBOutlet private weak var totalFileSizeLabel: UILabel!
    @IBOutlet private weak var selectAllBarButton: UIBarButtonItem!
    @IBOutlet private weak var deleteBarButton: UIBarButtonItem!

    struct CourseDownload {
        var id: String
        var title: String
        var data: [DownloadedContentHelper.ContentType: UInt64] = [:]

        init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    private var courseDownloads: [CourseDownload] = [] {
        didSet {
            let isEditing = self.isEditing && !self.courseDownloads.isEmpty
            self.navigationController?.setToolbarHidden(!isEditing, animated: trueUnlessReduceMotionEnabled)
            self.navigationItem.setHidesBackButton(isEditing, animated: trueUnlessReduceMotionEnabled)

            self.updateToolBarButtons()
            self.updateTotalFileSizeLabel()

            self.navigationItem.rightBarButtonItem = self.courseDownloads.isEmpty ? nil : self.editButtonItem
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupEmptyState()
        self.refresh()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(coreDataChange(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataHelper.viewContext)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.resizeTableHeaderView()
    }

    private func setupEmptyState() {
        self.tableView.emptyStateDataSource = self
        self.tableView.emptyStateDelegate = self
        self.tableView.tableFooterView = UIView()
    }

    @discardableResult
    private func refresh() -> Future<[[DownloadedContentHelper.DownloadItem]], XikoloError> {
        return DownloadedContentHelper.downloadedItemForAllCourses().onSuccess { itemsArray in
            let downloadItems = itemsArray.flatMap { $0 }
            var downloadedCourseList: [String: CourseDownload] = [:]

            for downloadItem in downloadItems {
                let courseId = downloadItem.courseID
                var courseDownload = downloadedCourseList[courseId, default: CourseDownload(id: courseId, title: downloadItem.courseTitle ?? "")]
                courseDownload.data[downloadItem.contentType, default: 0] += downloadItem.fileSize ?? 0
                downloadedCourseList[downloadItem.courseID] = courseDownload
            }

            self.courseDownloads = downloadedCourseList.values.sorted { $0.title < $1.title }
        }.onFailure { error in
            log.error(error.localizedDescription)
        }
    }

    private func updateTotalFileSizeLabel() {
        let fileSize = self.courseDownloads.reduce(0) { result, courseDownload -> UInt64 in
            return result + self.aggregatedFileSize(for: courseDownload)
        }

        let format = NSLocalizedString("settings.downloads.total size: %@", comment: "total size label")
        let formattedFileSize = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        self.totalFileSizeLabel.text = String.localizedStringWithFormat(format, formattedFileSize)
        self.tableViewHeader.isHidden = self.courseDownloads.isEmpty
    }

    private func aggregatedFileSize(for courseDownload: CourseDownload) -> UInt64 {
        return courseDownload.data.reduce(0) { result, data -> UInt64 in
            return result + data.value
        }
    }

    @objc private func coreDataChange(notification: Notification) {
        let keys = [NSDeletedObjectsKey, NSRefreshedObjectsKey, NSUpdatedObjectsKey]
        let containsVideoDeletion = notification.includesChanges(for: Video.self, keys: keys)
        let containsDocumentDeletion = notification.includesChanges(for: DocumentLocalization.self, keys: keys)
        if containsVideoDeletion || containsDocumentDeletion {
            self.refresh()
        }
    }

}

extension DownloadedContentListViewController { // Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.courseDownloads.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courseDownloads[section].data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.downloadTypeCell, for: indexPath).require()
        let data = Array(self.courseDownloads[indexPath.section].data)[indexPath.row]
        cell.textLabel?.text = data.key.title
        cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(data.value), countStyle: .file)
        cell.selectedBackgroundView = self.isEditing ? UIView(backgroundColor: ColorCompatibility.secondarySystemGroupedBackground) : nil
        return cell
    }

    private func downloadType(for indexPath: IndexPath) -> DownloadedContentHelper.ContentType {
        return self.courseDownloads[indexPath.section].data.map { $0.key }[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.courseDownloads[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !self.isEditing else {
            self.updateToolBarButtons()
            tableView.cellForRow(at: indexPath)?.selectedBackgroundView = UIView(backgroundColor: ColorCompatibility.secondarySystemGroupedBackground)
            return
        }

        let courseId = self.courseDownloads[indexPath.section].id

        switch self.downloadType(for: indexPath) {
        case .video:
            let viewController = DownloadedContentTypeListViewController(forCourseId: courseId, configuration: DownloadedStreamsListConfiguration.self)
            self.navigationController?.pushViewController(viewController, animated: trueUnlessReduceMotionEnabled)
        case .slides:
            let viewController = DownloadedContentTypeListViewController(forCourseId: courseId, configuration: DownloadedSlidesListConfiguration.self)
            self.navigationController?.pushViewController(viewController, animated: trueUnlessReduceMotionEnabled)
        case .document:
            let viewController = DownloadedContentTypeListViewController(forCourseId: courseId, configuration: DownloadedDocumentsListConfiguration.self)
            self.navigationController?.pushViewController(viewController, animated: trueUnlessReduceMotionEnabled)
        }

    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard self.isEditing else { return }
        self.updateToolBarButtons()
        tableView.cellForRow(at: indexPath)?.selectedBackgroundView = nil
    }

}

extension DownloadedContentListViewController { // editing

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.updateToolBarButtons()
        self.navigationController?.setToolbarHidden(!editing, animated: animated)
        self.navigationItem.setHidesBackButton(editing, animated: animated)

        if !editing {
            for cell in self.tableView.visibleCells {
                cell.selectedBackgroundView = nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        super.tableView(tableView, willBeginEditingRowAt: indexPath)
        self.navigationController?.setToolbarHidden(true, animated: trueUnlessReduceMotionEnabled)
        self.navigationItem.setHidesBackButton(false, animated: trueUnlessReduceMotionEnabled)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let alert = UIAlertController { _ in
            let downloadItem = self.courseDownloads[indexPath.section]
            let course = self.fetchCourse(withID: downloadItem.id).require(hint: "Course has to exist")
            self.downloadType(for: indexPath).persistenceManager.deleteDownloads(for: course)
        }

        self.present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.isEditing = true
    }

    private func fetchCourse(withID id: String) -> Course? {
        let request = CourseHelper.FetchRequest.course(withSlugOrId: id)
        return CoreDataHelper.viewContext.fetchSingle(request).value
    }

    private func updateToolBarButtons() {
        var title: String {
            let allRowsSelected = self.allIndexPaths.count == self.tableView.indexPathsForSelectedRows?.count
            if allRowsSelected {
                return NSLocalizedString("global.list.selection.deselect all", comment: "Title for button for deselecting all items in a list")
            } else {
                return NSLocalizedString("global.list.selection.select all", comment: "Title for button for selecting all items in a list")
            }
        }

        self.selectAllBarButton.title = title
        self.deleteBarButton.isEnabled = !(self.tableView.indexPathsForSelectedRows?.isEmpty ?? true)
    }

    private var allIndexPaths: [IndexPath] {
        return (0..<self.tableView.numberOfSections).flatMap { section in
            return (0..<self.tableView.numberOfRows(inSection: section)).map { row in
                return IndexPath(row: row, section: section)
            }
        }
    }

    @IBAction private func selectMultiple() {
        let allIndexPaths = self.allIndexPaths
        let allRowsSelected = allIndexPaths.count == self.tableView.indexPathsForSelectedRows?.count
        self.tableView.beginUpdates()

        if allRowsSelected {
            allIndexPaths.forEach { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: trueUnlessReduceMotionEnabled)
            }
        } else {
            allIndexPaths.forEach { indexPath in
                self.tableView.selectRow(at: indexPath, animated: trueUnlessReduceMotionEnabled, scrollPosition: .none)
            }
        }

        self.tableView.endUpdates()
        self.updateToolBarButtons()
    }

    @IBAction private func deleteSelectedIndexPaths() {
        guard let indexPaths = self.tableView.indexPathsForSelectedRows else {
            return
        }

        let alert = UIAlertController { [weak self] _ in
            guard let self = self else { return }

            for indexPath in indexPaths {
                let downloadItem = self.courseDownloads[indexPath.section]
                let course = self.fetchCourse(withID: downloadItem.id).require(hint: "Course has to exist")
                self.downloadType(for: indexPath).persistenceManager.deleteDownloads(for: course)
            }

            self.setEditing(false, animated: trueUnlessReduceMotionEnabled)
        }

        self.present(alert, animated: trueUnlessReduceMotionEnabled)
    }

}

extension DownloadedContentListViewController: EmptyStateDataSource, EmptyStateDelegate {

    var titleText: String? {
        return NSLocalizedString("empty-view.account.download.no-downloads.title", comment: "title for empty download list")
    }

    var detailText: String? {
        return NSLocalizedString("empty-view.account.download.no-downloads.description", comment: "description for empty download list")
    }

}
