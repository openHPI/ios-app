//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import DZNEmptyDataSet
import Foundation
import UIKit

class CourseOverviewViewController: UICollectionViewController {

    var fetchRequest: NSFetchRequest<Course>!
    var resultsController: NSFetchedResultsController<Course>!
    var resultsControllerDelegateImplementation: CollectionViewResultsControllerDelegateImplementation<Course>!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.register(R.nib.courseCell(), forCellWithReuseIdentifier: R.reuseIdentifier.courseCell.identifier)

//        let request = CourseHelper.FetchRequest.enrolledCourses
        resultsController = CoreDataHelper.createResultsController(self.fetchRequest, sectionNameKeyPath: nil)

        let reuseIdentifier = R.reuseIdentifier.courseCell.identifier
        resultsControllerDelegateImplementation = CollectionViewResultsControllerDelegateImplementation(self.collectionView,
                                                                                                        resultsControllers: [resultsController],
                                                                                                        cellReuseIdentifier: reuseIdentifier)
        let configuration = CourseOverviewViewConfiguration().wrapped
        resultsControllerDelegateImplementation.configuration = configuration
        resultsController.delegate = resultsControllerDelegateImplementation
        self.collectionView?.dataSource = resultsControllerDelegateImplementation

        do {
            try resultsController.performFetch()
        } catch {
            CrashlyticsHelper.shared.recordError(error)
            log.error(error)
        }
    }

}

extension CourseOverviewViewController {

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let course = resultsController.object(at: indexPath)
        AppNavigator.show(course: course)
    }

}

extension CourseOverviewViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = 12 + 150 + 8 + 20.5 + 4 + 18 // (image height + padding + text + padding + text)
        let availableWidth = collectionView.bounds.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right
        let width = min(availableWidth * 0.9, 300)
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath())
        let numberOfCellsInSection = CGFloat(self.resultsController?.sections?[section].numberOfObjects ?? 0)
        let viewWidth = self.collectionView?.frame.size.width ?? 0

        var leftPadding = collectionView.layoutMargins.left - 14
        var rightPadding = collectionView.layoutMargins.right - 14

        if #available(iOS 11.0, *) {
            leftPadding -= collectionView.safeAreaInsets.left
            rightPadding -= collectionView.safeAreaInsets.right
        }

        let horizontalCenteredPadding = (viewWidth - numberOfCellsInSection * cellSize.width) / 2
        leftPadding = max(leftPadding, horizontalCenteredPadding)
        rightPadding = max(leftPadding, horizontalCenteredPadding)

        return UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding)
    }

}

struct CourseOverviewViewConfiguration: CollectionViewResultsControllerConfiguration {

    func configureCollectionCell(_ cell: UICollectionViewCell, for controller: NSFetchedResultsController<Course>, indexPath: IndexPath) {
        let cell = cell.require(toHaveType: CourseCell.self, hint: "CourseOverviewViewController requires cell of type CourseCell")
        let course = controller.object(at: indexPath)
        cell.configure(course, forConfiguration: .courseOverview)
    }

}
