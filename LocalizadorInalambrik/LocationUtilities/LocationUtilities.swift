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
        let Year             = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "YYYY")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "YYYY"))
        let Month            = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "MM")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "MM"))
        let Day              = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "dd")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "dd"))
        let Hour             = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "HH")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "HH"))
        let Minute           = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "mm")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "mm"))
        let Second           = reportType == "" ? Int(DeviceUtilities.shared().convertDateTimeToString(locationReport.timestamp, "ss")) : Int(DeviceUtilities.shared().convertDateTimeToString(Date(), "ss"))
        
        let Latitude         = reportType == "" ? Float(locationReport.coordinate.latitude) : 0
        let Longitude        = reportType == "" ? Float(locationReport.coordinate.longitude) : 0
        let Altitude         = reportType == "" ? Float(locationReport.altitude) : 0
        let Speed            = reportType == "" ? Float(locationReport.speed) : 0
        let Orientation      = 0
        let Satellites       = reportType == "" ? 9 : 0
        let Accuracy         = reportType == "" ? getLocationAccuracy(locationReport) : 0
        let Status           = "P"
        let NetworkType      = reportType == "" ? "GPS" : "INV"
        let MCC              = 0
        let MNC              = 0
        let LAC              = 0
        let CID              = 0
        let BatteryLevel     = Int(DeviceUtilities.shared().getBatteryStatus())
        let EventCode        = reportType == "" ? 1 : 14
        let ReportDate       = reportType == "" ? locationReport.timestamp : Date()
        var GpsStatus        = ""
        
        
        if reportType != ""
        {
            GpsStatus = "I"
        }
        else if (abs(locationReport.coordinate.latitude) == 0 || abs(locationReport.coordinate.longitude) == 0)
        {
            GpsStatus = "I"
        }
        
        
        //Save Location Report To DB
        _ = LocationReportInfo(year: Year!, month: Month!, day: Day!, hour: Hour!, minute: Minute!, second: Second!, latitude: Latitude, longitude: Longitude, altitude: Int(Altitude), speed: Int(Speed), orientation: Orientation, satellites: Satellites, accuracy: Accuracy, status: Status, networkType: NetworkType, mcc: MCC, mnc: MNC, lac: LAC, cid: CID, batteryLevel: BatteryLevel, eventCode: EventCode, reportDate: ReportDate,gpsStatus: GpsStatus,errorLocation: errorLocation!, context: CoreDataStack.shared().context)
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
                    return LocationReportInfo(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, latitude: 0, longitude: 0, altitude: 0, speed: 0, orientation: 0, satellites: 0, accuracy: 0, status: "P", networkType: "GPS", mcc: 0, mnc: 0, lac: 0, cid: 0, batteryLevel: 0, eventCode: 0, reportDate: Date(), gpsStatus: "GPS",errorLocation: "", context: CoreDataStack.shared().context)
                }
            return lastLocationReport
        }
        catch
        {
            return LocationReportInfo(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, latitude: 0, longitude: 0, altitude: 0, speed: 0, orientation: 0, satellites: 0, accuracy: 0, status: "P", networkType: "GPS", mcc: 0, mnc: 0, lac: 0, cid: 0, batteryLevel: 0, eventCode: 0, reportDate: Date(), gpsStatus: "GPS",errorLocation: "", context: CoreDataStack.shared().context)
        }
    }
    
    public func checkIfExistsLocationReport() -> Bool
    {
        do
        {
            guard let last = try CoreDataStack.shared().fetchLocationReport(nil, entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
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
