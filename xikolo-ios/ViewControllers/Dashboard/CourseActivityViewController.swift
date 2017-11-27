//
//  LastCourseActivityViewController.swift
//  xikolo-ios
//
//  Created by Tobias Rohloff on 16.11.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import DZNEmptyDataSet


class CourseActivityViewController: UICollectionViewController {

    var resultsController: NSFetchedResultsController<Course>!
    var resultsControllerDelegateImplementation: CollectionViewResultsControllerDelegateImplementation<Course>!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CourseActivityViewController.updateAfterLoginStateChange),
                                               name: NotificationKeys.loginStateChangedKey,
                                               object: nil)
        self.updateFetchedResultController()
    }

    @objc func updateAfterLoginStateChange() {
        self.updateFetchedResultController()
    }

    private func updateFetchedResultController() {
        let request = UserProfileHelper.isLoggedIn() ? CourseHelper.FetchRequest.enrolledAccessibleCourses : CourseHelper.FetchRequest.interestingCoursesRequest
        resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: nil)

        resultsControllerDelegateImplementation = CollectionViewResultsControllerDelegateImplementation(self.collectionView!, resultsControllers: [resultsController], cellReuseIdentifier: "LastCourseCell")
        let configuration = CollectionViewResultsControllerConfigurationWrapper(CourseActivityViewConfiguration())
        resultsControllerDelegateImplementation.configuration = configuration
        resultsController.delegate = resultsControllerDelegateImplementation
        collectionView!.dataSource = resultsControllerDelegateImplementation

        do {
            try resultsController.performFetch()
        } catch {
            // TODO: Error handling.
        }

        self.refresh()
    }

    func refresh() {
        CourseHelper.syncAllCourses()
    }
}

extension CourseActivityViewController {

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let course = resultsController.object(at: indexPath)
        AppDelegate.instance().goToCourse(course)
    }

}

extension CourseActivityViewController : UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 240)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding: CGFloat = 10.0
        let cellSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section))
        let numberOfCellsInSection = CGFloat(self.resultsController?.sections?[section].numberOfObjects ?? 0)
        let viewWidth = self.collectionView?.frame.size.width ?? 0
        let horizontalPadding = max(0, (viewWidth - 2*padding - numberOfCellsInSection * cellSize.width) / 2)

        return UIEdgeInsets(top: 0, left: padding + horizontalPadding, bottom: 0, right: padding + horizontalPadding)
    }

}


struct CourseActivityViewConfiguration : CollectionViewResultsControllerConfiguration {

    func configureCollectionCell(_ cell: UICollectionViewCell, for controller: NSFetchedResultsController<Course>, indexPath: IndexPath) {
        let cell = cell as! CourseCell
        let course = controller.object(at: indexPath)
        cell.configure(course)
    }

}
