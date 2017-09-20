//
//  CourseListViewController.swift
//  xikolo-ios
//
//  Created by Arne Boockmeyer on 08/07/15.
//  Copyright © 2015 HPI. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CoreData


class CourseListViewController : AbstractCourseListViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var numberOfItemsPerRow = 1

    enum CourseDisplayMode {
        case enrolledOnly
        case all
        case explore
        case bothSectioned
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        self.collectionView?.emptyDataSetSource = nil
        self.collectionView?.emptyDataSetDelegate = nil
    }

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(CourseListViewController.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        if UserProfileHelper.isLoggedIn() {
            EnrollmentHelper.syncEnrollments().onComplete { _ in
                refreshControl.endRefreshing()
            }
        } else {
            CourseHelper.refreshCourses().onComplete { _ in
                refreshControl.endRefreshing()
            }
        }
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            if UserProfileHelper.isLoggedIn() {
                courseDisplayMode = .enrolledOnly
            } else {
                sender.selectedSegmentIndex = 1
                performSegue(withIdentifier: "ShowLogin", sender: sender)
            }
        case 1:
            courseDisplayMode = UserProfileHelper.isLoggedIn() ? .explore : .all
        default:
            break
        }
    }

    override func viewDidLoad() {
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionHeadersPinToVisibleBounds = true
        }

        if !UserProfileHelper.isLoggedIn() {
            segmentedControl.selectedSegmentIndex = 1
            courseDisplayMode = .all
        }

        self.collectionView?.addSubview(self.refreshControl)
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CourseListViewController.updateAfterLoginStateChange),
                                               name: NotificationKeys.loginStateChangedKey,
                                               object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        switch traitCollection.horizontalSizeClass {
        case .compact, .unspecified:
            numberOfItemsPerRow = 1
        case .regular:
            numberOfItemsPerRow = 2
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // Force redraw
            self.collectionView!.performBatchUpdates(nil, completion: nil)
        }, completion: nil)
    }

    func updateAfterLoginStateChange() {
        self.collectionView?.reloadEmptyDataSet()

        if UserProfileHelper.isLoggedIn() {
            self.segmentedControl.selectedSegmentIndex = 0
            self.courseDisplayMode = .enrolledOnly
        } else {
            self.segmentedControl.selectedSegmentIndex = 1
            self.courseDisplayMode = .all
        }

        CourseHelper.refreshCourses()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "ShowCourseContent"?:
                let vc = segue.destination as! CourseDecisionViewController
                let cell = sender as! CourseCell
                let indexPath = collectionView!.indexPath(for: cell)
                let (controller, dataIndexPath) = resultsControllerDelegateImplementation.controllerAndImplementationIndexPath(forVisual: indexPath!)!
                let course = controller.object(at: dataIndexPath)
                vc.course = try! CourseHelper.getByID(course.id) // TODO:
            default:
                break
        }
    }

}

extension CourseListViewController : UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
            let blankSpace = flowLayout.sectionInset.left
                + flowLayout.sectionInset.right
                + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
            let width = (collectionView.bounds.width - blankSpace) / CGFloat(numberOfItemsPerRow)
            return CGSize(width: width, height: width * 0.6)
    }

}
