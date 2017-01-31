//
//  CollectionVC.swift
//  Virtual Tourist
//
//  Created by Nitish on 30/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import UIKit
import CoreData

class CollectionVC: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    
    var selectedPin : Pin!
    let appDelegate = AppDelegate()
    var downloadedPhotos = [Photo]()        //selectedPinphoto
    var presentPhotos = [Photo]()       //collectionviewphotos
    var deletePhotos = [Photo]()        //photosdeleted
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadedPhotos = Array(selectedPin.photo!) as! [Photo]
        
        var albumPhotos = [Photo]()
        for p in downloadedPhotos{
            if p.url != nil{
                albumPhotos.append(p)
            }
        }
        
        presentPhotos = albumPhotos
        
        if presentPhotos.isEmpty{
            self.displayAlert(error: "No photos found for this pin")
        }
        
        selectedPin.photo = Set(downloadedPhotos) as NSSet?
        
        do{
            try appDelegate.stack.saveContext()
        }catch{
            self.displayAlert(error:"Couldn't save.")
        }
    }
    @IBAction func newCollection(_ sender: Any) {
        if deletePhotos.isEmpty{
            deletePhotos = presentPhotos
            if downloadedPhotos.count > 0{
                newCollection(sender)
            }else{
                performUIUpdatesOnMain {
                    self.displayAlert(error: "All photos are deleted")
                }
            }
            collectionView.reloadData()
        }else{
            
        }
    
    }

}
