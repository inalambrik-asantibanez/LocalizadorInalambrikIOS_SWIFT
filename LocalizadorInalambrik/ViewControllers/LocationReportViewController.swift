//
//  LocationReportViewController.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/23/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLocationReportInfo()
    }
    
    public func showLocationReportInfo()
    {
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
        
        do{
            guard let locationInfo = try CoreDataStack.shared().fetchLocationReport(nil, entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
                else
            {
                print("NO Encontro reporte")
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
            fechaHora = DeviceUtilities.shared().convertDateTimeToString((locationInfo.reportDate),"yyyy/MM/dd HH:mm:ss")
            latitude = NSString(format: "%.6f", locationInfo.latitude) as String
            longitude = NSString(format: "%.6f", locationInfo.longitude) as String
            precision = NSString(format: "%.2f", locationInfo.accuracy) as String
            precision += " mts"
            velocidad = String(locationInfo.speed)
            velocidad += " km/h"
            satelites = String(locationInfo.satellites)
            estado = locationInfo.status!
        }
        catch{
            
            print("NO Encontro reporte")
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
        print("Se va enviar un reporte de prueba")
        let reportDate : Date = DeviceUtilities.shared().convertStringToDateTime("2019/08/27","10:57:20")
        _ = LocationReportInfo(year: 2019, month: 8, day: 27, hour: 10, minute: 57, second: 20, latitude: -2.1705792, longitude:-79.9451913, altitude: 10, speed: 2, orientation: 30, satellites: 5, accuracy: 10.5, status: "P", networkType: "5G", mcc: 5, mnc: 4, lac: 6, cid: 2, batteryLevel: 90, eventCode: 1, reportDate: reportDate, context: CoreDataStack.shared().context)
        CoreDataStack.shared().save()
        print("El reporte fue guardado")
        
        Client.shared().sendPendingLocationReport()
        {
            (sendLocationResp, error) in
            
            //After calling the webservice and this finished then check if there exist a response
            if let sendLocationResp = sendLocationResp
            {
                let reportInterval = sendLocationResp.ReportInterval
                let errorMessage = sendLocationResp.ErrorMessage
                
                print("reportInterval=",reportInterval)
                print("errorMessage=",errorMessage)
                
                if errorMessage == ""
                {
                    do
                    {
                        //Actualiza el reporte a estado Enviado (S)
                        guard let lastPendingLocationReport = try CoreDataStack.shared().fetchLocationReport(NSPredicate(format: "status == %@ ", "P"), entityName: LocationReportInfo.name, sorting: NSSortDescriptor(key: "reportDate", ascending: false))
                        else
                        {
                            print("No se pudo obtener el ultimo reporte pendiente de envio")
                            return
                        }
                    
                        print("Se va actualizar el reporte a enviado")
                        lastPendingLocationReport.setValue("S", forKey: "status")
                        CoreDataStack.shared().save()
                        
                        print("Se actualizo el ultimo reporte pendiente a enviado")
                        DispatchQueue.main.async {
                            print("dispatched to main")
                            self.getLastLocationInfo()
                        }
                    }
                    catch
                    {
                        print("No se pudo obtener el ultimo reporte pendiente de envio")
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

