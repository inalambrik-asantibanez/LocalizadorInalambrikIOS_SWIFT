//
//  client.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/22/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import UIKit

class Client {
    
    var session = URLSession.shared
    private var tasks: [String: URLSessionDataTask] = [:]
    
    class func shared() -> Client {
        struct Singleton {
            static var shared = Client()
        }
        return Singleton.shared
    }
}

extension Client
{
    
    func sendAuthorization(_ activationCode: String,_ Apple_pn_id: String, completion: @escaping (_ result: sendUserResponse?, _ error: Error?) -> Void)
    {
        let deviceUID = UIDevice.current.identifierForVendor!.uuidString
        let deviceOSVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.name
        
        let sendRequest = sendUserRequest(device_id: deviceUID, email: "", activation_code: activationCode, device_imei: deviceUID, device_vendor_id: deviceUID, device_brand: deviceModel, device_model: deviceModel, device_os: "IOS", device_os_version: deviceOSVersion, app_version: Float(ConstantsController().APP_VERSION), latitude: 0.0, longitude: 0.0, device_phone_number: "", device_phone_area_code: "", verify_phone_number_only: false, firebase_id: "", apple_pn_id: Apple_pn_id,device_firebase_unique_id: "")
        
        let jsonData = try! JSONEncoder().encode(sendRequest)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        DeviceUtilities.shared().printData(jsonString)
        
        _ = taskForPOSTRESTMethod("POST","REGISTER_DEVICE",jsonString) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Could not retrieve data."]
                completion(nil, NSError(domain: "taskForPOSTMethod", code: 1, userInfo: userInfo))
                return
            }
            
            do {
                let userResponseParser = try JSONDecoder().decode(sendUserResponse.self, from: data)
                completion(userResponseParser, nil)
            } catch {
                print("\(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func sendPendingLocationReport(_ locationReport: LocationReportInfo, completion: @escaping (_ result: sendLocationReportResponse?, _ error: Error?)-> Void)
    {
        let deviceId              = QueryUtilities.shared().getUserIMEI()
        let yearCharacter         = String(locationReport.year)
        let monthCharacter        = String(locationReport.month)
        let dayCharacter          = String(locationReport.day)
        let hourCharacter         = String(locationReport.hour)
        let minuteCharacter       = String(locationReport.minute)
        let secondCharacter       = String(locationReport.second)
        let latitudeCharacter     = String(locationReport.latitude)
        let longitudeCharacter    = String(locationReport.longitude)
        let altitudeCharacter     = String(locationReport.altitude)
        let speedCharacter        = String(locationReport.speed)
        let orientationCharacter  = String(locationReport.orientation)
        let satellitesCharacter   = String(locationReport.satellites)
        let accuracyCharacter     = String(locationReport.accuracy)
        let statusCharacter       = locationReport.gpsStatus
        let networkTypeCharacter  = locationReport.networkType
        let mCCCharacter          = String(locationReport.mcc)
        let mNCCharacter          = String(locationReport.mnc)
        let lACCharacter          = String(locationReport.lac)
        let cIDCharacter          = String(locationReport.cid)
        let batteryLevelCharacter  = String(locationReport.batteryLevel)
        let eventCodeCharacter    = String(locationReport.eventCode)
        
        let sendLocationReport = sendLocationReportRequest(OS: "IOS", DeviceId: deviceId, Year: yearCharacter, Month: monthCharacter, Day: dayCharacter, Hour: hourCharacter, Minute: minuteCharacter, Second: secondCharacter, Latitude: latitudeCharacter, Longitude: longitudeCharacter, Altitude: altitudeCharacter, Speed: speedCharacter, Orientation: orientationCharacter, Satellites: satellitesCharacter, Accuracy: accuracyCharacter, Status: statusCharacter!, NetworkType: networkTypeCharacter!, MCC: mCCCharacter, MNC: mNCCharacter, LAC: lACCharacter, CID: cIDCharacter, BatteryLevel: batteryLevelCharacter, EventCode: eventCodeCharacter,ActivityRecognitionCode: "")
        
        let jsonData = try! JSONEncoder().encode(sendLocationReport)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        DeviceUtilities.shared().printData(jsonString)
        
        _ = taskForPOSTRESTMethod("POST", "", jsonString){ (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Could not retrieve data."]
                completion(nil, NSError(domain: "taskForPOSTMethod", code: 2, userInfo: userInfo))
                return
            }
            
            do
            {
                let respo = try JSONDecoder().decode(sendLocationReportResponse.self, from: data)
                completion(respo, nil)
            } catch {
                DeviceUtilities.shared().printData("Error obtenido \(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }

    func taskForPOSTRESTMethod(
        _ method                 : String,
        _ useType                : String,
        _ parameters             : String,
        completionHandlerForPOSTREST: @escaping (_ result: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request: NSMutableURLRequest!
        
        request = NSMutableURLRequest(url: buildURLFromParameters(useType))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters.data(using: String.Encoding.utf8)
        DeviceUtilities.shared().printData("Request=\(request)")
        
        showActivityIndicator(true)
        
        //It makes the request
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                self.showActivityIndicator(false)
                DeviceUtilities.shared().printData("Existe un error=\(error)")
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForPOSTREST(nil, NSError(domain: "completionHandlerForPOST", code: 1, userInfo: userInfo))
            }
            
            if let error = error {
                
                // the request got canceled
                if (error as NSError).code == URLError.cancelled.rawValue {
                    completionHandlerForPOSTREST(nil, nil)
                } else {
                    DeviceUtilities.shared().printData("Existió un error al conectarse al servidor")
                    sendError("Existió un error al conectarse al servidor: \(error.localizedDescription)")
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Su codigo de respuesta es diferente de 200")
                return
            }
            
            guard let data = data else {
                DeviceUtilities.shared().printData("No existe respuesta devuelta del servidor")
                sendError("No existe respuesta devuelta del servidor")
                
                return
            }
            
            self.showActivityIndicator(false)
            
            //It parses the data and use the data (happens in completion handler)
            DeviceUtilities.shared().printData("Si logro consultar el webservice ")
            completionHandlerForPOSTREST(data, nil)
            
        }
        
        //It starts the request
        task.resume()
        
        return task
    }
    
    //It shows activity indicator
    private func showActivityIndicator(_ show: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
    
    //It helps for Creating a URL from Parameters
    private func buildURLFromParameters(_ useType: String) -> URL {
        
        var components = URLComponents()
        components.scheme = userRequestAPI.APIScheme
        if ConstantsController().HTTP_SECURE
        {
            components.scheme = userRequestAPI.SecureAPIScheme
        }
        components.host = userRequestAPI.LocalAPIHost
        if ConstantsController().PRODUCTION_MODE
        {
            components.host = userRequestAPI.APIHost
        }
        
        components.path = userRequestAPI.SendLocationReportAPIPath
        if useType == "REGISTER_DEVICE"
        {
            components.path = userRequestAPI.RegisterDeviceAPIPath
        }
        DeviceUtilities.shared().printData("Components=\(components)")
        return components.url!
    }
}
