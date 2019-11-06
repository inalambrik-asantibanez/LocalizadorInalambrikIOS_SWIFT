//
//  INLLocationTracking.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 10/28/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class INLLocationTracking: NSObject {
    
    //Constant
    let timeInternal = ConstantsController().REPORT_INTERVAL
    static let accuracy = 200
    var counter = 1
    let numTries = ConstantsController().NUMBER_OF_TRIES
    
    
    var manager: INLLocationManager!
    private static var privateShared : INLLocationTracking?
    var currentLocation : CLLocation
    
    override init()
    {
        currentLocation = CLLocation(latitude: 0, longitude: 0)
        super.init()
        
        manager = INLLocationManager(delegate: self)
    }
    
    
    class func shared() -> INLLocationTracking {
        guard let uwShared = privateShared else {
            privateShared = INLLocationTracking()
            return privateShared!
        }
        return uwShared
    }
    
    class func destroy() {
        privateShared = nil
    }
    
    
    func isLocationServiceEnable()->Bool{
        if CLLocationManager.authorizationStatus() == .denied{
            return false
        }else{
            return true
        }
    }
    
    
    func showLocationAlert(){
        print("Please enalble location service")
    }
    
    func startLocationTracking(){
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||  CLLocationManager.authorizationStatus() == .authorizedWhenInUse
        {
            manager.startUpdatingLocation(interval: timeInternal, acceptableLocationAccuracy: 200)
        }
        else if CLLocationManager.authorizationStatus() == .denied
        {
            DeviceUtilities.shared().printData("Location service is disable")
        }
        else
        {
            if #available(iOS 13.0, *)
            {
                manager.requestWhenInUseAuthorization()
            }
            else
            {
                manager.requestAlwaysAuthorization()
            }
        }
    }
    
    func stopLocationTracking(){
        manager.stopUpdatingLocation()
    }
}


extension INLLocationTracking:INLLocationManagerDelegate{
    
    func scheduledLocationManager(_ manager: INLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let recentLocation = locations.last!
        
        DeviceUtilities.shared().printData("new datetime=\(recentLocation.timestamp)")
        DeviceUtilities.shared().printData("new latitude=\(recentLocation.coordinate.latitude)")
        DeviceUtilities.shared().printData("new longitude=\(recentLocation.coordinate.longitude)")
        
        let existLastLocationReport = LocationUtilities.shared().checkIfExistsLocationReport()
        let lastLocationReport = LocationUtilities.shared().getLastLocationInfo()
        if existLastLocationReport
        {
            
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationReport.latitude), longitude: CLLocationDegrees(lastLocationReport.longitude)), altitude: CLLocationDistance(lastLocationReport.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), timestamp: lastLocationReport.reportDate)
        }
        else
        {
            currentLocation = CLLocation(latitude: 0, longitude: 0)
        }
        let DifferencesTwoDatesInSeconds = getDifferenceBetweenDates(dateFrom: currentLocation.timestamp, dateTo: recentLocation.timestamp)
        DeviceUtilities.shared().printData("Difference between two dates in seconds \(DifferencesTwoDatesInSeconds)")
        if(Int(abs(recentLocation.coordinate.latitude)) != 0 && Int(abs(recentLocation.coordinate.longitude)) != 0) && (!existLastLocationReport || DifferencesTwoDatesInSeconds >= 45)
        {
            DeviceUtilities.shared().printData("Location retrive successfully: FechaActual=\(Date().preciseLocalDateTime)")
            //Save LocationReport in DB
            DeviceUtilities.shared().printData("Se guarda reporte en BD despues de haber buscado ubicación")
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(recentLocation,"")
            
            DeviceUtilities.shared().printData("LR Reporte Guardado Fecha:  \(recentLocation.timestamp.preciseLocalDateTime), Latitude:  \(recentLocation.coordinate.latitude) Longitude:  \(recentLocation.coordinate.longitude)")
            
            
            //Send pending locations (Foreground or Background)
            sendPendingLocationReports()
            
            //Update UI in case is foreground
            if(UIApplication.shared.applicationState == .active)
            {
                NotificationCenter.default.post(name: .refreshUILastReport, object: nil)
            }
            
            currentLocation = recentLocation
            
            //Reset Counter
            counter = 1
        }
        counter += 1
        
    }
    
    func scheduledLocationManager(_ manager: INLLocationManager, didFailWithError error: Error)
    {
        let existLastLocationReport = LocationUtilities.shared().checkIfExistsLocationReport()
        let lastLocationReport = LocationUtilities.shared().getLastLocationInfo()
        if existLastLocationReport
        {
            
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationReport.latitude), longitude: CLLocationDegrees(lastLocationReport.longitude)), altitude: CLLocationDistance(lastLocationReport.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), timestamp: lastLocationReport.reportDate)
        }
        else
        {
            currentLocation = CLLocation(latitude: 0, longitude: 0)
        }
        
        DeviceUtilities.shared().printData("Location Error \(error.localizedDescription)")
        let nullCoordinates = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let locationNull = CLLocation.init(coordinate: nullCoordinates, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp:convertToDate(dateString: Date().preciseLocalDateTime) )
        
        let DifferencesTwoDatesInSeconds = getDifferenceBetweenDates(dateFrom: currentLocation.timestamp, dateTo: locationNull.timestamp)
        if(!existLastLocationReport || DifferencesTwoDatesInSeconds >= 45)
        {
            DeviceUtilities.shared().printData("Se guarda reporte en BD 0.0 con fecha \(Date().preciseLocalDateTime)")
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(locationNull,"",error.localizedDescription)
            currentLocation = locationNull
            sendPendingLocationReports()
            manager.startWaitTimerOnLocationError()
            
        }
    }
    
    func scheduledLocationManager(_ manager: INLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .denied{
            DeviceUtilities.shared().printData("Location service is disable...")
            if #available(iOS 13.0,*)
            {
            manager.requestWhenInUseAuthorization()
            }
            else
            {
                manager.requestAlwaysAuthorization()
            }
        }else{
            startLocationTracking()
        }
    }
    
    func convertToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatType.dateWithTime.rawValue // Your date format
        let serverDate: Date = dateFormatter.date(from: dateString)! // according to date format your date string
        return serverDate
    }
    
    /// Date Format type
    enum DateFormatType: String {
        /// Time
        case time = "HH:mm:ss"

        /// Date with hours
        case dateWithTime = "yyyy-MM-dd HH:mm:ss"

        /// Date
        case date = "dd-MMM-yyyy"
    }
    
    func sendPendingLocationReports()
    {
        deleteYesterDaySentLocationReports()
        var locationReports: [LocationReportInfo]?
        do
        {
            try locationReports = CoreDataStack.shared().fetchLocationReports(NSPredicate(format: " status == %@ ", "P"), LocationReportInfo.name,sorting: NSSortDescriptor(key: "reportDate", ascending: true),ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)
            
            if (locationReports?.count)! > 0
            {
                DeviceUtilities.shared().printData("Maxima cantidad de reportes pendientes a enviar=\(ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)")
                for locationReport in locationReports!
                {
                    DeviceUtilities.shared().printData("LR Reporte a enviar=\(locationReport.reportDate.preciseLocalDateTime)")
                    Client.shared().sendPendingLocationReport(locationReport)
                    {
                        (sendLocationResp, error) in
                        
                        //After calling the webservice and this finished then check if there exist a response
                        if let sendLocationResp = sendLocationResp
                        {
                            let reportInterval = sendLocationResp.ReportInterval
                            let errorMessage = sendLocationResp.ErrorMessage
                            
                             DeviceUtilities.shared().printData("Respuestas del webservice")
                             DeviceUtilities.shared().printData("reportInterval=\(reportInterval)")
                             DeviceUtilities.shared().printData("errorMessage=\(errorMessage)")
                            
                            if errorMessage == ""
                            {
                                //Actualiza el reporte a estado Enviado (S)
                                DeviceUtilities.shared().printData("Se va actualizar el reporte a estado Enviado (S)")
                                locationReport.setValue("S", forKey: "status")
                                CoreDataStack.shared().save()
                                DeviceUtilities.shared().printData("Se actualizo el ultimo reporte pendiente a enviado")
                                
                                let nCenter = UNUserNotificationCenter.current()
                                DeviceUtilities.shared().printData("Eliminacion de las notificaciones enviadas")
                                nCenter.removeAllDeliveredNotifications()
                                
                                //Update UI in case is foreground
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .refreshUILastReport, object: nil)
                                }
                            }
                            else
                            {
                                DeviceUtilities.shared().printData("Existio un error al enviar el reporte")
                            }
                        }
                    }
                }
            }
            else
            {
                DeviceUtilities.shared().printData("No hay reportes pendientes de enviar")
            }
        }
        catch {
            DeviceUtilities.shared().printData("No es posible obtener los reportes pendientes ")
        }
    }
    
    func deleteYesterDaySentLocationReports()
    {
        var locationReports: [LocationReportInfo]?
        do
        {
            try locationReports = CoreDataStack.shared().fetchLocationReports(NSPredicate(format: " status == %@ ", "S"), LocationReportInfo.name,sorting: NSSortDescriptor(key: "reportDate", ascending: true),ConstantsController().NUMBER_OF_MAX_SENT_REPORTS_TO_DELETE)
            
            if (locationReports?.count)! > 0
            {
                DeviceUtilities.shared().printData("Maximo numero de reportes enviados a eliminar=\(ConstantsController().NUMBER_OF_MAX_SENT_REPORTS_TO_DELETE)")
                
                DeviceUtilities.shared().printData("Borrado de reportes enviados \(locationReports?.count ?? 0)")
                for locationReport in locationReports!
                {
                    CoreDataStack.shared().context.delete(locationReport)
                    CoreDataStack.shared().save()
                }
            }
        }
        catch
        {
            DeviceUtilities.shared().printData("No hay reportes enviados por eliminar ")
        }
    }
    
    func scheduleLocalNotification(locationReport: LocationReportInfo)
    {
         DeviceUtilities.shared().printData("scheduleLocalNotification create a notification")
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.fireNotification(locationReport: locationReport)
            }
        }
    }
    
    func fireNotification(locationReport: LocationReportInfo)
    {
        DeviceUtilities.shared().printData("Creacion de la notificacion en background")
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Localizador Inalambrik"
        notificationContent.body = "Ubicación encontrada y enviada a las \(locationReport.reportDate.preciseLocalDateTime)"
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "background_location_notification", content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
    func getDifferenceBetweenDates(dateFrom: Date, dateTo: Date) -> Double
    {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([ .second])
        let DTComponents = calendar.dateComponents(unitFlags, from: dateFrom, to: dateTo)
        guard let seconds = DTComponents.second else { return 0 }
        return Double(seconds)
    }
}

extension Notification.Name
{
    static let refreshUILastReport = Notification.Name("refreshuilastreport")
}
