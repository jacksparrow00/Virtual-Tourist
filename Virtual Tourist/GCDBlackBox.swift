//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Nitish on 23/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {              //to perform UI updates on Main thread
    DispatchQueue.main.async {
        updates()
    }
}
