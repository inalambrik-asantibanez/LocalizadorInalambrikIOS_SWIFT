//
//  LocationServiceTask.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 9/3/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreLocation

class LocationServiceTask: NSObject, CLLocationManagerDelegate
{
    class func shared() -> LocationServiceTask
    {
        struct Singleton {
            static var shared = LocationServiceTask()
        }
        return Singleton.shared
    }
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var counter = 1
    let numTries = ConstantsController().NUMBER_OF_TRIES
    var locationServiceIsRunning = false
    let locationReportController = LocationReportViewController()
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else
        {
            return
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined
        {
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startUpdatingLocation() {
        DeviceUtilities.shared().printData("Starting Location Updates")
        locationServiceIsRunning = true
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationServiceIsRunning = false
        DeviceUtilities.shared().printData("Stop Location Updates")
        self.locationManager?.stopUpdatingLocation()
        
        //Post the notification to register the next timer (Location Report Interval)
        DeviceUtilities.shared().printData("Ejecucion del observer del seteo del timer del intervalo del reporte a las FechaActual=\(Date().preciseLocalDateTime)")
        NotificationCenter.default.post(name: .setLocationReportInterval, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let mostRecentLocation = locations[0]
        
        print("new datetime",mostRecentLocation.timestamp)
        print("new latitude",mostRecentLocation.coordinate.latitude)
        print("new longitude",mostRecentLocation.coordinate.longitude)
        
        DeviceUtilities.shared().printData("Intento # \(counter)")
        if abs(mostRecentLocation.coordinate.latitude) != 0 && abs(mostRecentLocation.coordinate.longitude) != 0 && counter > numTries
        {
            //Save LocationReport in DB
            DeviceUtilities.shared().printData("Se guarda reporte en BD despues de haber buscado ubicación")
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(mostRecentLocation,"")
            
            //Post the notification to update UI
            DeviceUtilities.shared().printData("Ejecucion del observer del refresh del UI")
            NotificationCenter.default.post(name: .refreshUI, object: nil)
            
            //Post the notification to send the first Report
            DeviceUtilities.shared().printData("Ejecucion del observer del envio del primer reporte")
            NotificationCenter.default.post(name: .sendFirstRP, object: nil)
            
            DeviceUtilities.shared().printData("LR Reporte Guardado Fecha:  \(mostRecentLocation.timestamp.preciseLocalDateTime), Latitude:  \(mostRecentLocation.coordinate.latitude) Longitude:  \(mostRecentLocation.coordinate.longitude)")
            
            DeviceUtilities.shared().printData("Servicio de ubicacion apagado")
            stopUpdatingLocation()
            print("")
            
            //Reinit the counter
            counter = 1
        }
        counter += 1
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        counter = 1
        DeviceUtilities.shared().printData("No puedo obtener la coordenada, esta tuvo error")
        stopUpdatingLocation()
    }
}

extension Notification.Name
{
    static let refreshUI = Notification.Name("refreshUIfromLocation")
    static let sendFirstRP = Notification.Name("sendFirstReport")
    static let setLocationReportInterval = Notification.Name("setLocationReportInterval")
}
