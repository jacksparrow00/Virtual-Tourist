//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Nitish on 28/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    convenience init( url: String, insertInto context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.photo = NSData()
        }else{
            fatalError("Unable to find Entity name!")
        }
    }

}
