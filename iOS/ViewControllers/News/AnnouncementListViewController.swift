//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import CoreData
import DZNEmptyDataSet
import UIKit

class AnnouncementListViewController: UITableViewController {

    private var dataSource: CoreDataTableViewDataSource<AnnouncementListViewController>!

    deinit {
        self.tableView?.emptyDataSetSource = nil
        self.tableView?.emptyDataSetDelegate = nil
    }

    var course: Course?

    @IBOutlet private var actionButton: UIBarButtonItem!

    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(coreDataChange(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataHelper.viewContext)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addRefreshControl()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateUIAfterLoginStateChanged),
                                               name: UserProfileHelper.loginStateDidChangeNotification,
                                               object: nil)

        self.updateUIAfterLoginStateChanged()

        // set to follow readable width when course is present
        self.tableView.cellLayoutMarginsFollowReadableWidth = self.course != nil

        // setup table view data
        let request: NSFetchRequest<Announcement>

        if let course = course {
            request = AnnouncementHelper.FetchRequest.announcements(forCourse: course)
        } else {
            request = AnnouncementHelper.FetchRequest.allAnnouncements
        }

        let reuseIdentifier = R.reuseIdentifier.announcementCell.identifier
        let resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: nil)
        self.dataSource = CoreDataTableViewDataSource(self.tableView,
                                                      fetchedResultsController: resultsController,
                                                      cellReuseIdentifier: reuseIdentifier,
                                                      delegate: self)

        self.refresh()
        self.setupEmptyState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TrackingHelper.shared.createEvent(.visitedAnnouncementList)
    }

    func setupEmptyState() {
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadEmptyDataSet()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let announcement = (sender as? Announcement).require(hint: "Sender must be Announcement")
        if let typedInfo = R.segue.announcementListViewController.showAnnouncement(segue: segue) {
            typedInfo.destination.configure(for: announcement, showCourseTitle: self.course == nil)
        }
    }

    @objc private func updateUIAfterLoginStateChanged() {
        self.navigationItem.rightBarButtonItem = UserProfileHelper.shared.isLoggedIn ? self.actionButton : nil
    }

    @IBAction private func tappedActionButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender

        let markAllAsReadActionTitle = NSLocalizedString("announcement.alert.mark all as read", comment: "alert action title to mark all announcements as read")
        let markAllAsReadAction = UIAlertAction(title: markAllAsReadActionTitle, style: .default) { _ in
            AnnouncementHelper.shared.markAllAsVisited()
        }

        alert.addAction(markAllAsReadAction)
        alert.addCancelAction()

        self.present(alert, animated: true)
    }

    @objc private func coreDataChange(notification: Notification) {
        guard notification.includesChanges(for: Enrollment.self, keys: [NSUpdatedObjectsKey, NSRefreshedObjectsKey]) else { return }
        self.tableView.reloadData()
    }

}

extension AnnouncementListViewController { // TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let announcement = self.dataSource.object(at: indexPath)
        self.performSegue(withIdentifier: R.segue.announcementListViewController.showAnnouncement, sender: announcement)
    }

}

extension AnnouncementListViewController: CoreDataTableViewDataSourceDelegate {

    func configure(_ cell: AnnouncementCell, for object: Announcement) {
        cell.configure(for: object, showCourseTitle: self.course == nil)
    }

}

extension AnnouncementListViewController: RefreshableViewController {

    func refreshingAction() -> Future<Void, XikoloError> {
        if let course = self.course {
            return AnnouncementHelper.shared.syncAnnouncements(for: course).asVoid()
        } else {
            return AnnouncementHelper.shared.syncAllAnnouncements().asVoid()
        }
    }

}

extension AnnouncementListViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let title = NSLocalizedString("empty-view.announcements.title", comment: "title for empty announcement list")
        return NSAttributedString(string: title)
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let description = NSLocalizedString("empty-view.announcements.description", comment: "description for empty announcement list")
        return NSAttributedString(string: description)
    }

    func emptyDataSet(_ scrollView: UIScrollView!, didTap view: UIView!) {
        self.refresh()
    }

}

extension AnnouncementListViewController: CourseAreaViewController {

    func configure(for course: Course, delegate: CourseAreaViewControllerDelegate) {
        self.course = course
    }

}
