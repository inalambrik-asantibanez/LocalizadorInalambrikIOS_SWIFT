//
//  User.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreData

@objc(User)

public class User: NSManagedObject
{
    static let name = "User"
    
    convenience init(userId: String, deviceId: String, authorizedDevice: String,deviceIdentifierVendorID: String,apple_pn_id: String, context: NSManagedObjectContext ) {
        if let ent = NSEntityDescription.entity(forEntityName: User.name, in: context)
        {
            self.init(entity: ent, insertInto: context)
            self.userId = userId
            self.deviceId = deviceId
            self.authorizedDevice = authorizedDevice
            self.deviceIdentifierVendorID = deviceIdentifierVendorID
            self.apple_pn_id = apple_pn_id
        }
        else{
            fatalError("Unable to find Entity Name!")
        }
    }
    
}

