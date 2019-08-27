//
//  JSONStructures.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/22/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation

struct sendUserRequest:Codable
{
    let device_id:         String
    let email:             String
    let activation_code:   String
    let device_imei:       String
    let device_vendor_id:  String
    let device_brand:      String
    let device_model:      String
    let device_os:         String
    let device_os_version: String
    let app_version:       Float
    let latitude:          Float
    let longitude:         Float
}

struct sendUserResponse : Codable
{
    let request_status : Int
    let request_message: String
    let request_imei:    String
}

struct sendLocationReportRequest : Codable
{
    let OS:           String
    let DeviceId:     String
    let Year:         String
    let Month:        String
    let Day:          String
    let Hour:         String
    let Minute:       String
    let Second:       String
    let Latitude:     String
    let Longitude:    String
    let Altitude:     String
    let Speed:        String
    let Orientation:  String
    let Satellites:   String
    let Accuracy:     String
    let Status:       String
    let NetworkType:  String
    let MCC:          String
    let MNC:          String
    let LAC:          String
    let CID:          String
    let BatteryLevel: String
    let EventCode:    String
}

struct sendLocationReportResponse: Codable
{
    let ReportInterval: String
    let ErrorMessage:   String
}

//It Contains the struct to use in the flickr api
struct userRequestAPI {
    static let APIScheme = "http"
    static let SecureAPIScheme = "https"
    static let APIHost = "soluciones.inalambrik.com.ec"
    static let SendLocationReportAPIHost = "localizador.inalambrik.com.ec"
    static let LocalAPIHost = "192.168.1.214"
    static let RegisterDeviceAPIPath = "/api/registerdevicesd.aspx"
    static let SendLocationReportAPIPath = "/api/savedevicereportsd.aspx"
}
