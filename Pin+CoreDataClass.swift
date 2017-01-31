//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Nitish on 28/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Pin: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D{
        get{
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set(coordinate){
            self.coordinate = coordinate
        }
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?){
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(pinLatitude: Double, pinLongitude: Double, context: NSManagedObjectContext?) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context!){
            self.init(entity: ent, insertInto: context)
            self.latitude = pinLatitude
            self.longitude = pinLongitude
        }else{
            fatalError("Unable to find Entity name")
        }
    }

}
