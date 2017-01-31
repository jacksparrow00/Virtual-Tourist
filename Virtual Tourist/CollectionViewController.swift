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
    var downloadedPhotos = [Photo]()
    var collectionPhotos = [Photo]()
    var deletedPhotos = [Photo]()
    var selectedPin: Pin!
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
        
        var albumPhotos = [Photo]()
        for p in downloadedPhotos{
            if p.url != nil{
                albumPhotos.append(p)
            }
        }
        
        collectionPhotos = albumPhotos
        
        if collectionPhotos.isEmpty{
            self.displayAlert(error: "No photos found for this pin")
        }
        
        selectedPin.photo = Set(downloadedPhotos) as NSSet?
        
        do{
            try appDelegate.stack.saveContext()
        }catch{
            self.displayAlert(error:"Couldn't save.")
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        collectionView.reloadData()
    }
    
    @IBAction func newCollection(_ sender: Any) {
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
            collectionPhotos = collectionPhotos.filter{!deletedPhotos.contains($0)}
            
            downloadedPhotos = downloadedPhotos.filter{!deletedPhotos.contains($0)}
            
            do{
                try appDelegate.stack.saveContext()
            }catch{
                self.displayAlert(error:"Couldn't save.")
            }
            
            performUIUpdatesOnMain {
                self.displayAlert(error: "Photos deleted")
            }
            
            deletedPhotos = []
            
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
                cell.activityIndicator.startAnimating()
            }
            for pic in downloadedPhotos{
                FlickrAPI.sharedInstance().downloadImage(imagePath: collectionPhotos[indexPath.row].url!, completionHandlerForDownload: { (imageData, error) in
                    guard error == nil else{
                        self.displayAlert(error: "\(error)")
                        return
                    }
                    
                    performUIUpdatesOnMain {
                        cell.activityIndicator.stopAnimating()
                        cell.imageView.image = UIImage(data: imageData as! Data)
                    }
                })
            }
        }else{
            let pic = fetchedResultsController?.object(at: indexPath) as! Photo
            performUIUpdatesOnMain {
                cell.activityIndicator.stopAnimating()
            }
            cell.imageView.image = UIImage(data: pic.photo as! Data)
        }
    }
}
