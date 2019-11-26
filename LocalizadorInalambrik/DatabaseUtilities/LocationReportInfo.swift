//
//  PhoneInfo.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreData

@objc(LocationReportInfo)

public class LocationReportInfo: NSManagedObject
{
    static let name = "LocationReportInfo"
    
    
    convenience init(year: Int, month: Int, day: Int,hour: Int,minute: Int,second: Int,latitude: Float, longitude: Float, altitude: Int, speed: Int, orientation: Int, satellites: Int, accuracy: Float, status: String, networkType: String, mcc: Int, mnc:Int, lac: Int, cid: Int, batteryLevel:Int,eventCode: Int,reportDate: Date,gpsStatus: String,errorLocation: String,reportIsInvalid: String, context: NSManagedObjectContext ) {
        if let ent = NSEntityDescription.entity(forEntityName: LocationReportInfo.name, in: context)
        {
            self.init(entity: ent, insertInto: context)
            self.year            = year
            self.month           = month
            self.day             = day
            self.hour            = hour
            self.minute          = minute
            self.second          = second
            self.latitude        = latitude
            self.longitude       = longitude
            self.altitude        = altitude
            self.speed           = speed
            self.orientation     = orientation
            self.satellites      = satellites
            self.accuracy        = accuracy
            self.status          = status
            self.networkType     = networkType
            self.mcc             = mcc
            self.mnc             = mnc
            self.lac             = lac
            self.cid             = cid
            self.batteryLevel    = batteryLevel
            self.eventCode       = eventCode
            self.reportDate      = reportDate
            self.gpsStatus       = gpsStatus
            self.locationerror   = errorLocation
            self.reportIsInvalid = reportIsInvalid
        }
        else{
            fatalError("Unable to find Entity Name!")
        }
    }
}
