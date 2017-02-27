//
//  CourseContentTableViewController.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 18.05.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import CoreData
import UIKit
import DZNEmptyDataSet

class CourseContentTableViewController: UITableViewController {

    var course: Course!

    var resultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var resultsControllerDelegateImplementation: TableViewResultsControllerDelegateImplementation!

    deinit {
        self.tableView?.emptyDataSetSource = nil
        self.tableView?.emptyDataSetDelegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = course.title

        let request = CourseItemHelper.getItemRequest(course)
        resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: "section.title")

        resultsControllerDelegateImplementation = TableViewResultsControllerDelegateImplementation(tableView, resultsController: resultsController, cellReuseIdentifier: "CourseItemCell")
        resultsControllerDelegateImplementation.delegate = self
        resultsController.delegate = resultsControllerDelegateImplementation
        tableView.dataSource = resultsControllerDelegateImplementation

        do {
            try resultsController.performFetch()
        } catch {
            // TODO: Error handling.
        }
        NetworkIndicator.start()
        CourseSectionHelper.syncCourseSections(course).flatMap { sections in
            sections.map { section in
                CourseItemHelper.syncCourseItems(section)
            }.sequence().onComplete { _ in
                self.tableView.reloadEmptyDataSet()
            }
        }.onSuccess { _ in
            NetworkIndicator.end()
        }
        setupEmptyState()
    }

    func setupEmptyState() {
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadEmptyDataSet()
    }

    func showItem(_ item: CourseItem) {
        TrackingHelper.sendEvent("VISITED_ITEM", resource: item)
        //save read state to server
        item.visited = true
        SpineHelper.save(CourseItemSpine.init(courseItem: item))
        
        switch item.content {
            case is Video:
                performSegue(withIdentifier: "ShowVideo", sender: item)
            case is LTIExercise, is Quiz, is PeerAssessment:
                performSegue(withIdentifier: "ShowQuiz", sender: item)
            case is RichText:
                performSegue(withIdentifier: "ShowRichtext", sender: item)
            default:
                // TODO: show error: unsupported type
                break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let courseItem = sender as? CourseItem
        switch segue.identifier! {
        case "ShowVideo":
            let videoView = segue.destination as! VideoViewController
            videoView.courseItem = courseItem
            break
        case "ShowQuiz":
            let webView = segue.destination as! WebViewController
            if let courseID = courseItem!.section?.course?.id {
                let courseURL = Routes.COURSES_URL + courseID
                let quizpathURL = "/items/" + courseItem!.id
                let url = courseURL + quizpathURL
                webView.url = url
            }
            break
        case "ShowRichtext":
            let richtextView = segue.destination as! RichtextViewController
            richtextView.courseItem = courseItem
            break
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

}

extension CourseContentTableViewController { // TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = resultsController.object(at: indexPath) as! CourseItem
        showItem(item)
    }

}

extension CourseContentTableViewController : TableViewResultsControllerDelegateImplementationDelegate {

    func configureTableCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let cell = cell as! CourseItemCell

        let item = resultsController.object(at: indexPath) as! CourseItem
        cell.configure(item)
    }

}

extension CourseContentTableViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if NetworkIndicator.counter > 0 {
            return nil // blank screen for loading
        }
        let title = NSLocalizedString("Error loading course items", comment: "")
        let attributedString = NSAttributedString(string: title)
        return attributedString
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if NetworkIndicator.counter > 0 {
            return nil // blank screen for loading
        }
        let description = NSLocalizedString("Please check you internet connection", comment: "")
        let attributedString = NSAttributedString(string: description)
        return attributedString
    }
    
}
