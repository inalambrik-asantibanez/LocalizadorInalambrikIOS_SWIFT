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
    
    @IBOutlet weak var labelIMEI: UILabel!
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var labelNetworkType: UILabel!
    @IBOutlet weak var labelPendingReports: UILabel!
    @IBOutlet weak var labelLSentReports: UILabel!
    
    @IBOutlet weak var labelDateTime: UILabel!
    @IBOutlet weak var labelLatitude: UILabel!
    @IBOutlet weak var labelLongitude: UILabel!
    @IBOutlet weak var labelPrecision: UILabel!
    @IBOutlet weak var labelSpeed: UILabel!
    @IBOutlet weak var labelNumberOfSatellites: UILabel!
    @IBOutlet weak var labelStatus: UILabel!
    
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
    
    override func viewWillAppear(_ animated: Bool)
    {
        /*showLocationReportInfo()
        sendPendingLocationReports()
        INLLocationTracking.shared().startLocationTracking()*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        if #available(iOS 12.0, *)
        {
            if self.traitCollection.userInterfaceStyle == .dark
            {
                labelIMEI.textColor = UIColor.black
                labelBattery.textColor = UIColor.black
                labelNetworkType.textColor = UIColor.black
                labelPendingReports.textColor = UIColor.black
                labelLSentReports.textColor = UIColor.black
                labelDateTime.textColor = UIColor.black
                labelLatitude.textColor = UIColor.black
                labelLongitude.textColor = UIColor.black
                labelPrecision.textColor = UIColor.black
                labelSpeed.textColor = UIColor.black
                labelNumberOfSatellites.textColor = UIColor.black
                labelStatus.textColor = UIColor.black
            }
        }
        //Observer to refresh the ui
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidBecomeActive),name: .UIApplicationDidBecomeActive,object: nil)
               
        //Observer to refresh the last report saved in DB
        NotificationCenter.default.addObserver(self, selector: #selector(refreshLastReportUI), name: .refreshUILastReport , object: nil)
        
        sendLocationReportTest.isHidden = true
        textSentReports.isHidden = true
        labelSentReports.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showLocationReportInfo()
        
        //Send the pending reports
        sendPendingLocationReports()
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
    
    @objc func refreshUI()
       {
           if UIApplication.shared.applicationState == .active
           {
               DeviceUtilities.shared().printData("Pantalla Refrescada")
               showLocationReportInfo()
           }
       }

//------------------------------------------------LOCATION REPORT METHODS-----------------------------------------------
    func sendPendingLocationReports()
    {
        var locationReports: [LocationReportInfo]?
        DeviceUtilities.shared().printData("Recopilando reportes pendientes")
        do
        {
            try locationReports = CoreDataStack.shared().fetchLocationReports(NSPredicate(format: " status == %@ ", "P"), LocationReportInfo.name,sorting: NSSortDescriptor(key: "reportDate", ascending: true),ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)
            
            let pendingLocationReportsCount = locationReports?.count
            if(pendingLocationReportsCount == 0)
            {
                return
            }
            
            if (locationReports?.count)! > 0
            {
                var stopSendPendingReports = false
                //let group = DispatchGroup()
                //let queue = DispatchQueue.global(qos: .userInteractive)
                //let semaphore = DispatchSemaphore(value: 1)
                
                DeviceUtilities.shared().printData("Maxima cantidad de reportes pendientes a enviar=\(ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND)")
                for locationReport in locationReports!
                {
                    DeviceUtilities.shared().printData("Enviando reporte")
                    //group.enter()
                    //semaphore.wait()
                    if !stopSendPendingReports
                    {
                        //group.enter()
                        DeviceUtilities.shared().printData("LR Reporte a enviar=\(locationReport.reportDate.preciseLocalDateTime)")
                        Client.shared().sendPendingLocationReport(locationReport)
                        {
                            (sendLocationResp, error) in
                            
                            if let error = error
                            {
                                DeviceUtilities.shared().printData("error consultando el WS=\(error.localizedDescription)")
                                stopSendPendingReports = true
                                //return
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
                                    if errorMessage == "DELETE"
                                    {
                                        //Actualiza el reporte a estado Enviado (S)
                                        DeviceUtilities.shared().printData("Se va a eliminar el reporte")
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
                        //semaphore.signal()
                        //group.leave()
                    }
                }
                DispatchQueue.main.async {
                    print("Actualizacion del UI",separator: "",terminator: "\n")
                    self.showLocationReportInfo()
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

extension Date
{
    static var yesterday: Date { return Date().dayBefore }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
    
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
