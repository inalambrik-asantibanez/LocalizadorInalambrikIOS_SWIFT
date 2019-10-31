//
//  LocationReportViewController.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/23/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class LocationReportViewController : UIViewController
{
    @IBOutlet weak var textIMEI: UILabel!
    @IBOutlet weak var textBatteryLevel: UILabel!
    @IBOutlet weak var textNetworkType: UILabel!
    @IBOutlet weak var textPendingReports: UILabel!
    @IBOutlet weak var textSentReports: UILabel!
    @IBOutlet weak var labelSentReports: UILabel!
    @IBOutlet weak var textLocalDateTime: UILabel!
    @IBOutlet weak var textLatitude: UILabel!
    @IBOutlet weak var textLongitude: UILabel!
    @IBOutlet weak var textPrecision: UILabel!
    @IBOutlet weak var textSpeed: UILabel!
    @IBOutlet weak var textSatellites: UILabel!
    @IBOutlet weak var textReportStatus: UILabel!
    @IBOutlet weak var sendLocationReportTest: UIButton!
    @IBOutlet weak var textErrorLocation: UILabel!
    
    //Configure the Timer for the infinite BackGroundTask
    //var updateTimer: Timer?
    
    //Set as Invalid BackgroundTask
    //var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    //Set background service variables
    /*let interval: Double = ConstantsController().REPORT_INTERVAL
    let initInterval : Double = ConstantsController().INITIAL_INTERVAL
    var initIsActive = false*/
    
    override func viewWillAppear(_ animated: Bool) {
        
        //Observer to refresh the ui
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidBecomeActive),name: .UIApplicationDidBecomeActive,object: nil)
        
        //Observer to refresh the last report saved in DB
        NotificationCenter.default.addObserver(self, selector: #selector(refreshLastReportUI), name: .refreshUILastReport, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        showLocationReportInfo()
        
        //Send the pending reports
        sendPendingLocationReports()
        
        /*//check Location Permissions
        checkUsersLocationServicesAuthorization()
        
        showLocationReportInfo()
        
        //Add observer to refresh UI
        addRefreshUIObserver()
        
        //Add observer to send the first report found
        addSendFirstReportObserver()
        
        //Add observer to set the location report Interval
        addSetLocationReportInterval()
        
        //Set Timer for BackGroundTask
        setInitTimerBackGroundTask()
        
        //Add the observer to check the values of the BackGroundTask
        addBackGroundTaskObserver()
        
        //Register BackGroundTask
        registerBackGroundTask()*/
        
        sendLocationReportTest.isHidden = true
        textSentReports.isHidden = true
        labelSentReports.isHidden = true
        
        INLLocationTracking.shared().startLocationTracking()
    }
    
    //Remove the observer when the viewcontroller is closed
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationDidBecomeActive()
    {
        DeviceUtilities.shared().printData("applicationDidBecomeActive on viewcontroller")
        self.showLocationReportInfo()
    }
    
    @objc func refreshLastReportUI()
    {
        DeviceUtilities.shared().printData("refreshLastReportUI refresh the last report on viewcontroller")
        self.showLocationReportInfo()
    }
    
    public func showLocationReportInfo()
    {
        DeviceUtilities.shared().printData("showLocationReportInfo")
        
        let userIMEI = QueryUtilities.shared().getUserIMEI()
        let batteryLevel = DeviceUtilities.shared().getBatteryStatus()
        let networkType = DeviceUtilities.shared().getNetworkType()
        let pendingReports = QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@","P"))
        let sentReports = QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@","S"))
        
        self.textIMEI.text = userIMEI
        self.textBatteryLevel.text = String(batteryLevel)
        self.textNetworkType.text = networkType
        self.textPendingReports.text = String(pendingReports)
        self.textSentReports.text = String(sentReports)
        getLastLocationInfo()
    }
    
    public func getLastLocationInfo()
    {
        var fechaHora = ""
        var latitude = ""
        var longitude = ""
        var precision = ""
        var velocidad = ""
        var satelites = ""
        var estado = ""
        var errorLocation = ""
        
        do{
            guard let locationInfo = try CoreDataStack.shared().fetchLocationReport(nil, entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
                else
            {
                DeviceUtilities.shared().printData("NO hay ultimo reporte disponible")
                fechaHora = "No Encontrada"
                latitude = "0.000000"
                longitude = "0.000000"
                precision = "0 mts"
                velocidad = "0 km/h"
                satelites = "0 "
                estado = " "
                errorLocation = ""
                self.textLocalDateTime.text = fechaHora
                self.textLatitude.text = latitude
                self.textLongitude.text = longitude
                self.textPrecision.text = precision
                self.textSpeed.text = velocidad
                self.textSatellites.text = satelites
                self.textReportStatus.text = estado
                self.textErrorLocation.text = errorLocation
                return
            }
            fechaHora = DeviceUtilities.shared().convertDateTimeToString((locationInfo.reportDate),"yyyy-MM-dd HH:mm:ss")
            latitude = NSString(format: "%.6f", locationInfo.latitude) as String
            longitude = NSString(format: "%.6f", locationInfo.longitude) as String
            precision = NSString(format: "%.2f", locationInfo.accuracy) as String
            precision += " mts"
            velocidad = String(locationInfo.speed)
            velocidad += " km/h"
            satelites = String(locationInfo.satellites)
            estado = locationInfo.status == "P" ? "Pendiente" : "Enviado";
            errorLocation = locationInfo.locationerror!
        }
        catch{
            
            DeviceUtilities.shared().printData("NO hay ultimo reporte disponible")
        }
        self.textLocalDateTime.text = fechaHora
        self.textLatitude.text = latitude
        self.textLongitude.text = longitude
        self.textPrecision.text = precision
        self.textSpeed.text = velocidad
        self.textSatellites.text = satelites
        self.textReportStatus.text = estado
        self.textErrorLocation.text = errorLocation
    }
    @IBAction func sendLocationReportAction(_ sender: Any)
    {
    }

//------------------------------------------------LOCATION REPORT METHODS-----------------------------------------------
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
                                DispatchQueue.main.async {
                                    print("Actualizacion del UI",separator: "",terminator: "\n")
                                    self.showLocationReportInfo()
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
        showLocationReportInfo()
    }
    
    /*func deleteYesterDaySentLocationReports()
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
    }*/
//----------------------------------------------------------------------------------------------------------------------
    
//------------------------------------------------BACKGROUNDTASK METHODS------------------------------------------------
    /*func addBackGroundTaskObserver()
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
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "com.so.locationreport", expirationHandler: {self.endBackgroundTask()})
        /*backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }*/
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        DeviceUtilities.shared().printData("endBackgroundTask Se termina la tarea")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    func addRefreshUIObserver()
    {
        DeviceUtilities.shared().printData("Registro Observer Refresh de la pantalla del localizador")
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: Notification.Name.refreshUIfromLocation, object: nil)
    }
    
    @objc func refreshUI()
    {
        if UIApplication.shared.applicationState == .active
        {
            DeviceUtilities.shared().printData("Pantalla Refrescada")
            showLocationReportInfo()
        }
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
                checkUsersLocationServicesAuthorization()
                DeviceUtilities.shared().printData("Activa FechaActual=\(Date().preciseLocalDateTime)")
                DeviceUtilities.shared().printData("ACTIVO Activar el servicio Ubicacion")
                DeviceUtilities.shared().printData("Actualizar la pantalla ")
                showLocationReportInfo()
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
            checkUsersLocationServicesAuthorization()
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
                showLocationReportInfo()
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
    
    func checkUsersLocationServicesAuthorization()
    {
        
        /// Check if user has authorized Total Plus to use Location Services
        if CLLocationManager.locationServicesEnabled()
        {
            switch CLLocationManager.authorizationStatus()
            {

            case .notDetermined:
                // Request when-in-use authorization initially
                // This is the first and the ONLY time you will be able to ask the user for permission
                LocationServiceTask.shared().locationManager?.requestWhenInUseAuthorization()
                break

            case .restricted, .denied:
                // Disable location features

                let alert = UIAlertController(title: "Allow Location Access", message: "Localizador necesita acceder a su ubicación. Encienda los servicios de localización.", preferredStyle: UIAlertController.Style.alert)

                // Button to Open Settings
                alert.addAction(UIAlertAction(title: "Configuración", style: UIAlertAction.Style.default, handler: { action in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                }))
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)

                break

            case .authorizedWhenInUse, .authorizedAlways:
                // Enable features that require location services here.
                print("Full Access")
                break
            }
        }
    }*/
}
//-----------------------------------------------------------------------------------------------------------------

//------------------------------------------------ AUXILIAR METHODS------------------------------------------------
extension Formatter {
    
    static let preciseLocalTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static let preciseLocalDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let preciseLocalDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

extension Date {
    var nanosecond: Int { return Calendar.current.component(.nanosecond,  from: self)   }
    var preciseLocalTime: String {
        return Formatter.preciseLocalTime.string(for: self) ?? ""
    }
    var preciseLocalDate: String {
        return Formatter.preciseLocalDate.string(for: self) ?? ""
    }
    
    var preciseLocalDateTime: String {
        return Formatter.preciseLocalDateTime.string(for: self) ?? ""
    }
}

extension Notification.Name
{
    static let refreshUIfromLocation = Notification.Name("refreshUIfromLocation")
    static let sendFirstReport = Notification.Name("sendFirstReport")
    static let setIntervalRep  = Notification.Name("setLocationReportInterval")
}
//------------------------------------------------------------------------------------------------------------------
