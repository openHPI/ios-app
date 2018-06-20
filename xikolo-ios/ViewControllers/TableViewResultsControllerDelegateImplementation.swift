//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import UIKit

// swiftlint:disable:next type_name
class TableViewResultsControllerDelegateImplementation<T: NSManagedObject> : NSObject, NSFetchedResultsControllerDelegate, UITableViewDataSource {

    private let errorMessageIndexSetConversion = "Convertion of IndexSet for multiple FetchedResultsControllers failed"
    private let errorMessageIndexPathConversion = "Convertion of IndexPath for multiple FetchedResultsControllers failed"
    private let errorMessageNewIndexPathConversion = "Convertion of NewIndexPath for multiple FetchedResultsControllers failed"

    weak var tableView: UITableView?
    var resultsControllers: [NSFetchedResultsController<T>]
    var cellReuseIdentifier: String

    var configuration: TableViewResultsControllerConfigurationWrapper<T>?

    required init(_ tableView: UITableView,
                  resultsController: [NSFetchedResultsController<T>],
                  cellReuseIdentifier: String) {
        self.tableView = tableView
        self.resultsControllers = resultsController
        self.cellReuseIdentifier = cellReuseIdentifier
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        let convertedIndexSet = self.indexSet(for: controller, with: sectionIndex).require(hint: self.errorMessageIndexSetConversion)
        switch type {
        case .insert:
            self.tableView?.insertSections(convertedIndexSet, with: .fade)
        case .delete:
            self.tableView?.deleteSections(convertedIndexSet, with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        let convertedIndexPath = self.indexPath(for: controller, with: indexPath)
        let convertedNewIndexPath = self.indexPath(for: controller, with: newIndexPath)
        switch type {
        case .insert:
            self.tableView?.insertRows(at: [convertedNewIndexPath.require(hint: errorMessageNewIndexPathConversion)], with: .fade)
        case .delete:
            self.tableView?.deleteRows(at: [convertedIndexPath.require(hint: self.errorMessageIndexPathConversion)], with: .fade)
        case .update:
            self.tableView?.reloadRows(at: [convertedIndexPath.require(hint: self.errorMessageIndexPathConversion)], with: .fade)
        case .move:
            self.tableView?.deleteRows(at: [convertedIndexPath.require(hint: self.errorMessageIndexPathConversion)], with: .fade)
            self.tableView?.insertRows(at: [convertedNewIndexPath.require(hint: self.errorMessageNewIndexPathConversion)], with: .fade)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsControllers.reduce(0) { partialCount, controller -> Int in
            return (controller.sections?.count ?? 0) + partialCount
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var sectionsToGo = section
        for controller in resultsControllers {
            let sectionCount = controller.sections?.count ?? 0
            if sectionsToGo >= sectionCount {
                sectionsToGo -= sectionCount
            } else {
                return controller.sections?[sectionsToGo].numberOfObjects ?? 0
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let (controller, newIndexPath) = controllerAndImplementationIndexPath(forVisual: indexPath)!
        self.configuration?.configureTableCell(cell, for: controller, indexPath: newIndexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let (controller, newSection) = controllerAndImplementationSection(forSection: section)!
        guard let headerTitle = self.configuration?.titleForDefaultHeader(forController: controller, forSection: newSection) else {
            return nil
        }

        return headerTitle
    }

}

extension TableViewResultsControllerDelegateImplementation { // Conversion of indices between data and views
    // correct "visual" indexPath for data controller and its indexPath (data->visual)
    func indexPath(for controller: NSFetchedResultsController<NSFetchRequestResult>, with indexPath: IndexPath?) -> IndexPath? {
        guard var newIndexPath = indexPath else {
            return nil
        }

        for contr in resultsControllers {
            if contr == controller {
                return newIndexPath
            } else {
                newIndexPath.section += contr.sections?.count ?? 0
            }
        }

        return nil
    }

    // correct "visual" indexSet for data controller and its indexSet (data->visual)
    func indexSet(for controller: NSFetchedResultsController<NSFetchRequestResult>, with sectionIndex: Int?) -> IndexSet? {
        guard let oldSectionIndex = sectionIndex else { return nil }
        var convertedIndexSet = IndexSet()
        var passedSections = 0
        for contr in resultsControllers {
            if contr == controller {
                passedSections += oldSectionIndex
                convertedIndexSet.insert(passedSections)
                break
            } else {
                passedSections += contr.sections?.count ?? 0
            }
        }

        return convertedIndexSet
    }

    // find data controller and its sectionIndex for a given "visual" sectionIndex (visual->data)
    func controllerAndImplementationSection(forSection section: Int) -> (NSFetchedResultsController<T>, Int)? {
        var passedSections = 0
        for contr in resultsControllers {
            if passedSections + (contr.sections?.count ?? 0) > section {
                let newSection = section - passedSections
                return (contr, newSection)
            } else {
                passedSections += (contr.sections?.count ?? 0)
            }
        }

        return nil
    }

    // find data controller and its indexPath for a given "visual" indexPath (visual->data)
    func controllerAndImplementationIndexPath(forVisual indexPath: IndexPath) -> (NSFetchedResultsController<T>, IndexPath)? {
        var passedSections = 0
        for contr in resultsControllers {
            if passedSections + (contr.sections?.count ?? 0) > indexPath.section {
                let newIndexPath = IndexPath(item: indexPath.item, section: indexPath.section - passedSections)
                return (contr, newIndexPath)
            } else {
                passedSections += (contr.sections?.count ?? 0)
            }
        }

        return nil
    }

}

protocol TableViewResultsControllerConfigurationProtocol {

    associatedtype Content: NSManagedObject

    func configureTableCell(_ cell: UITableViewCell, for controller: NSFetchedResultsController<Content>, indexPath: IndexPath)

    func titleForDefaultHeader(forController controller: NSFetchedResultsController<Content>, forSection section: Int) -> String?

}

extension TableViewResultsControllerConfigurationProtocol {

    func titleForDefaultHeader(forController controller: NSFetchedResultsController<Content>, forSection section: Int) -> String? {
        return nil
    }

}

protocol TableViewResultsControllerConfiguration: TableViewResultsControllerConfigurationProtocol {
    var wrapped: TableViewResultsControllerConfigurationWrapper<Content> { get }
}

extension TableViewResultsControllerConfiguration {
    var wrapped: TableViewResultsControllerConfigurationWrapper<Content> {
        return TableViewResultsControllerConfigurationWrapper(self)
    }
}

// This is a wrapper for type erasure allowing the generic TableViewResultsControllerDelegateImplementation to be
// configured with a concrete type (via a configuration struct).
// swiftlint:disable:next type_name
class TableViewResultsControllerConfigurationWrapper<T: NSManagedObject>: TableViewResultsControllerConfigurationProtocol {

    private let _configureTableCell: (UITableViewCell, NSFetchedResultsController<T>, IndexPath) -> Void
    private let _titleForDefaultHeader: (NSFetchedResultsController<T>, Int) -> String?

    required init<U: TableViewResultsControllerConfiguration>(_ configuration: U) where U.Content == T {
        self._configureTableCell = configuration.configureTableCell
        self._titleForDefaultHeader = configuration.titleForDefaultHeader
    }

    func configureTableCell(_ cell: UITableViewCell, for controller: NSFetchedResultsController<T>, indexPath: IndexPath) {
        self._configureTableCell(cell, controller, indexPath)
    }

    func titleForDefaultHeader(forController controller: NSFetchedResultsController<T>, forSection section: Int) -> String? {
        return self._titleForDefaultHeader(controller, section)
    }

}
