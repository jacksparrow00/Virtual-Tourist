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
    
    var pins = [Pin]()              //to get all the pins stored in core data
    var selectedPin: Pin!           //to get the currently selected pin and it's properties
    var editMode = false            //to determine the pin delete or pin drop mode of the app
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
        
        mapView.addAnnotations(pins)            //add annotations in the map for pins stored in core data
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin))           //add long press gesture recognizer
        longPress.minimumPressDuration = 1.5            //define long press duration
        mapView.addGestureRecognizer(longPress)         //add the gesture to mapView
    }
    
    @IBAction func editButton(_ sender: Any) {
        
        if editMode{                            //for pin drop mode of the app
            editMode = false
            Edit.title = "Edit"
            infoLabel.text = "Create new Pin or Select Pin"
            
            do{
                try appDelegate.stack.saveContext()                 //saving context in core data
            }catch{
                print("Couldn't save the view.")
            }
        } else{
            editMode = true                     //for pin delete mode of the app
            Edit.title = "Done"
            infoLabel.text = "Select the pins to delete"
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let mapPinFetch: NSFetchRequest<Pin> = Pin.fetchRequest()               //creating a pin fetch request
        print("selecting a pin")                //for debug purposes
        
        mapPinFetch.predicate = NSPredicate(format: "(%K = %@) AND (%K = %@)", #keyPath(Pin.latitude), #keyPath(Pin.longitude))             //constrain the selection of objects from core data for the selected pin
        //NS Predicate Syntax for getting the pins on Latitude & longitude respectively
        // Took help for NSPRedicate Syntax from http://nshipster.com/nspredicate/ , https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html
        
        var resultPin = [Pin]()
        
        
        
        
        //MARK: I am getting error in the following code block. But the console isn't showing any error. I am confused. I have implemented this very same code in viewDidLoad and it compiles there. But it isn't compiling here. Nor giving any errors. Any help will be appreciated.
        do{
            resultPin = try appDelegate.stack.context.fetch(mapPinFetch)
        }catch{
            print("Couldn't get the results Pins from NSPredicate")
        }
        
        if editMode{                    //for delete pin mode of app
            if resultPin.count > 0{
                mapView.removeAnnotation(resultPin.first!)              //remove the selected pin

                
                appDelegate.stack.context.delete(resultPin.first!)          //remove the pin from core data
                print("Pin removed from CoreData")
                
                do{
                    try appDelegate.stack.saveContext()         //save the core data context
                }catch{
                    print("Couldn't save. Please try again.")
                }
            }else{
                print("Couldn't fetch pins.")
            }
        }else{
            if resultPin.count > 0{
                selectedPin = resultPin.first               //get the selected pin
                
                let photosVC = self.storyboard?.instantiateViewController(withIdentifier: "collectionVC") as! CollectionViewController              //instantiate the collectionViewController
                photosVC.selectedPin = selectedPin              //send the selected pin info to the collectionview controller
                performUIUpdatesOnMain {
                    self.navigationController?.pushViewController(photosVC, animated: true) //bring the next view controller when the pin is clicked
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
            //putting and identifying coordinates from mapview
            
            let newPin = Pin(context: appDelegate.stack.context)
            newPin.latitude = coordinates.latitude          //initializing pin properties
            newPin.longitude = coordinates.longitude
            
            mapView.addAnnotation(newPin)               //adding the pin on the map
            
            infoLabel.text = "Select the pin to get photos."
            
            FlickrAPI.sharedInstance().search(pin: newPin, managedContext: appDelegate.stack.context, completionHandlerForSearch: { (data, error) in            //starting the function to get data from Parse api as soon as pin is dropped
                guard error == nil else{
                    self.displayAlert(error: error)
                    return
                }
            })
            
            do{
                try appDelegate.stack.saveContext()             //saving context in core data
            }catch{
                print("Couldn't save. Try again")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NextVC"{
            let collectionVC = segue.destination as! CollectionViewController
            collectionVC.selectedPin = selectedPin
        }
    }
}

