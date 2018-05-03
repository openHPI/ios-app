//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import UIKit

class AbstractCourseListViewController: UICollectionViewController {

    enum CourseDisplayMode {
        case enrolledOnly
        case all
        case explore
        case bothSectioned
    }

    var resultsControllers: [NSFetchedResultsController<Course>] = []
    var resultsControllerDelegateImplementation: CollectionViewResultsControllerDelegateImplementation<Course>!
    var courseDisplayMode: CourseDisplayMode = .enrolledOnly {
        didSet {
            if self.courseDisplayMode != oldValue {
                self.updateView()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateView()
        CourseHelper.syncAllCourses()
    }

    func updateView() {
        switch courseDisplayMode {
        case .enrolledOnly:
            resultsControllers = [
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.enrolledCurrentCoursesRequest, sectionNameKeyPath: "currentSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.enrolledUpcomingCourses, sectionNameKeyPath: "upcomingSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.enrolledSelfPacedCourses, sectionNameKeyPath: "selfpacedSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.completedCourses, sectionNameKeyPath: "completedSectionName"),
            ]
        case .explore:
            resultsControllers = [
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.interestingCoursesRequest, sectionNameKeyPath: "interestingSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.pastCourses, sectionNameKeyPath: "selfpacedSectionName"),
            ]
        case .all:
            resultsControllers = [
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.currentCourses, sectionNameKeyPath: "currentSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.upcomingCourses, sectionNameKeyPath: "upcomingSectionName"),
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.selfpacedCourses, sectionNameKeyPath: "selfpacedSectionName"),
            ]
        case .bothSectioned:
            resultsControllers = [
                CoreDataHelper.createResultsController(CourseHelper.FetchRequest.allCoursesSectioned, sectionNameKeyPath: "isEnrolledSectionName"),
            ]
        }

        let searchFetchRequest = CourseHelper.FetchRequest.accessibleCourses
        let reuseIdentifier = R.reuseIdentifier.courseCell.identifier
        resultsControllerDelegateImplementation = CollectionViewResultsControllerDelegateImplementation(self.collectionView,
                                                                                                        resultsControllers: resultsControllers,
                                                                                                        searchFetchRequest: searchFetchRequest,
                                                                                                        cellReuseIdentifier: reuseIdentifier)

        resultsControllerDelegateImplementation.headerReuseIdentifier = R.nib.courseHeaderView.name
        let configuration = CourseListViewConfiguration().wrapped
        resultsControllerDelegateImplementation.configuration = configuration

        for resultsController in resultsControllers {
            resultsController.delegate = resultsControllerDelegateImplementation
        }

        self.collectionView?.dataSource = resultsControllerDelegateImplementation

        do {
            for resultsController in resultsControllers {
                try resultsController.performFetch()
            }
        } catch {
            CrashlyticsHelper.shared.recordError(error)
            log.error(error)
        }

        self.collectionView?.reloadData()
    }

}

struct CourseListViewConfiguration: CollectionViewResultsControllerConfiguration {

    func configureCollectionCell(_ cell: UICollectionViewCell, for controller: NSFetchedResultsController<Course>, indexPath: IndexPath) {
        let cell = cell.require(toHaveType: CourseCell.self, hint: "CourseList requires cells of type CourseCell")
        let course = controller.object(at: indexPath)
        cell.configure(course, forConfiguration: .courseList)
    }

    func configureCollectionHeaderView(_ view: UICollectionReusableView, section: NSFetchedResultsSectionInfo) {
        let headerView = view.require(toHaveType: CourseHeaderView.self, hint: "CourseList requires header cells of type CourseHeaderView")
        headerView.configure(section)
    }

    func searchPredicate(forSearchText searchText: String) -> NSPredicate? {
        let subPredicates = searchText.split(separator: " ").map(String.init).map { searchTextPart in
            return NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "title CONTAINS[c] %@", searchTextPart),
                NSPredicate(format: "teachers CONTAINS[c] %@", searchTextPart),
                NSPredicate(format: "abstract CONTAINS[c] %@", searchTextPart),
            ])
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
    }

    func configureSearchHeaderView(_ view: UICollectionReusableView, numberOfSearchResults: Int) {
        let view = view as! CourseHeaderView // swiftlint:disable:this force_cast
        let format = NSLocalizedString("%d courses found", tableName: "Common", comment: "<number> of courses found #bc-ignore!")
        view.configure(withText: String.localizedStringWithFormat(format, numberOfSearchResults))
    }

}
