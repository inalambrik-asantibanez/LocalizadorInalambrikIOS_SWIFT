//
//  DeviceUtilities.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/23/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit

class DeviceUtilities
{
    class func shared() -> DeviceUtilities {
        struct Singleton {
            static var shared = DeviceUtilities()
        }
        return Singleton.shared
    }
    
    
    func getNetworkType() -> String
    {
        
        let netWorkType = "RED"
        return netWorkType
    }
    
    func getBatteryStatus() -> Float
    {
        var batteryStatus: Float = 0
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryStatus = UIDevice.current.batteryLevel * 100
        return batteryStatus
    }
    
    func convertDateTimeToString(_ date: Date,_ format: String) -> String
    {
        var dateTimeString:String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateTimeString = dateFormatter.string(from: date)
        return dateTimeString
    }
    
    func convertStringToDateTime(_ date: String,_ time: String) -> Date
    {
        let dateFormat = "yyyy/MM/dd HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let stringDateTime = date+" "+time
        let stringConvertedToDateTime = dateFormatter.date(from:stringDateTime)
        return stringConvertedToDateTime!
    }
    
}
