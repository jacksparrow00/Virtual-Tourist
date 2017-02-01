//
//  CollectionViewController.swift
//  Virtual Tourist
//
//  Created by Nitish on 31/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CollectionViewController: CoreDataCollectionViewController {
    
    let appDelegate = AppDelegate()
    var downloadedPhotos = [Photo]()                //downloaded photos for the pin
    var collectionPhotos = [Photo]()                //selected photos for the pin
    var deletedPhotos = [Photo]()                   //deleted photos for the pin
    var selectedPin: Pin!                           //to get selected pin from mapViewController
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Flickr Photos"
        let space:CGFloat = 3.0                                                 //resize cell according to device
        let cellWidth = (self.view.frame.size.width-(2*space))/3.0
        let cellHeight = (self.view.frame.size.height-(2*space))/3.0
        
        flowLayout.minimumLineSpacing = 1.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        downloadedPhotos = Array(selectedPin.photo!) as! [Photo]
        
        var albumPhotos = [Photo]()                 //get photos which have url stored in core data
        for p in downloadedPhotos{
            if p.url != nil{
                albumPhotos.append(p)
            }
        }
        
        collectionPhotos = albumPhotos              //get photos selected for the pin
        
        if collectionPhotos.isEmpty{                    //error handling
            self.displayAlert(error: "No photos found for this pin")
        }
        
        selectedPin.photo = Set(downloadedPhotos) as NSSet?
        
        do{
            try appDelegate.stack.saveContext()             //save context
        }catch{
            self.displayAlert(error:"Couldn't save.")
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")          //defining the fetch request
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        collectionView.reloadData()             //refreshing the view
    }
    
    @IBAction func newCollection(_ sender: Any) {           //called when new collection of photos is required
        if deletedPhotos.isEmpty{
            deletedPhotos = collectionPhotos
            if downloadedPhotos.count > 0{
                newCollection(sender)
            }else{
                performUIUpdatesOnMain {
                    self.displayAlert(error: "All photos are deleted")
                }
            }
            collectionView.reloadData()
        }else{
            collectionPhotos = collectionPhotos.filter{!deletedPhotos.contains($0)}     //selected photos for the pin are filtered out for the ones that have delete photos
            
            downloadedPhotos = downloadedPhotos.filter{!deletedPhotos.contains($0)}     //same filtering for the downloaded photos
            
            deletedPhotos = []          //empty the deleted photos array and it will go back again to previous if block to see if the photos are deleted
            
            do{
                try appDelegate.stack.saveContext()
            }catch{
                self.displayAlert(error:"Couldn't save.")
            }
            
            performUIUpdatesOnMain {
                self.displayAlert(error: "Photos deleted")
            }
            
            collectionView.reloadData()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        
        loadImage(indexPath: indexPath, cell: cell)
        return cell
    }
    
    func loadImage(indexPath: IndexPath, cell: Cell) {
        cell.imageView.image = nil
        
        if collectionPhotos[indexPath.row].photo == nil {
            performUIUpdatesOnMain {
                cell.activityIndicator.startAnimating()         //start animating
            }
            for pic in downloadedPhotos{
                FlickrAPI.sharedInstance().downloadImage(imagePath: collectionPhotos[indexPath.row].url!, completionHandlerForDownload: { (imageData, error) in         //download the image for the given url
                    guard error == nil else{                //error handling
                        self.displayAlert(error: "\(error)")
                        return
                    }
                    
                    performUIUpdatesOnMain {
                        cell.activityIndicator.stopAnimating()      //stop animating when data is recieved
                        cell.imageView.image = UIImage(data: imageData as! Data)            //display the image
                    }
                })
            }
        }else{
            let pic = fetchedResultsController?.object(at: indexPath) as! Photo         //fetch the photo from core data
            performUIUpdatesOnMain {
                cell.activityIndicator.stopAnimating()          //stop acitivity indicator
                cell.imageView.image = UIImage(data: pic.photo as! Data)
            }
            
        }
    }
    
    override func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {             //override method from coredatacollection view controller
        collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {          //override method from coredatacollection view controller
        let set = IndexSet(integer: sectionIndex)
            switch (type){
            case .delete:
                collectionView.deleteSections(set)
            default:
                break
            }
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {               //override method from coredatacollection view controller
        switch type {
        case .delete:
            collectionView.deleteItems(at: [newIndexPath!])
        case .update:
            collectionView.reloadData()
        default:
            break
        }
    }
}

