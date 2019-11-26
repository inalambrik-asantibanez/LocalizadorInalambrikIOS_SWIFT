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
    
    func saveLocationReportObjectOnFetchLocation(_ locationReport : CLLocation, _ reportType: String, _ errorLocation: String? = "")
    {
        //Variables of the location report
        let Year             = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "YYYY"))
        let Month            = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "MM"))
        let Day              = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "dd"))
        let Hour             = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "HH"))
        let Minute           = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "mm"))
        let Second           = Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "ss"))
        
        let Latitude         = Float(locationReport.coordinate.latitude)
        let Longitude        = Float(locationReport.coordinate.longitude)
        let Altitude         = Float(locationReport.altitude)
        let Speed            = Float(locationReport.speed)
        let Orientation      = 0
        let Satellites       = 9
        let Accuracy         = getLocationAccuracy(locationReport)
        let Status           = "P"
        let NetworkType      = reportType == "V" ? "GPS" : "INV"
        let MCC              = 0
        let MNC              = 0
        let LAC              = 0
        let CID              = 0
        let BatteryLevel     = Int(DeviceUtilities.shared().getBatteryStatus())
        let EventCode        = reportType == "V" ? 1 : 14
        let ReportDate       = locationReport.timestamp
        let GpsStatus        = reportType
        
        //Save Location Report To DB
        _ = LocationReportInfo(year: Year!, month: Month!, day: Day!, hour: Hour!, minute: Minute!, second: Second!, latitude: Latitude, longitude: Longitude, altitude: Int(Altitude), speed: Int(Speed), orientation: Orientation, satellites: Satellites, accuracy: Accuracy, status: Status, networkType: NetworkType, mcc: MCC, mnc: MNC, lac: LAC, cid: CID, batteryLevel: BatteryLevel, eventCode: EventCode, reportDate: ReportDate,gpsStatus: GpsStatus,errorLocation: errorLocation!,reportIsInvalid:"0", context: CoreDataStack.shared().context)
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
    
    func getLastLocationReport()
    {
        
    }
    
    public func getLastLocationInfo() -> LocationReportInfo
    {
        do
        {
            guard let lastLocationReport = try CoreDataStack.shared().fetchLocationReport(nil, entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
                else
                {
                    return LocationReportInfo(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, latitude: 0, longitude: 0, altitude: 0, speed: 0, orientation: 0, satellites: 0, accuracy: 0, status: "P", networkType: "GPS", mcc: 0, mnc: 0, lac: 0, cid: 0, batteryLevel: 0, eventCode: 0, reportDate: Date(), gpsStatus: "V",errorLocation: "",reportIsInvalid: "0", context: CoreDataStack.shared().context)
                }
            return lastLocationReport
        }
        catch
        {
            return LocationReportInfo(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, latitude: 0, longitude: 0, altitude: 0, speed: 0, orientation: 0, satellites: 0, accuracy: 0, status: "P", networkType: "GPS", mcc: 0, mnc: 0, lac: 0, cid: 0, batteryLevel: 0, eventCode: 0, reportDate: Date(), gpsStatus: "V",errorLocation: "",reportIsInvalid: "0", context: CoreDataStack.shared().context)
        }
    }
    
    public func checkIfExistsLocationReport() -> Bool
    {
        do
        {
            guard (try CoreDataStack.shared().fetchLocationReport(NSPredicate(format: " reportIsInvalid == %@ " ,"0"), entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))) != nil
            else
            {
                return false
            }
            return true
        }
        catch
        {
            return false
        }
    }
}
