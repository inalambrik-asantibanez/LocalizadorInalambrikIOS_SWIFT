//
//  DeviceUtilities.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/23/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit
import CoreTelephony
import CoreLocation

class DeviceUtilities
{
    let telephonyInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()
    let notificationCenter = UNUserNotificationCenter.current()
    
    class func shared() -> DeviceUtilities {
        struct Singleton {
            static var shared = DeviceUtilities()
        }
        return Singleton.shared
    }
    
    func getNetworkType() -> String
    {
        return "GPS"
    }
    
    func getBatteryStatus() -> Float
    {
        var batteryStatus: Float = 0
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryStatus = UIDevice.current.batteryLevel * 100
        return batteryStatus
    }
    
    func getLocationServicesStatus()->Bool{
        if CLLocationManager.authorizationStatus() == .denied{
            return false
        }else{
            return true
        }
    }
    
    func getNotificationServiceStatus() -> Bool
    {
        var notificationServiceStatus = false
        notificationCenter.getNotificationSettings()
        {
            (settings) in
            
            switch settings.authorizationStatus
            {
                case .authorized, .provisional:
                  notificationServiceStatus = true
                case .denied:
                  notificationServiceStatus = false
                case .notDetermined:
                  notificationServiceStatus = false
            }
        }
        return notificationServiceStatus
    }
    
    func getCurrentDeviceDateTime() -> String
    {
        return Date().preciseLocalDateTime
    }
        
    func convertDateTimeToString(_ date: Date,_ format: String) -> String
    {
        var dateTimeString:String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateTimeString = dateFormatter.string(from: date)
        return dateTimeString
    }
    
    func convertStringToDateTime(_ date: String,_ time: String, _ format: String ) -> Date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let stringDateTime = date+" "+time
        guard let stringConvertedToDateTime = dateFormatter.date(from:stringDateTime)
        else
        {
            return Date()
        }
        return stringConvertedToDateTime
    }
    
    func printData(_ message: String)
    {
        print(message,separator: "",terminator: "\n")
    }
    
    
}
