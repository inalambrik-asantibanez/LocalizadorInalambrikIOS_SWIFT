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
        _ = LocationReportInfo(year: locationReport.year, month: locationReport.month, day: locationReport.day, hour: locationReport.hour, minute: locationReport.minute, second: locationReport.second, latitude: locationReport.latitude, longitude: locationReport.longitude, altitude: locationReport.altitude, speed: locationReport.speed, orientation: locationReport.orientation, satellites: locationReport.satellites, accuracy: locationReport.accuracy, status: locationReport.status!, networkType: locationReport.networkType!, mcc: locationReport.mcc, mnc: locationReport.mnc, lac: locationReport.lac, cid: locationReport.cid, batteryLevel: locationReport.batteryLevel, eventCode: locationReport.eventCode,reportDate: locationReport.reportDate,gpsStatus: locationReport.gpsStatus!, context: CoreDataStack.shared().context)
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
                print("Dispositivo encontrado en base")
            }
            else
            {
                print("Dispositivo no encontrado en base, será creado")
                _ = User(userId: "1", deviceId: "ASD", authorizedDevice: "0", deviceIdentifierVendorID: "", apple_pn_id: "", context: CoreDataStack.shared().context)
                CoreDataStack.shared().save()
            }
        }
        catch
        {
            print("Error: Dispositivo no encontrado en Base")
        }
        return userAuthorizationStatus
    }
    
    func getUserIMEI() -> String
    {
        var userIMEI = ""
        var user :User?
        let predicate = NSPredicate(format: "userId == %@ ","1")
        do {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName: User.name)
            if user != nil
            {
                userIMEI = (user?.deviceId)!
            }
            else
            {
                userIMEI = "IMEI No Encontrado"
            }

        }
        catch{
            userIMEI = "IMEI No Encontrado"
        }
        
        return userIMEI
    }
    
    func getApplePNID() -> String
    {
        var ApplePNID = ""
        var user: User?
        let predicate = NSPredicate(format: " apple_pn_id != %@ ", "")
        do
        {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName: User.name)
            ApplePNID = (user?.apple_pn_id)!
        }
        catch
        {
            ApplePNID = "APPLE_PN_NOT_FOUND"
        }
        return ApplePNID
    }
    
    func getLocationReportsByStatusCount(_ predicate: NSPredicate) -> Int
    {
        var locationReportCount = -1
        var locationReports : [LocationReportInfo]?
        do{
            try locationReports = CoreDataStack.shared().fetchLocationReports(predicate,LocationReportInfo.name,0)
            if locationReports != nil
            {
                print("Reportes encontrados")
                locationReportCount = (locationReports?.count)!
            }
            else
            {
                print("No Hay Reportes encontrados")
                locationReportCount = -1
            }
        }
        catch{
            print("No hay Reportes encontrados")
            locationReportCount = -1
        }
        
        return locationReportCount
    }
}
