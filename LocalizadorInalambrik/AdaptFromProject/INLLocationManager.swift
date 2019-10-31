//
//  INLLocationManager.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 10/28/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

public protocol INLLocationManagerDelegate {
    
    func scheduledLocationManager(_ manager: INLLocationManager, didFailWithError error: Error)
    func scheduledLocationManager(_ manager: INLLocationManager, didUpdateLocations locations: [CLLocation])
    func scheduledLocationManager(_ manager: INLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
}


public class INLLocationManager: NSObject, CLLocationManagerDelegate {
    
    private let MaxBGTime: TimeInterval = 170
    private let MinBGTime: TimeInterval = 2
    private let MinAcceptableLocationAccuracy: CLLocationAccuracy = 5
    private let WaitForLocationsTime: TimeInterval = 3
    
    private let delegate: INLLocationManagerDelegate
    private let manager = CLLocationManager()
    
    private var isManagerRunning = false
    private var checkLocationTimer: Timer?
    private var waitTimer: Timer?
    private var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var lastLocations = [CLLocation]()
    
    public private(set) var acceptableLocationAccuracy: CLLocationAccuracy = 100
    public private(set) var checkLocationInterval: TimeInterval = 10
    public private(set) var isRunning = false
    
    public init(delegate: INLLocationManagerDelegate) {
        self.delegate = delegate
        super.init()
        configureLocationManager()
    }
    
    private func configureLocationManager(){
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.delegate = self
    }
    
    public func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }
    
    public func requestWhenInUseAuthorization()
    {
        manager.requestWhenInUseAuthorization()
    }
    
    public func startUpdatingLocation(interval: TimeInterval, acceptableLocationAccuracy: CLLocationAccuracy = 100) {
        DeviceUtilities.shared().printData("startUpdatingLocation Start Update Location at interval =\(interval) seconds")
        if isRunning {
            stopUpdatingLocation()
        }
        
        checkLocationInterval -= WaitForLocationsTime
        checkLocationInterval = interval > MaxBGTime ? MaxBGTime : interval
        checkLocationInterval = interval < MinBGTime ? MinBGTime : interval
        
        self.acceptableLocationAccuracy = acceptableLocationAccuracy < MinAcceptableLocationAccuracy ? MinAcceptableLocationAccuracy : acceptableLocationAccuracy
        
        isRunning = true
        
        addNotifications()
        startLocationManager()
    }
    
    public func stopUpdatingLocation() {
        isRunning = false
        stopWaitTimer()
        stopLocationManager()
        stopBackgroundTask()
        stopCheckLocationTimer()
        removeNotifications()
    }
    
    private func addNotifications() {
        
        removeNotifications()
        
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startLocationManager() {
        isManagerRunning = true
        //manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //manager.distanceFilter = 5
        //manager.desiredAccuracy = 100
        //manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
        
        if #available(iOS 11.0, *) {
            manager.showsBackgroundLocationIndicator = true
        }
        manager.startUpdatingLocation()
    }
    
    private func pauseLocationManager(){
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 99999
    }
    private func stopLocationManager() {
        isManagerRunning = false
        manager.stopUpdatingLocation()
    }
    
    @objc func applicationDidEnterBackground()
    {
        DeviceUtilities.shared().printData("applicationDidEnterBackground  App did come to background")
        let nCenter = UNUserNotificationCenter.current()
        nCenter.removeAllDeliveredNotifications()
        stopBackgroundTask()
        scheduleLocalNotification()
        startBackgroundTask()
        
    }
    
    @objc func applicationDidBecomeActive()
    {
        stopBackgroundTask()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate.scheduledLocationManager(self, didChangeAuthorization: status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate.scheduledLocationManager(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard isManagerRunning else { return }
        guard locations.count>0 else { return }
        
        lastLocations = locations
        
        if waitTimer == nil {
            startWaitTimer()
        }
    }
    
    private func startCheckLocationTimer()
    {
        DeviceUtilities.shared().printData("startCheckLocationTimer Verificacion del timer de reporte")
        stopCheckLocationTimer()
        checkLocationTimer = Timer.scheduledTimer(timeInterval: checkLocationInterval, target: self, selector: #selector(checkLocationTimerEvent), userInfo: nil, repeats: false)
    }
    
    private func stopCheckLocationTimer()
    {
        DeviceUtilities.shared().printData("stopCheckLocationTimer Verificacion del stop del timer del reporte")
        if let timer = checkLocationTimer {
            timer.invalidate()
            checkLocationTimer=nil
        }
    }
    
    @objc func checkLocationTimerEvent()
    {
        DeviceUtilities.shared().printData("checkLocationTimerEvent Stop location timer event")
        stopCheckLocationTimer()
        
        DeviceUtilities.shared().printData("checkLocationTimerEvent Start location timer event")
        startLocationManager()
        
        // starting from iOS 7 and above stop background task with delay, otherwise location service won't start
        self.perform(#selector(stopAndResetBgTaskIfNeeded), with: nil, afterDelay: 1)
    }
    
    private func startWaitTimer()
    {
        stopWaitTimer()
        
        waitTimer = Timer.scheduledTimer(timeInterval: WaitForLocationsTime, target: self, selector: #selector(waitTimerEvent), userInfo: nil, repeats: false)
    }
    
    public func startWaitTimerOnLocationError()
    {
        stopWaitTimer()
        
        waitTimer = Timer.scheduledTimer(timeInterval: WaitForLocationsTime, target: self, selector: #selector(waitTimerEventOnLocationError), userInfo: nil, repeats: false)
    }
    
    private func stopWaitTimer() {
        
        if let timer = waitTimer {
            
            timer.invalidate()
            waitTimer=nil
        }
    }
    
    @objc func waitTimerEventOnLocationError()
    {
        let localDate = Date().preciseLocalDate
        let localTime = Date().preciseLocalTime
        let localDateTime = DeviceUtilities.shared().convertStringToDateTime(localDate, localTime, "yyyy-MM-dd HH:mm:ss")
        let localHour = Int(DeviceUtilities.shared().convertDateTimeToString(localDateTime, "HH"))
        
        stopWaitTimer()
        
        DeviceUtilities.shared().printData("waitTimerEvent when location is correct")
        startBackgroundTask()
        startCheckLocationTimer()
        pauseLocationManager()
        /*if localHour! > ConstantsController().BEGIN_REPORT_HOUR && localHour! < ConstantsController().END_REPORT_HOUR
            {*/
                DeviceUtilities.shared().printData("Localizador en calendario")
                DeviceUtilities.shared().printData("Chequeo de estado de la aplicacion FechaActual=\(Date().preciseLocalDateTime)")
                //delegate.scheduledLocationManager(self, didUpdateLocations: lastLocations)
            //}
            /*else
            {
                DeviceUtilities.shared().printData("Localizador no esta en calendario")
            }*/
    }
    
    @objc func waitTimerEvent()
    {
        let localDate = Date().preciseLocalDate
        let localTime = Date().preciseLocalTime
        let localDateTime = DeviceUtilities.shared().convertStringToDateTime(localDate, localTime, "yyyy-MM-dd HH:mm:ss")
        let localHour = Int(DeviceUtilities.shared().convertDateTimeToString(localDateTime, "HH"))
        
        stopWaitTimer()
        
        if acceptableLocationAccuracyRetrieved()
        {
            DeviceUtilities.shared().printData("waitTimerEvent when location is correct")
            startBackgroundTask()
            startCheckLocationTimer()
            pauseLocationManager()
            /*if localHour! > ConstantsController().BEGIN_REPORT_HOUR && localHour! < ConstantsController().END_REPORT_HOUR
            {*/
                DeviceUtilities.shared().printData("Localizador en calendario")
                DeviceUtilities.shared().printData("Chequeo de estado de la aplicacion FechaActual=\(Date().preciseLocalDateTime)")
                delegate.scheduledLocationManager(self, didUpdateLocations: lastLocations)
            //}
            /*else
            {
                DeviceUtilities.shared().printData("Localizador no esta en calendario")
            }*/
        }
        else
        {
            DeviceUtilities.shared().printData("waitTimerEvent When location is 0,0")
            startWaitTimer()
        }
    }
    
    private func acceptableLocationAccuracyRetrieved() -> Bool {
        let location = lastLocations.last!
        return location.horizontalAccuracy <= acceptableLocationAccuracy ? true : false
    }
    
    @objc func stopAndResetBgTaskIfNeeded()  {
        
        if isManagerRunning {
            stopBackgroundTask()
        }else{
            stopBackgroundTask()
            startBackgroundTask()
        }
    }
    
    private func startBackgroundTask()
    {
        DeviceUtilities.shared().printData("startBackgroundTask When start the background task")
        let state = UIApplication.shared.applicationState
        
        if ((state == .background || state == .inactive) && bgTask == UIBackgroundTaskInvalid) {
            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                self.checkLocationTimerEvent()
            })
        }
    }
    
    @objc private func stopBackgroundTask() {
        guard bgTask != UIBackgroundTaskInvalid else { return }
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
    }
    
    func scheduleLocalNotification()
    {
         DeviceUtilities.shared().printData("scheduleLocalNotification create a notification")
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.fireNotification()
            }
        }
    }
    
    func fireNotification() {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Localizador Inalambrik"
        let lastLocationInfo = LocationUtilities.shared().getLastLocationInfo()
        notificationContent.body = "Última ubicación encontrada a las \(lastLocationInfo.reportDate.preciseLocalDateTime )"
        
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

