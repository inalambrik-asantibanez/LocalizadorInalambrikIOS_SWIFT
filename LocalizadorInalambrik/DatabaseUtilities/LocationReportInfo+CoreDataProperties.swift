//
//  LocationReportInfo+CoreDataProperties.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreData

extension LocationReportInfo
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationReportInfo>
    {
        return NSFetchRequest<LocationReportInfo>(entityName: "LocationReportInfo")
    }
    
    //It declares the entity PhoneInfo properties
    @NSManaged public var year: Int
    @NSManaged public var month: Int
    @NSManaged public var day: Int
    @NSManaged public var hour: Int
    @NSManaged public var minute: Int
    @NSManaged public var second: Int
    @NSManaged public var latitude: Float
    @NSManaged public var longitude: Float
    @NSManaged public var altitude: Int
    @NSManaged public var speed: Int
    @NSManaged public var orientation: Int
    @NSManaged public var satellites: Int
    @NSManaged public var accuracy: Float
    @NSManaged public var status: String?
    @NSManaged public var networkType: String?
    @NSManaged public var mcc: Int
    @NSManaged public var mnc: Int
    @NSManaged public var lac: Int
    @NSManaged public var cid: Int
    @NSManaged public var batteryLevel: Int
    @NSManaged public var eventCode: Int
    @NSManaged public var reportDate: Date
    @NSManaged public var gpsStatus: String?
    @NSManaged public var locationerror: String?
}
