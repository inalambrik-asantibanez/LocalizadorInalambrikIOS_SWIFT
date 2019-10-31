//
//  LocationBackgroundServiceTask.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 10/28/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit

class LocationBackgroundServiceTask
{
    //Configure the Timer for the infinite BackGroundTask
    var updateTimer: Timer?
    
    //Set as Invalid BackgroundTask
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    //Set background service variables
    let interval: Double = ConstantsController().REPORT_INTERVAL
    let initInterval : Double = ConstantsController().INITIAL_INTERVAL
    var initIsActive = false
    
    class func shared() -> LocationBackgroundServiceTask
    {
        struct Singleton {
            static var shared = LocationBackgroundServiceTask()
        }
        return Singleton.shared
    }
    
    func addBackGroundTaskObserver()
    {
        DeviceUtilities.shared().printData("Tarea que mantiene el hilo principal agregado el observador")
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc func reinstateBackgroundTask()
    {
        DeviceUtilities.shared().printData("Tarea que mantiene el hilo principal reiniciada")
        if updateTimer != nil && backgroundTask == UIBackgroundTaskInvalid {
            registerBackGroundTask()
        }
    }
    
    func registerBackGroundTask()
    {
        DeviceUtilities.shared().printData("Tarea registrada")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        DeviceUtilities.shared().printData("Tarea terminada")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    
    //Setea el primer intervalo de reporte basado en preferencia
    func setInitTimerBackGroundTask()
    {
        DeviceUtilities.shared().printData("Timer inicial configurado en \(initInterval)")
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: initInterval, target: self,
                                           selector: #selector(getFirstLocationReportFetch), userInfo: nil, repeats: false)
    }
    
    //Activa la tarea que obtiene el primer reporte
    @objc func getFirstLocationReportFetch()
    {
        let localDate = Date().preciseLocalDate
        let localTime = Date().preciseLocalTime
        let localDateTime = DeviceUtilities.shared().convertStringToDateTime(localDate, localTime, "yyyy-MM-dd HH:mm:ss")
        let localHour = Int(DeviceUtilities.shared().convertDateTimeToString(localDateTime, "HH"))
        if localHour! > ConstantsController().BEGIN_REPORT_HOUR && localHour! < ConstantsController().END_REPORT_HOUR
        {
            DeviceUtilities.shared().printData("Localizador en calendario")
            DeviceUtilities.shared().printData("Chequeo de estado de la aplicacion FechaActual=\(Date().preciseLocalDateTime)")
            switch UIApplication.shared.applicationState
            {
            case .active:
               // NotificationCenter.default.post(name: .checkLocationPermissions, object: nil) //checkUsersLocationServicesAuthorization()
                DeviceUtilities.shared().printData("Activa FechaActual=\(Date().preciseLocalDateTime)")
                DeviceUtilities.shared().printData("ACTIVO Activar el servicio Ubicacion")
                DeviceUtilities.shared().printData("Actualizar la pantalla ")
                NotificationCenter.default.post(name: .refreshUI, object: nil) //showLocationReportInfo()
                LocationServiceTask.shared().startUpdatingLocation()
                break
                
            case .background:
                DeviceUtilities.shared().printData("BackGround FechaActual=\(Date().preciseLocalDateTime)")
                DeviceUtilities.shared().printData("BACKGROUND Activar el servicio Ubicacion")
                LocationServiceTask.shared().startUpdatingLocation()
                break
                
            case .inactive:
                break
            }
            initIsActive = true
        }
        else
        {
            DeviceUtilities.shared().printData("El localizador esta fuera de calendario")
        }
    }
    
    func addSendFirstReportObserver()
    {
        DeviceUtilities.shared().printData("Registro Observer Envio del primer reporte")
        NotificationCenter.default.addObserver(self, selector: #selector(sendFirstReport), name: Notification.Name.sendFirstReport, object: nil)
    }
    
    @objc func sendFirstReport()
    {
        DeviceUtilities.shared().printData("Envio primer Reporte y initIsActive \(initIsActive)")
        if UIApplication.shared.applicationState == .active && initIsActive
        {
            DeviceUtilities.shared().printData("Envio primer Reporte")
            sendPendingLocationReports()
            initIsActive = false
        }
    }
    
    func addSetLocationReportInterval()
    {
        DeviceUtilities.shared().printData("addSetLocationReportInterval Registro Observer timer del intervalo de reporte")
        NotificationCenter.default.addObserver(self, selector: #selector(setTimerBackGroundTask), name: Notification.Name.setIntervalRep, object: nil)
    }
    
    @objc func setTimerBackGroundTask()
    {
        DeviceUtilities.shared().printData("setTimerBackGroundTask Timer configurado en \(interval), segundos")
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                           selector: #selector(getLocationReportFetch), userInfo: nil, repeats: false)
    }
    
    @objc func getLocationReportFetch()
    {
        let localDate = Date().preciseLocalDate
        let localTime = Date().preciseLocalTime
        let localDateTime = DeviceUtilities.shared().convertStringToDateTime(localDate, localTime, "yyyy-MM-dd HH:mm:ss")
        let localHour = Int(DeviceUtilities.shared().convertDateTimeToString(localDateTime, "HH"))
        if localHour! > ConstantsController().BEGIN_REPORT_HOUR && localHour! < ConstantsController().END_REPORT_HOUR
        {
            //NotificationCenter.default.post(name: .checkLocationPermissions, object: nil) //checkUsersLocationServicesAuthorization()
            DeviceUtilities.shared().printData("Localizador en calendario")
            
            DeviceUtilities.shared().printData("Envio de reportes pendientes \(QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@ ", "P")))")
            
            //Sending pending reports
            sendPendingLocationReports()
            
            //Delete sent reports to free space on DB
            deleteYesterDaySentLocationReports()
            
            DeviceUtilities.shared().printData("Chequeo de estado de la aplicacion FechaActual=\(Date().preciseLocalDateTime)")
            DeviceUtilities.shared().printData("Detiene el servicio para un nuevo ciclo")
            LocationServiceTask.shared().stopUpdatingLocation()
            switch UIApplication.shared.applicationState
            {
            case .active:
                DeviceUtilities.shared().printData("Activa FechaActual=\(Date().preciseLocalDateTime)")
                DeviceUtilities.shared().printData("Activar el servicio Ubicacion")
                DeviceUtilities.shared().printData("Actualizar la pantalla ")
                NotificationCenter.default.post(name: .refreshUI, object: nil) //showLocationReportInfo()
                LocationServiceTask.shared().startUpdatingLocation()
                break
                
            case .background:
                DeviceUtilities.shared().printData("BackGround FechaActual=\(Date().preciseLocalDateTime)")
                DeviceUtilities.shared().printData("Activar el servicio Ubicacion")
                LocationServiceTask.shared().startUpdatingLocation()
                break
                
            case .inactive:
                break
            }
        }
        else
        {
            DeviceUtilities.shared().printData("El localizador esta fuera de calendario")
        }
    }
    
    func sendPendingLocationReports()
    {
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
                                NotificationCenter.default.post(name: .refreshUI, object: nil)
                                /*DispatchQueue.main.async {
                                    print("Actualizacion del UI",separator: "",terminator: "\n")
                                    self.getLastLocationInfo()
                                }*/
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
        NotificationCenter.default.post(name: .refreshUI, object: nil)//showLocationReportInfo()
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
}
