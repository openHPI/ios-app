//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

protocol CoreDataCollectionViewDataSourceDelegate: AnyObject {

    associatedtype Object: NSFetchRequestResult
    associatedtype Cell: UICollectionViewCell
    associatedtype HeaderView: UICollectionReusableView

    func configure(_ cell: Cell, for object: Object)
    func configureHeaderView(_ headerView: HeaderView, sectionInfo: NSFetchedResultsSectionInfo)

    func searchPredicate(forSearchText searchText: String) -> NSPredicate?
    func configureSearchHeaderView(_ searchHeaderView: HeaderView, numberOfSearchResults: Int)

}

extension CoreDataCollectionViewDataSourceDelegate {

    func configureHeaderView(_ view: HeaderView, sectionInfo: NSFetchedResultsSectionInfo) {}

    func searchPredicate(forSearchText searchText: String) -> NSPredicate? {
        return nil
    }

    func configureSearchHeaderView(_ view: HeaderView, numberOfSearchResults: Int) {}

}

class CoreDataCollectionViewDataSource<Delegate: CoreDataCollectionViewDataSourceDelegate>: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    typealias Object = Delegate.Object
    typealias Cell = Delegate.Cell
    typealias HeaderView = Delegate.HeaderView

    private let emptyCellReuseIdentifier = "collectionview.cell.empty"

    private weak var collectionView: UICollectionView?
    private var fetchedResultsControllers: [NSFetchedResultsController<Object>]
    private var cellReuseIdentifier: String
    private var headerReuseIdentifier: String?
    private weak var delegate: Delegate?

    private var searchFetchRequest: NSFetchRequest<Object>?
    private var searchFetchResultsController: NSFetchedResultsController<Object>?

    private var contentChangeOperations: [BlockOperation] = []

    required init(_ collectionView: UICollectionView?,
                  fetchedResultsControllers: [NSFetchedResultsController<Object>],
                  searchFetchRequest: NSFetchRequest<Object>? = nil,
                  cellReuseIdentifier: String,
                  headerReuseIdentifier: String? = nil,
                  delegate: Delegate) {
        self.collectionView = collectionView
        self.fetchedResultsControllers = fetchedResultsControllers
        self.searchFetchRequest = searchFetchRequest
        self.cellReuseIdentifier = cellReuseIdentifier
        self.headerReuseIdentifier = headerReuseIdentifier
        self.delegate = delegate
        super.init()
        self.collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.emptyCellReuseIdentifier)

        do {
            for fetchedResultsController in self.fetchedResultsControllers {
                fetchedResultsController.delegate = self
                try fetchedResultsController.performFetch()
            }
        } catch {
            CrashlyticsHelper.shared.recordError(error)
            log.error(error)
        }

        self.collectionView?.dataSource = self
        self.collectionView?.reloadData()
    }

    var isSearching: Bool {
        return self.searchFetchResultsController != nil
    }

    var hasSearchResults: Bool {
        return !(self.searchFetchResultsController?.fetchedObjects?.isEmpty ?? true)
    }

    func object(at indexPath: IndexPath) -> Object {
        if let searchResultsController = self.searchFetchResultsController {
            return searchResultsController.object(at: indexPath)
        }

        let (controller, dataIndexPath) = self.controllerAndImplementationIndexPath(forVisual: indexPath)
        return controller.object(at: dataIndexPath)
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        guard self.searchFetchResultsController == nil else { return }

        let indexSet = IndexSet(integer: sectionIndex)
        let convertedIndexSet = self.indexSet(for: controller, with: indexSet)

        switch type {
        case .insert:
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.insertSections(convertedIndexSet)
            }))
        case .delete:
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.deleteSections(convertedIndexSet)
            }))
        case .move, .update:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        guard self.searchFetchResultsController == nil else { return }

        switch type {
        case .insert:
            let newIndexPath = newIndexPath.require(hint: "newIndexPath is required for collection view cell insert")
            let convertedNewIndexPath = self.indexPath(for: controller, with: newIndexPath)
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.insertItems(at: [convertedNewIndexPath])
            }))
        case .delete:
            let indexPath = newIndexPath.require(hint: "indexPath is required for collection view cell delete")
            let convertedIndexPath = self.indexPath(for: controller, with: indexPath)
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.deleteItems(at: [convertedIndexPath])
            }))
        case .update:
            let indexPath = newIndexPath.require(hint: "indexPath is required for collection view cell update")
            let convertedIndexPath = self.indexPath(for: controller, with: indexPath)
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.reloadItems(at: [convertedIndexPath])
            }))
        case .move:
            let indexPath = newIndexPath.require(hint: "indexPath is required for collection view cell move")
            let newIndexPath = newIndexPath.require(hint: "newIndexPath is required for collection view cell move")
            let convertedIndexPath = self.indexPath(for: controller, with: indexPath)
            let convertedNewIndexPath = self.indexPath(for: controller, with: newIndexPath)
            self.contentChangeOperations.append(BlockOperation(block: {
                self.collectionView?.deleteItems(at: [convertedIndexPath])
                self.collectionView?.insertItems(at: [convertedNewIndexPath])
            }))
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard self.searchFetchResultsController == nil else { return }

        self.collectionView?.performBatchUpdates({
            for operation in self.contentChangeOperations {
                operation.start()
            }
        }, completion: { _ in
            self.contentChangeOperations.removeAll(keepingCapacity: false)
        })
    }

    deinit {
        for operation in self.contentChangeOperations {
            operation.cancel()
        }

        self.contentChangeOperations.removeAll(keepingCapacity: false)
        self.fetchedResultsControllers.removeAll(keepingCapacity: false)
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if self.isSearching {
            return 1
        } else {
            return self.fetchedResultsControllers.map { $0.sections?.count ?? 0 }.reduce(0, +)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let searchResultsController = self.searchFetchResultsController {
            return max(searchResultsController.fetchedObjects?.count ?? 0, 1)
        } else {
            var sectionsToGo = section
            for controller in self.fetchedResultsControllers {
                let sectionCount = controller.sections?.count ?? 0
                if sectionsToGo >= sectionCount {
                    sectionsToGo -= sectionCount
                } else {
                    return controller.sections?[sectionsToGo].numberOfObjects ?? 0
                }
            }

            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.searchFetchResultsController?.fetchedObjects?.isEmpty ?? false {
            return collectionView.dequeueReusableCell(withReuseIdentifier: self.emptyCellReuseIdentifier, for: indexPath)
        }

        let someCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseIdentifier, for: indexPath) as? Cell
        let cell = someCell.require(hint: "Unexpected cell type at \(indexPath), expected cell of type \(Cell.self)")
        let object = self.object(at: indexPath)
        self.delegate?.configure(cell, for: object)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.headerReuseIdentifier!, for: indexPath) as? HeaderView else {
                fatalError("Unexpected header view type, expected \(HeaderView.self)")
            }

            if let searchResultsController = self.searchFetchResultsController {
                if let numberOfSearchResults = searchResultsController.fetchedObjects?.count {
                    self.delegate?.configureSearchHeaderView(view, numberOfSearchResults: numberOfSearchResults)
                }
            } else {
                let (controller, newIndexPath) = self.controllerAndImplementationIndexPath(forVisual: indexPath)
                if let sectionInfo = controller.sections?[newIndexPath.section] {
                    self.delegate?.configureHeaderView(view, sectionInfo: sectionInfo)
                }
            }

            return view
        } else {
            return UICollectionReusableView()
        }
    }

    func search(withText searchText: String) {
        guard let fetchRequest = self.searchFetchRequest?.copy() as? NSFetchRequest<Object> else {
            log.warning("CollectionViewControllerDelegateImplementation is not configured for search. Missing search fetch request.")
            self.resetSearch()
            return
        }

        guard !searchText.isEmpty else {
            self.resetSearch()
            return
        }

        let searchPredicate = self.delegate?.searchPredicate(forSearchText: searchText)
        let fetchPredicate = fetchRequest.predicate
        let predicates = [fetchPredicate, searchPredicate].compactMap { $0 }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        self.searchFetchResultsController = CoreDataHelper.createResultsController(fetchRequest, sectionNameKeyPath: nil)

        do {
            try self.searchFetchResultsController?.performFetch()
        } catch {
            CrashlyticsHelper.shared.recordError(error)
            log.error(error)
        }

        self.collectionView?.reloadData()
    }

    func resetSearch() {
        let shouldReloadData = self.isSearching
        self.searchFetchResultsController = nil
        if shouldReloadData {
            self.collectionView?.reloadData()
        }
    }

}

extension CoreDataCollectionViewDataSource { // Conversion of indices between data and views

    // correct "visual" indexPath for data controller and its indexPath (data->visual)
    private func indexPath(for controller: NSFetchedResultsController<NSFetchRequestResult>, with indexPath: IndexPath) -> IndexPath {
        var convertedIndexPath = indexPath

        for contr in self.fetchedResultsControllers {
            if contr == controller {
                return convertedIndexPath
            } else {
                convertedIndexPath.section += contr.sections?.count ?? 0
            }
        }

        fatalError("Convertion of indexPath (\(indexPath) in controller (\(controller.debugDescription) to indexPath failed")
    }

    // correct "visual" indexSet for data controller and its indexSet (data->visual)
    private func indexSet(for controller: NSFetchedResultsController<NSFetchRequestResult>, with indexSet: IndexSet) -> IndexSet {
        var convertedIndexSet = IndexSet()
        var passedSections = 0
        for contr in self.fetchedResultsControllers {
            if contr == controller {
                for index in indexSet {
                    convertedIndexSet.insert(index + passedSections)
                }

                break
            } else {
                passedSections += contr.sections?.count ?? 0
            }
        }

        return convertedIndexSet
    }

    // find data controller and its indexPath for a given "visual" indexPath (visual->data)
    private func controllerAndImplementationIndexPath(forVisual indexPath: IndexPath) -> (NSFetchedResultsController<Object>, IndexPath) {
        var passedSections = 0
        for contr in self.fetchedResultsControllers {
            if passedSections + (contr.sections?.count ?? 0) > indexPath.section {
                let newIndexPath = IndexPath(item: indexPath.item, section: indexPath.section - passedSections)
                return (contr, newIndexPath)
            } else {
                passedSections += (contr.sections?.count ?? 0)
            }
        }

        fatalError("Convertion of indexPath (\(indexPath) to controller and indexPath failed")
    }

}
