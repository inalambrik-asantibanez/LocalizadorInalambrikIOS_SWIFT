//
//  QueryUtilities.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class QueryUtilities
{
    class func shared() -> QueryUtilities {
        struct Singleton {
            static var shared = QueryUtilities()
        }
        return Singleton.shared
    }
    
    func saveLocationReport(_ locationReport: LocationReportInfo)
    {
        _ = LocationReportInfo(year: locationReport.year, month: locationReport.month, day: locationReport.day, hour: locationReport.hour, minute: locationReport.minute, second: locationReport.second, latitude: locationReport.latitude, longitude: locationReport.longitude, altitude: locationReport.altitude, speed: locationReport.speed, orientation: locationReport.orientation, satellites: locationReport.satellites, accuracy: locationReport.accuracy, status: locationReport.status!, networkType: locationReport.networkType!, mcc: locationReport.mcc, mnc: locationReport.mnc, lac: locationReport.lac, cid: locationReport.cid, batteryLevel: locationReport.batteryLevel, eventCode: locationReport.eventCode,reportDate: locationReport.reportDate,gpsStatus: locationReport.gpsStatus!,errorLocation: locationReport.locationerror!, context: CoreDataStack.shared().context)
        CoreDataStack.shared().save()
        
    }
    
    func saveUser(_ user: User)
    {
        _ = User(userId: user.userId!, deviceId: user.deviceId!, authorizedDevice: user.authorizedDevice!,deviceIdentifierVendorID: user.deviceIdentifierVendorID!,apple_pn_id:user.apple_pn_id!, context: CoreDataStack.shared().context)
        CoreDataStack.shared().save()
    }
    
    func checkUserAuthorization() -> Bool
    {
        var userAuthorizationStatus = false
        var user: User?
        let predicate = NSPredicate(format:"authorizedDevice == %@ ","1")
        do {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName:User.name)
            if user != nil
            {
                userAuthorizationStatus = true
                DeviceUtilities.shared().printData("Dispositivo encontrado en base")
            }
            else
            {
                DeviceUtilities.shared().printData("Dispositivo no encontrado en base, será creado")
                _ = User(userId: "1", deviceId: "ASD", authorizedDevice: "0", deviceIdentifierVendorID: "", apple_pn_id: "", context: CoreDataStack.shared().context)
                CoreDataStack.shared().save()
            }
        }
        catch
        {
            DeviceUtilities.shared().printData("Error: Dispositivo no encontrado en Base")
        }
        return userAuthorizationStatus
    }
    
    func getUserIMEI() -> String
    {
        var user :User?
        let predicate = NSPredicate(format: "userId == %@ ","1")
        do
        {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName: User.name)
            guard let userIMEI = user?.deviceId! else
            {
                return "IMEI No Encontrado"
            }
            return userIMEI
        }
        catch
        {
            return "IMEI No Encontrado"
        }
        
    }
    
    func getApplePNID() -> String
    {
        var user: User?
        let predicate = NSPredicate(format: " apple_pn_id != %@ ", "")
        do
        {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName: User.name)
            guard let ApplePNID = user?.apple_pn_id! else {
                return "APPLE_ID_NOT_FOUND"
            }
            return ApplePNID
            
        }
        catch
        {
            return "APPLE_ID_NOT_FOUND"
        }
    }
    
    func getLocationReportsByStatusCount(_ predicate: NSPredicate) -> Int
    {
        var locationReportCount = -1
        var locationReports : [LocationReportInfo]?
        do{
            try locationReports = CoreDataStack.shared().fetchLocationReports(predicate,LocationReportInfo.name,0)
            if locationReports != nil
            {
                DeviceUtilities.shared().printData("Reportes encontrados")
                locationReportCount = (locationReports?.count)!
            }
            else
            {
                DeviceUtilities.shared().printData("No Hay Reportes encontrados")
                locationReportCount = -1
            }
        }
        catch{
            DeviceUtilities.shared().printData("No hay Reportes encontrados")
            locationReportCount = -1
        }
        
        return locationReportCount
    }
}
