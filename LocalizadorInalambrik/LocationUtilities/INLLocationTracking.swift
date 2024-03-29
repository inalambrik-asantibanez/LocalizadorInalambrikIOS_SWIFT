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
        DeviceUtilities.shared().printData("Location retrieve successfully: FechaActual=\(Date().preciseLocalDateTime)")
        DeviceUtilities.shared().printData("new datetime=\(recentLocation.timestamp)")
        DeviceUtilities.shared().printData("new latitude=\(recentLocation.coordinate.latitude)")
        DeviceUtilities.shared().printData("new longitude=\(recentLocation.coordinate.longitude)")
        
        let existLastLocationReport = LocationUtilities.shared().checkIfExistsLocationReport()
        if(existLastLocationReport)
        {
            DeviceUtilities.shared().printData("Location exists last report on DB")
            let lastLocationReport = LocationUtilities.shared().getLastLocationInfo()
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationReport.latitude), longitude: CLLocationDegrees(lastLocationReport.longitude)), altitude: CLLocationDistance(lastLocationReport.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), timestamp: lastLocationReport.reportDate)
            
            let DifferencesTwoDatesInSeconds = QueryUtilities.shared().getDifferenceBetweenDates(dateFrom: currentLocation.timestamp, dateTo: recentLocation.timestamp)
            DeviceUtilities.shared().printData("Difference between two dates in seconds \(DifferencesTwoDatesInSeconds)")
            if(Int(abs(recentLocation.coordinate.latitude)) != 0 && Int(abs(recentLocation.coordinate.longitude)) != 0 && Int(abs(DifferencesTwoDatesInSeconds)) >= 45)
            {
                DeviceUtilities.shared().printData("Se guarda reporte en BD despues de haber buscado ubicaci?n valida ")
                LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(recentLocation,"V")
                let lastLocationReportGotten = LocationUtilities.shared().getLastLocationInfo()
                DeviceUtilities.shared().printData("LR Reporte Guardado En varios Reportes Fecha:  \(lastLocationReportGotten.reportDate.preciseLocalDateTime), Latitude:  \(lastLocationReportGotten.latitude) Longitude:  \(lastLocationReportGotten.longitude)")
                //manager.startWaitTimer()
            }
            else
            {
                DeviceUtilities.shared().printData("La ubicacion encontrada no cumple las condiciones ")
            }
        }
        else
        {
            DeviceUtilities.shared().printData("Se guarda reporte en BD como primer reporte")
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(recentLocation,"V")
            let lastLocationOnFirstReport = LocationUtilities.shared().getLastLocationInfo()
            DeviceUtilities.shared().printData("LR Reporte Guardado En Primer Reporte Fecha:  \(lastLocationOnFirstReport.reportDate.preciseLocalDateTime), Latitude:  \(lastLocationOnFirstReport.latitude) Longitude:  \(lastLocationOnFirstReport.longitude)")
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationOnFirstReport.latitude), longitude: CLLocationDegrees(lastLocationOnFirstReport.longitude)), altitude: CLLocationDistance(lastLocationOnFirstReport.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationOnFirstReport.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationOnFirstReport.accuracy), timestamp: lastLocationOnFirstReport.reportDate)
        }
        //Update UI in case is foreground
        DispatchQueue.main.async {
            DeviceUtilities.shared().printData("LOCATION REPORT Pantalla actualizada a :  FechaActual=\(Date().preciseLocalDateTime)")
            NotificationCenter.default.post(name: .refreshUILastReport, object: nil)
        }
    }
    
    func scheduledLocationManager(_ manager: INLLocationManager, didFailWithError error: Error)
    {
        let nullCoordinates = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let locationNull = CLLocation.init(coordinate: nullCoordinates, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp:convertToDate(dateString: Date().preciseLocalDateTime) )
        DeviceUtilities.shared().printData("Location Error \(error.localizedDescription)")
        let existLastLocationReport = LocationUtilities.shared().checkIfExistsLocationReport()
        if(existLastLocationReport)
        {
            let lastLocationReport = LocationUtilities.shared().getLastLocationInfo()
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationReport.latitude), longitude: CLLocationDegrees(lastLocationReport.longitude)), altitude: CLLocationDistance(lastLocationReport.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationReport.accuracy), timestamp: lastLocationReport.reportDate)
            let DifferencesTwoDatesInSeconds = QueryUtilities.shared().getDifferenceBetweenDates(dateFrom: currentLocation.timestamp, dateTo: locationNull.timestamp)
            if(Int(abs(DifferencesTwoDatesInSeconds)) >= 30)
            {
                DeviceUtilities.shared().printData("Se guarda reporte en BD 0.0 con fecha \(Date().preciseLocalDateTime)")
                LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(locationNull,"I",error.localizedDescription)
                DeviceUtilities.shared().printData("LR Reporte Guardado En Varios Reportes por error Fecha:  \(lastLocationReport.reportDate.preciseLocalDateTime), Latitude:  \(lastLocationReport.latitude) Longitude:  \(lastLocationReport.longitude)")
                manager.startWaitTimerOnLocationError()
            }
            else
            {
                DeviceUtilities.shared().printData("La ubicacion encontrada no cumple las condiciones cuando hay error")
            }
        }
        else
        {
            DeviceUtilities.shared().printData("Se guarda reporte en BD como primer reporte en error ")
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(locationNull,"I",error.localizedDescription)
            let lastLocationOnFirstReportError = LocationUtilities.shared().getLastLocationInfo()
            DeviceUtilities.shared().printData("LR Reporte Guardado En Primer Reporte por error Fecha:  \(lastLocationOnFirstReportError.reportDate.preciseLocalDateTime), Latitude:  \(lastLocationOnFirstReportError.latitude) Longitude:  \(lastLocationOnFirstReportError.longitude)")
            currentLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLocationOnFirstReportError.latitude), longitude: CLLocationDegrees(lastLocationOnFirstReportError.longitude)), altitude: CLLocationDistance(lastLocationOnFirstReportError.altitude), horizontalAccuracy: CLLocationAccuracy(lastLocationOnFirstReportError.accuracy), verticalAccuracy: CLLocationAccuracy(lastLocationOnFirstReportError.accuracy), timestamp: lastLocationOnFirstReportError.reportDate)
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
        var locationReports: [LocationReportInfo]?
        DeviceUtilities.shared().printData("Recopilando reportes pendientes para ser enviados")
        do
        {
            try locationReports = CoreDataStack.shared().fetchLocationReports(NSPredicate(format: " status == %@ ", "P"), LocationReportInfo.name,sorting: NSSortDescriptor(key: "reportDate", ascending: true),ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)
            
            let pendingLocationReportsCount = locationReports?.count
            if(pendingLocationReportsCount == 0)
            {
                DeviceUtilities.shared().printData("No Hay reportes pendientes que enviar")
                return
            }
            
            if (!Reachability.shared.isConnectedToNetwork()){
                DeviceUtilities.shared().printData("No Hay conexión a Internet disponible para enviar los reportes")
                return
            }
            
            var lastReportSentOK = true
            var notSentReportCount = 0
            
            DeviceUtilities.shared().printData("Maxima cantidad de reportes pendientes a enviar=\(ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)")
            for locationReport in locationReports!
            {
                if(lastReportSentOK)
                {
                     DeviceUtilities.shared().printData("LR Reporte a enviar=\(locationReport.reportDate.preciseLocalDateTime)")
                    Client.shared().sendPendingLocationReport(locationReport)
                    {
                        (sendLocationResp, error) in
                        
                        if sendLocationResp == nil && error == nil
                        {
                            DeviceUtilities.shared().printData("error no hay conexion a internet al tratar de enviar el reporte")
                            lastReportSentOK = false
                        }
                        
                        if let error = error
                        {
                            DeviceUtilities.shared().printData("error consultando el WS=\(error.localizedDescription)")
                            lastReportSentOK = false
                        }
                        
                        //After calling the webservice and this finished then check if there exist a response
                        if let sendLocationResp = sendLocationResp
                        {
                            let reportInterval = sendLocationResp.ReportInterval
                            let errorMessage = sendLocationResp.ErrorMessage
                            
                             DeviceUtilities.shared().printData("Respuestas del webservice")
                             DeviceUtilities.shared().printData("reportInterval=\(reportInterval)")
                             DeviceUtilities.shared().printData("errorMessage=\(errorMessage)")
                            
                            if errorMessage.isEmpty
                            {
                                //Actualiza el reporte a estado Enviado (S)
                                DeviceUtilities.shared().printData("Se va actualizar el reporte a estado Enviado (S)")
                                locationReport.setValue("S", forKey: "status")
                                CoreDataStack.shared().save()
                                
                                DeviceUtilities.shared().printData("Se actualizo el ultimo reporte pendiente a enviado")
                            }
                            else
                            {
                                DeviceUtilities.shared().printData("Se va a marcar el reporte como invalido")
                                lastReportSentOK = false
                                //Primero se actualiza a enviado el reporte para que no se trate de enviar nuevamente
                                //Se marca el reporte con error para luego ser eliminado
                                locationReport.setValue("S", forKey: "status")
                                locationReport.setValue("1", forKey: "reportIsInvalid")
                                CoreDataStack.shared().save()
                            }
                        }
                    }
                }
                
                if(!lastReportSentOK)
                {
                    notSentReportCount += 1
                }
            }
            if(notSentReportCount > 0)
            {
                DeviceUtilities.shared().printData("errorMessage=\(notSentReportCount)")
            }
            
        }
        catch
        {
            DeviceUtilities.shared().printData("No es posible obtener los reportes pendientes ")
        }
        //Update UI in case is foreground
        DispatchQueue.main.async {
            DeviceUtilities.shared().printData("LOCATION REPORT Pantalla actualizada por sending location reports a :  FechaActual=\(Date().preciseLocalDateTime)")
            NotificationCenter.default.post(name: .refreshUILastReport, object: nil)
        }
    }
    
    /*
    func sendPendingLocationReports()
    {
        QueryUtilities.shared().deleteYesterDaySentLocationReports()
        var locationReports: [LocationReportInfo]?
        do
        {
            try locationReports = CoreDataStack.shared().fetchLocationReports(NSPredicate(format: " status == %@ ", "P"), LocationReportInfo.name,sorting: NSSortDescriptor(key: "reportDate", ascending: true),ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)
            
            if (locationReports?.count)! > 0
            {
                var stopSendPendingReports = false
                DeviceUtilities.shared().printData("Maxima cantidad de reportes pendientes a enviar=\(ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)")
                for locationReport in locationReports!
                {
                    if !stopSendPendingReports
                    {
                        DeviceUtilities.shared().printData("LR Reporte a enviar=\(locationReport.reportDate.preciseLocalDateTime)")
                        Client.shared().sendPendingLocationReport(locationReport)
                        {
                            (sendLocationResp, error) in
                            
                            if let error = error
                            {
                                DeviceUtilities.shared().printData("error consultando el WS=\(error.localizedDescription)")
                                var stopSendPendingReports = true
                                return
                            }
                            
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
                                }
                                else
                                {
                                    if errorMessage == "DELETE"
                                    {
                                        //Actualiza el reporte a estado Enviado (S)
                                        DeviceUtilities.shared().printData("Se va a eliminar el reporte por comando DELET")
                                        CoreDataStack.shared().context.delete(locationReport)
                                        CoreDataStack.shared().save()
                                    }
                                    else
                                    {
                                        DeviceUtilities.shared().printData("Existio un error del servidor")
                                    }
                                }
                            }
                        }
                    }
                }
                
                //Update UI in case is foreground
                DispatchQueue.main.async {
                    DeviceUtilities.shared().printData("LOCATION REPORT Pantalla actualizada por sending location reports a :  FechaActual=\(Date().preciseLocalDateTime)")
                    NotificationCenter.default.post(name: .refreshUILastReport, object: nil)
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
    }*/
    
    func sendDeviceConfiguration()
    {
        DeviceUtilities.shared().printData("Recopilando la informacion de la configuracion del dispositivo para ser enviada")
        if (!Reachability.shared.isConnectedToNetwork()){
            DeviceUtilities.shared().printData("No Hay conexión a Internet disponible para enviar la configuracion del dispositivo")
            return
        }
        
        Client.shared().sendDeviceConfiguration()
        {
            (userResponse, error) in
            
            if let error = error
            {
                DeviceUtilities.shared().printData("errorMessage al consultar el ws =\(error)")
            }
            
            if let userResponse = userResponse
            {
                let errorMessage = userResponse.errorMessage
                DeviceUtilities.shared().printData("errorMessage=\(errorMessage)")
                if errorMessage.isEmpty
                {
                    DeviceUtilities.shared().printData("No existio error al mandar la configuracion del dispositivo")
                }
                else
                {
                    DeviceUtilities.shared().printData("Existio error al mandar la configuracion del dispositivo")
                }
            }
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
}

extension Notification.Name
{
    static let refreshUILastReport = Notification.Name("refreshuilastreport")
}
