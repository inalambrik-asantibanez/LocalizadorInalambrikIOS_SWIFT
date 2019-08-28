//
//  LocationUtilities.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/27/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class LocationUtilities
{
    class func shared() -> LocationUtilities
    {
        struct Singleton {
            static var shared = LocationUtilities()
        }
        return Singleton.shared
    }
    
    func saveLocationReportObjectOnFetchLocation(_ locationReport : CLLocation)
    {
        //Variables of the location report
        let locationDateString = locationReport.timestamp.preciseLocalDate
        let locationTimeString = locationReport.timestamp.preciseLocalTime
        let locationDate = DeviceUtilities.shared().convertStringToDateTime(locationDateString, locationTimeString, "yyyy-MM-dd HH:mm:ss")
        
        let Year   = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "YYYY"))
        let Month  = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "MM"))
        let Day    = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "dd"))
        let Hour   = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "HH"))
        let Minute = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "mm"))
        let Second = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "ss"))
        
        let Latitude     = Float(locationReport.coordinate.latitude)
        let Longitude    = Float(locationReport.coordinate.longitude)
        let Altitude     = locationReport.altitude
        let Speed        = locationReport.speed
        let Orientation  = 0 //for the moment
        let Satellites   = getLocationSatellitesNumber(locationReport)
        let Accuracy     = getLocationAccuracy(locationReport)
        let Status       = "P"
        let NetworkType  = "DEFAULT"//DeviceUtilities.shared().getNetworkType()
        let MCC          = 0//DeviceUtilities.shared().getMCC()
        let MNC          = 0//DeviceUtilities.shared().getMNC()
        let LAC          = 0
        let CID          = 0
        let BatteryLevel = Int(DeviceUtilities.shared().getBatteryStatus())
        let EventCode    = 1
        let ReportDate   = locationReport.timestamp
        
        //Save Location Report To DB
        _ = LocationReportInfo(year: Year!, month: Month!, day: Day!, hour: Hour!, minute: Minute!, second: Second!, latitude: Latitude, longitude: Longitude, altitude: Int(Altitude), speed: Int(Speed), orientation: Orientation, satellites: Satellites, accuracy: Accuracy, status: Status, networkType: NetworkType, mcc: MCC, mnc: MNC, lac: LAC, cid: CID, batteryLevel: BatteryLevel, eventCode: EventCode, reportDate: ReportDate, context: CoreDataStack.shared().context)
        CoreDataStack.shared().save()
    }
    
    func getLocationSatellitesNumber(_ locationReport: CLLocation) -> Int
    {
        var locationSatellitesNumber = 0
        
        if locationReport.verticalAccuracy > 0
        {
            locationSatellitesNumber = 4
            if locationReport.horizontalAccuracy >= 0 && locationReport.horizontalAccuracy <= 60
            {
                locationSatellitesNumber = 5
            }
            else if locationReport.horizontalAccuracy >= 60 && locationReport.horizontalAccuracy <= 300
            {
                locationSatellitesNumber = 3
            }
        }
        else
        {
            if locationReport.horizontalAccuracy > 300
            {
                locationSatellitesNumber = 2
            }
        }
        return locationSatellitesNumber
    }
    
    func getLocationAccuracy(_ locationReport: CLLocation) -> Float
    {
        return Float((locationReport.verticalAccuracy+locationReport.horizontalAccuracy)/2)
    }
}
