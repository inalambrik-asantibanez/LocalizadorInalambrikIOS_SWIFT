//
//  User+CoreDataProperties.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreData

extension User
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User>
    {
        return NSFetchRequest<User>(entityName: "User")
    }
    
    //It declares the entity User properties
    @NSManaged public var userId: String?
    @NSManaged public var deviceId: String?
    @NSManaged public var authorizedDevice: String?
    @NSManaged public var deviceIdentifierVendorID: String?
}
