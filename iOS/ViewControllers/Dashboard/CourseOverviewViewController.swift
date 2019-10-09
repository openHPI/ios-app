//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class CourseOverviewViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!

    private var dataSource: CoreDataCollectionViewDataSource<CourseOverviewViewController>!

    var configuration: CourseListConfiguration!

    private func configureCollectionView() {
        let reuseIdentifier = R.reuseIdentifier.courseCell.identifier
        self.dataSource = CoreDataCollectionViewDataSource(self.collectionView,
                                                           fetchedResultsControllers: self.configuration.resultsControllers,
                                                           cellReuseIdentifier: reuseIdentifier,
                                                           delegate: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = self.configuration.title

        self.collectionView.register(R.nib.courseCell)
        self.collectionView.register(R.nib.pseudoCourseCell)
        self.configureCollectionView()

        self.updateCollectionViewHeight()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let typedInfo = R.segue.courseOverviewViewController.showCourseList(segue: segue) {
            typedInfo.destination.configuration = self.configuration
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // swiftlint:disable:next trailing_closure
        coordinator.animate(alongsideTransition: { _ in
            self.updateCollectionViewHeight()
        })
    }

    @objc private func updateCollectionViewHeight() {
        let courseCellWidth = CourseCell.minimalWidth(for: self.collectionView.traitCollection)
        let availableWidth = self.view.bounds.width - self.view.layoutMargins.left - self.view.layoutMargins.right
        let preferredWidth = min(availableWidth * 0.9, courseCellWidth)
        let height = CourseCell.heightForOverviewList(forWidth: preferredWidth)
        self.collectionViewHeightConstraint.constant = ceil(height)
    }

}

extension CourseOverviewViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let numberOfCoreDataItems = self.dataSource.numberOfCoreDataItems(inSection: indexPath.section)
        let numberOfAdditionalItems = self.numberOfAdditonalItems(for: numberOfCoreDataItems, inSection: indexPath.section)
        let itemLimit = self.itemLimit(forSection: indexPath.section) ?? Int.max

        if numberOfAdditionalItems > 0, min(itemLimit, numberOfCoreDataItems) + numberOfAdditionalItems - 1 == indexPath.item {
            if numberOfCoreDataItems == 0 {
                self.appNavigator?.showCourseList()
            } else {
                self.performSegue(withIdentifier: R.segue.courseOverviewViewController.showCourseList, sender: nil)
            }
        } else {
            let course = self.dataSource.object(at: indexPath)
            self.appNavigator?.show(course: course)
        }
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
        let courseCellWidth = CourseCell.minimalWidth(for: collectionView.traitCollection)
        let availableWidth = collectionView.bounds.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right
        let preferedWidth = min(availableWidth * 0.9, courseCellWidth)

        let numberOfCoreDataItems = self.dataSource.numberOfCoreDataItems(inSection: indexPath.section)
        let numberOfAdditionalItems = self.numberOfAdditonalItems(for: numberOfCoreDataItems, inSection: indexPath.section)
        let itemLimit = self.itemLimit(forSection: indexPath.section) ?? Int.max

        let hasCourses = numberOfCoreDataItems > 0
        let hasAddtionaltems = numberOfAdditionalItems > 0
        let isLastCell = min(itemLimit, numberOfCoreDataItems) + numberOfAdditionalItems - 1 == indexPath.item
        let width = hasCourses && hasAddtionaltems && isLastCell ? preferedWidth * 2 / 3 : preferedWidth
        let height = CourseCell.heightForOverviewList(forWidth: preferedWidth)

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        var leftPadding = collectionView.layoutMargins.left - CourseCell.cardInset
        var rightPadding = collectionView.layoutMargins.right - CourseCell.cardInset

        if #available(iOS 11.0, *) {
            leftPadding -= collectionView.safeAreaInsets.left
            rightPadding -= collectionView.safeAreaInsets.right
        }

        return UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding)
    }

}

extension CourseOverviewViewController: CoreDataCollectionViewDataSourceDelegate {

    typealias HeaderView = UICollectionReusableView

    func configure(_ cell: CourseCell, for object: Course) {
        cell.configure(object, for: .courseOverview)
    }

    func shouldReloadCollectionViewForUpdate(from preChangeItemCount: Int?, to postChangeItemCount: Int) -> Bool {
        if preChangeItemCount == 0 || postChangeItemCount == 0 {
            return true
        }

        let itemLimit = self.itemLimit(forSection: 0) ?? Int.max
        let passedOverItemLimit = preChangeItemCount == itemLimit && (preChangeItemCount ?? Int.min) < postChangeItemCount
        let passedUnderItemLimit = postChangeItemCount == itemLimit && postChangeItemCount < (preChangeItemCount ?? Int.max)
        return passedOverItemLimit || passedUnderItemLimit
    }

    func itemLimit(forSection section: Int) -> Int? {
        return 5
    }

    func numberOfAdditonalItems(for numberOfCoreDataItems: Int, inSection section: Int) -> Int {
        let itemLimit = self.itemLimit(forSection: section) ?? Int.max
        return numberOfCoreDataItems > itemLimit || numberOfCoreDataItems == 0 ? 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, additionalCellForItemAt indexPath: IndexPath) -> UICollectionViewCell? {
        let numberOfCoreDataItems = self.dataSource.numberOfCoreDataItems(inSection: indexPath.section)
        let numberOfAdditionalItems = self.numberOfAdditonalItems(for: numberOfCoreDataItems, inSection: indexPath.section)
        let itemLimit = self.itemLimit(forSection: indexPath.section) ?? Int.max

        guard numberOfAdditionalItems > 0 else {
            return nil
        }

        guard min(itemLimit, numberOfCoreDataItems) <= indexPath.item else {
            return nil
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.pseudoCourseCell, for: indexPath)
        let style: PseudoCourseCell.Style = numberOfCoreDataItems == 0 ? .emptyCourseOverview : .showAllCoursesOfOverview
        cell?.configure(for: style, configuration: self.configuration)
        return cell
    }

}