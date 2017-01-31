//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Nitish on 13/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import UIKit
import MapKit
import CoreData


extension UIViewController{
    func displayAlert(error: String?){      //to display all the errors in the app
        performUIUpdatesOnMain {
            let alertController = UIAlertController()
            alertController.title = "Error"
            alertController.message = error
            let alertAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pins = [Pin]()
    var selectedPin: Pin!
    var editMode = false
    let appDelegate = AppDelegate()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var Edit: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate!
        _ = delegate?.stack
        
        mapView.delegate = self
        infoLabel.text = "Hold a location to drop a pin on the map"
        
        do{
            pins = try appDelegate.stack.context.fetch(Pin.fetchRequest())
        }catch{
            print("Couldn't fetch the stored pins")
        }
        
        mapView.addAnnotations(pins)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)
    }
    
    @IBAction func editButton(_ sender: Any) {
        
        if editMode{
            editMode = false
            Edit.title = "Edit"
            infoLabel.text = "Create new Pin or Select Pin"
            
            do{
                try appDelegate.stack.saveContext()
            }catch{
                print("Couldn't save the view.")
            }
        } else{
            editMode = true
            Edit.title = "Done"
            infoLabel.text = "Select the pins to delete"
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let pinFetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        pinFetchRequest.predicate = NSPredicate(format: "(%K = %@) AND (%K = %@)", #keyPath(Pin.latitude), #keyPath(Pin.longitude))
        
        var resultPin = [Pin]()
        
        do{
            resultPin = try appDelegate.stack.context.fetch(pinFetchRequest)
        }catch{
            print("Couldn't get the results Pins from NSPredicate")
        }
        
        if editMode{
            if resultPin.count > 0{
                mapView.removeAnnotation(resultPin.first!)

                
                appDelegate.stack.context.delete(resultPin.first!)
                print("Pin removed from CoreData")
                
                do{
                    try appDelegate.stack.saveContext()
                }catch{
                    print("Couldn't save. Please try again.")
                }
            }else{
                print("Couldn't fetch pins.")
            }
        }else{
            if resultPin.count > 0{
                selectedPin = resultPin.first
                
                let photosVC = self.storyboard?.instantiateViewController(withIdentifier: "collectionVC") as! CollectionVC
                photosVC.selectedPin = selectedPin
                performUIUpdatesOnMain {
                    self.navigationController?.pushViewController(photosVC, animated: true)
                }
                
            }else{
                print("Unable to find any Pins")
            }
        }
    }
    
    func addPin(gesture: UIGestureRecognizer){
        if gesture.state == UIGestureRecognizerState.began{
            print("Input recieved")
            
            let gesture = gesture.location(in: mapView)         //http://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
            var coordinates = mapView.convert(gesture, toCoordinateFrom: mapView)
            
            let newPin = Pin(context: appDelegate.stack.context)
            newPin.latitude = coordinates.latitude
            newPin.longitude = coordinates.longitude
            
            mapView.addAnnotation(newPin)
            
            infoLabel.text = "Select the pin to get photos."
            
            FlickrAPI.sharedInstance().search(pin: newPin, managedContext: appDelegate.stack.context, completionHandlerForSearch: { (data, error) in
                guard error == nil else{
                    self.displayAlert(error: error)
                    return
                }
            })
            
            do{
                try appDelegate.stack.saveContext()
            }catch{
                print("Couldn't save. Try again")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NextVC"{
            let collectionVC = segue.destination as! CollectionVC
            collectionVC.selectedPin = selectedPin
        }
    }
}

