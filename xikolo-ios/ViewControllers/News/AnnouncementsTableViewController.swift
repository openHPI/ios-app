//
//  AnnouncementTableViewController.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 04.07.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import CoreData
import UIKit
import DZNEmptyDataSet

class AnnouncementsTableViewController : UITableViewController {

    var resultsController: NSFetchedResultsController<Announcement>!
    var resultsControllerDelegateImplementation: TableViewResultsControllerDelegateImplementation<Announcement>!

    deinit {
        self.tableView?.emptyDataSetSource = nil
        self.tableView?.emptyDataSetDelegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .automatic
        }

        // setup pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        // setup table view data
        let request = AnnouncementHelper.FetchRequest.allAnnouncements
        resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: nil)

        resultsControllerDelegateImplementation = TableViewResultsControllerDelegateImplementation(tableView, resultsController: [resultsController], cellReuseIdentifier: "AnnouncementCell")
        let configuration = TableViewResultsControllerConfigurationWrapper(AnnouncementsTableViewConfiguration())
        resultsControllerDelegateImplementation.configuration = configuration
        resultsController.delegate = resultsControllerDelegateImplementation
        tableView.dataSource = resultsControllerDelegateImplementation

        self.refresh()

        do {
            try resultsController.performFetch()
        } catch {
            // TODO: Error handling.
        }
        setupEmptyState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TrackingHelper.createEvent(.visitedAnnouncementList)
    }

    func setupEmptyState() {
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadEmptyDataSet()
    }

    @objc func refresh() {
        let deadline = UIRefreshControl.minimumSpinningTime.fromNow
        AnnouncementHelper.syncAllAnnouncements().onComplete { _ in
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newsVC = segue.destination.require(toHaveType: AnnouncementViewController.self)
        let announcement = (sender as? Announcement).require(hint: "Sender must be Announcement")
        newsVC.announcement = announcement
    }

}

extension AnnouncementsTableViewController { // TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let announcement = resultsController.object(at: indexPath)
        performSegue(withIdentifier: "ShowAnnouncement", sender: announcement)
    }

}

struct AnnouncementsTableViewConfiguration : TableViewResultsControllerConfiguration {

    func configureTableCell(_ cell: UITableViewCell, for controller: NSFetchedResultsController<Announcement>, indexPath: IndexPath) {
        let cell = cell.require(toHaveType: AnnouncementCell.self, hint: "AnnouncementsTabelViewController requires cells of type AnnouncementCell")
        let announcement = controller.object(at: indexPath)
        cell.configure(announcement)
    }

}

extension AnnouncementsTableViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let title = NSLocalizedString("empty-view.announcements.title", comment: "title for empty announcement list")
        return NSAttributedString(string: title)
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let description = NSLocalizedString("empty-view.announcements.description", comment: "description for empty announcement list")
        return NSAttributedString(string: description)
    }

}
