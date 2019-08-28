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

class DeviceUtilities
{
    let telephonyInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()
    
    class func shared() -> DeviceUtilities {
        struct Singleton {
            static var shared = DeviceUtilities()
        }
        return Singleton.shared
    }
    
    func getNetworkType() -> String
    {
        /*guard let netWorkType = telephonyInfo.currentRadioAccessTechnology
        else
        {
            return ""
        }*/
        return "GPS" //netWorkType
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
    
}
