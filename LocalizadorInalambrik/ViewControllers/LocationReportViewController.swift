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
    @IBOutlet weak var textLocalDateTime: UILabel!
    @IBOutlet weak var textLatitude: UILabel!
    @IBOutlet weak var textLongitude: UILabel!
    @IBOutlet weak var textPrecision: UILabel!
    @IBOutlet weak var textSpeed: UILabel!
    @IBOutlet weak var textSatellites: UILabel!
    @IBOutlet weak var textReportStatus: UILabel!
    @IBOutlet weak var sendLocationReportTest: UIButton!
    
    //Configure the Timer for the infinite BackGroundTask
    var updateTimer: Timer?
    
    //Set as Invalid BackgroundTask
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    //Set background service variables
    var numTries = ConstantsController().NUMBER_OF_TRIES
    var counter = 1
    let interval: Double = ConstantsController().REPORT_INTERVAL
    let initInterval : Double = ConstantsController().INITIAL_INTERVAL
    var initIsActive = true
    
    public var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        showLocationReportInfo()
        
        setLocationManager()
        
        //Send the pending reports
        //sendPendingLocationReports()
        
        //Delete the first N sent reports
        //deleteYesterDaySentLocationReports()
        
        //Add the observer to check the values of the BackGroundTask
        addBackGroundTaskObserver()
        
        //Set Timer for BackGroundTask
        setInitTimerBackGroundTask()
        
        //Register BackGroundTask
        registerBackGroundTask()
        
        sendLocationReportTest.isHidden = true
    }
    
    //Remove the observer when the viewcontroller is closed
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setLocationManager()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
    }
    
    public func showLocationReportInfo()
    {
        let userIMEI = QueryUtilities.shared().getUserIMEI()
        let batteryLevel = DeviceUtilities.shared().getBatteryStatus()
        let networkType = DeviceUtilities.shared().getNetworkType()
        let pendingReports = QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@","P"))
        let sentReports = QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@","S"))
        
        print("pending reports ",pendingReports)
        print("sent reports ",sentReports)
        
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
        
        do{
            guard let locationInfo = try CoreDataStack.shared().fetchLocationReport(nil, entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
                else
            {
                print("NO hay ultimo reporte disponible")
                fechaHora = "No Encontrada"
                latitude = "0.000000"
                longitude = "0.000000"
                precision = "0 mts"
                velocidad = "0 km/h"
                satelites = "0 "
                estado = " "
                self.textLocalDateTime.text = fechaHora
                self.textLatitude.text = latitude
                self.textLongitude.text = longitude
                self.textPrecision.text = precision
                self.textSpeed.text = velocidad
                self.textSatellites.text = satelites
                self.textReportStatus.text = estado
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
        }
        catch{
            
            print("NO hay ultimo reporte disponible")
        }
        self.textLocalDateTime.text = fechaHora
        self.textLatitude.text = latitude
        self.textLongitude.text = longitude
        self.textPrecision.text = precision
        self.textSpeed.text = velocidad
        self.textSatellites.text = satelites
        self.textReportStatus.text = estado
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
                print("Maxima cantidad de reportes pendientes a enviar=",ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)
                print("Numero de reportes pendientes ",locationReports?.count ?? 0)
                for locationReport in locationReports!
                {
                    print("Reporte a enviar=",locationReport.reportDate.preciseLocalDateTime)
                    Client.shared().sendPendingLocationReport(locationReport)
                    {
                        (sendLocationResp, error) in
                        
                        //After calling the webservice and this finished then check if there exist a response
                        if let sendLocationResp = sendLocationResp
                        {
                            let reportInterval = sendLocationResp.ReportInterval
                            let errorMessage = sendLocationResp.ErrorMessage
                            
                            print("Respuestas del webservice")
                            print("reportInterval=",reportInterval)
                            print("errorMessage=",errorMessage)
                            
                            if errorMessage == ""
                            {
                                //Actualiza el reporte a estado Enviado (S)
                                print("Se va actualizar el reporte a estado Enviado (S)")
                                locationReport.setValue("S", forKey: "status")
                                CoreDataStack.shared().save()
                                
                                print("Se actualizo el ultimo reporte pendiente a enviado")
                                DispatchQueue.main.async {
                                    print("Actualizacion del UI")
                                    self.getLastLocationInfo()
                                }
                            }
                            else
                            {
                                print("Existio un error al enviar el reporte")
                            }
                        }
                    }
                }
            }
            else
            {
                print("No hay reportes pendientes de enviar")
            }
        }
        catch {
            print("No es posible obtener los reportes pendientes ")
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
                print("Maximo numero de reportes enviados a eliminar=",ConstantsController().NUMBER_OF_MAX_SENT_REPORTS_TO_DELETE)
                
                print("Borrado de reportes enviados ",locationReports?.count ?? 0)
                for locationReport in locationReports!
                {
                    CoreDataStack.shared().context.delete(locationReport)
                    CoreDataStack.shared().save()
                }
            }
        }
        catch
        {
            print("No hay reportes enviados por eliminar ")
        }
    }
//----------------------------------------------------------------------------------------------------------------------
    
//------------------------------------------------BACKGROUNDTASK METHODS------------------------------------------------
    func addBackGroundTaskObserver()
    {
        print("Tarea agregado el observador")
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    func setInitTimerBackGroundTask()
    {
        print("Timer inicial configurado en ",initInterval, " segundos")
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: initInterval, target: self,
                                           selector: #selector(getLocationReportFetch), userInfo: nil, repeats: false)
    }
    
    func setTimerBackGroundTask()
    {
        print("Timer configurado en ",interval," segundos")
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                           selector: #selector(getLocationReportFetch), userInfo: nil, repeats: true)
        initIsActive = false
    }
    
    func registerBackGroundTask()
    {
        print("Tarea registrada")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Tarea terminada")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    @objc func reinstateBackgroundTask()
    {
        print("Tarea reiniciada")
        if updateTimer != nil && backgroundTask == UIBackgroundTaskInvalid {
            registerBackGroundTask()
        }
    }
    
    @objc func getLocationReportFetch()
    {
        let localDate = Date().preciseLocalDate
        let localTime = Date().preciseLocalTime
        let localDateTime = DeviceUtilities.shared().convertStringToDateTime(localDate, localTime, "yyyy-MM-dd HH:mm:ss")
        let localHour = Int(DeviceUtilities.shared().convertDateTimeToString(localDateTime, "HH"))
        if localHour! > ConstantsController().BEGIN_REPORT_HOUR && localHour! < ConstantsController().END_REPORT_HOUR
        {
            print("Localizador en calendario")
            
            print("Envio de reportes pendientes ",QueryUtilities.shared().getLocationReportsByStatusCount(NSPredicate(format: "status == %@ ", "P")))
            
            //Sending pending reports
            sendPendingLocationReports()
            
            //Delete sent reports to free space on DB
            //deleteYesterDaySentLocationReports()
            
            print("Chequeo de estado de la aplicacion FechaActual=",Date().preciseLocalDateTime)
            switch UIApplication.shared.applicationState
            {
                case .active:
                    print("Activa FechaActual=",Date().preciseLocalDateTime)
                    print("Activar el servicio Ubicacion")
                    locationManager.startUpdatingLocation()
                    break
                
                case .background:
                    print("BackGround FechaActual=",Date().preciseLocalDateTime)
                    print("Activar el servicio Ubicacion")
                    locationManager.startUpdatingLocation()
                    break
                
                case .inactive:
                    break
            }
            if initIsActive
            {
                setTimerBackGroundTask()
            }
            
        }
        else
        {
            print("El localizador esta fuera de calendario")
        }
        
        
    }
}
//-----------------------------------------------------------------------------------------------------------------

//------------------------------------------------LOCATION METHODS------------------------------------------------
extension LocationReportViewController:CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let mostRecentLocation = locations[0]
        
        //print("new datetime",mostRecentLocation.timestamp)
        //print("new latitude",mostRecentLocation.coordinate.latitude)
        //print("new longitude",mostRecentLocation.coordinate.longitude)
        
        print("Intento # ",counter)
        if abs(mostRecentLocation.coordinate.latitude) != 0 && abs(mostRecentLocation.coordinate.longitude) != 0 && counter > numTries
        {
            //Save LocationReport in DB
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(mostRecentLocation,"")
            
            //If the app is active then update the UI
            print("Verifica el estado de la aplicacion al obtener el reporte")
            switch UIApplication.shared.applicationState
            {
                case .active:
                    print("Refresca la pantalla de reportes")
                    showLocationReportInfo()
                    print("Estado Activo Aplicacion")
                    break
                case .background:
                    print("Estado Background Aplicacion")
                    break
                case .inactive:
                    break
            }
            print("Fecha:  \(mostRecentLocation.timestamp.preciseLocalDateTime), Latitude:  \(mostRecentLocation.coordinate.latitude) Longitude:  \(mostRecentLocation.coordinate.longitude)")
            
            print("Servicio de ubicacion apagado")
            locationManager.stopUpdatingLocation()
            print("")
            
            //Reinit the counter
            counter = 0
        }
        counter += 1
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("No puedo obtener la coordenada, esta tuvo error")
        self.locationManager.stopUpdatingLocation()
        self.locationManager.startUpdatingLocation()
    }
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
//------------------------------------------------------------------------------------------------------------------
