//
//  CoreDataCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Nitish on 27/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension CoreDataCollectionViewController{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections?.count)!
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("This must be implemented by vc.")
    }
    
}

extension CoreDataCollectionViewController{
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError{
                self.displayAlert(error: "Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        fatalError("This must be implemented by vc.")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        fatalError("This must be implemented by vc.")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        fatalError("This must be implemented by vc.")
    }
}
