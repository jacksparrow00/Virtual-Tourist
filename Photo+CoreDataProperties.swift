//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Nitish on 28/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var photo: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
