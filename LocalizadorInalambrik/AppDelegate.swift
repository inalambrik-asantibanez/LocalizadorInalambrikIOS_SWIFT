//
//  AppDelegate.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreLocation
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()
    let categoryIdentifier = "PUSH_NOTIFICATION"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        /*if #available(iOS 13.0, *)
        {
            registerBackgroundTaks()
        }*/
        
        notificationCenter.delegate = (self as UNUserNotificationCenterDelegate)
        let options : UNAuthorizationOptions = [.badge,.alert,.sound]
        notificationCenter.requestAuthorization(options: options) {
            (success, error) in
            if !success {
                DeviceUtilities.shared().printData("usuario no ha autotizado el uso de notificaciones locales")
            }
            else
            {
                self.registerCategory()
            }
            self.getNotificationSettings()
        }
        
        return true
    }
    
    //MARK: Register BackGround Tasks
    @available(iOS 13.0, *)
    private func registerBackgroundTaks() {
        DeviceUtilities.shared().printData("registerBackgroundTaks Register the background task for ios 13")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.so.locationreport", using: nil) { task in
            //This task is cast with processing request (BGAppRefreshTask)
            self.scheduleLocalNotification()
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        /*if #available(iOS 13.0, *)
        {
            let vc = LocationReportViewController()
            vc.endBackgroundTask()
            DeviceUtilities.shared().printData("App entro a background ios 13")
            cancelAllPandingBGTask()
            scheduleAppRefresh()
        }
        else
        {
            DeviceUtilities.shared().printData("App entro a background ios 12 para abajo")
            NotificationCenter.default.post(name: .setLocationReportInterval, object: nil)
        }*/
    }
    
    
    @available(iOS 13.0, *)
    func cancelAllPandingBGTask() {
        DeviceUtilities.shared().printData("cancelAllPandingBGTask Cancel all pending tasks")
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh()
    {
        DeviceUtilities.shared().printData("scheduleAppRefresh Schedule the app refresh")
        let request = BGAppRefreshTaskRequest(identifier: "com.so.locationreport")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // App Refresh after 2 minute.
        
        do
        {
            DeviceUtilities.shared().printData("scheduleAppRefresh Submitting the background task request")
            try BGTaskScheduler.shared.submit(request)
        }
        catch
        {
            DeviceUtilities.shared().printData("Could not schedule app refresh: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func handleAppRefreshTask(task: BGAppRefreshTask)
    {
        scheduleAppRefresh()
        DeviceUtilities.shared().printData("handleAppRefreshTask FechaActual=\(Date().preciseLocalDateTime)")

        task.expirationHandler = {
            self.cancelAllPandingBGTask()
        }
        scheduleLocalNotification()
        task.setTaskCompleted(success: true)
    }
    
    func registerLocalNotification() {
           let notificationCenter = UNUserNotificationCenter.current()
           let options: UNAuthorizationOptions = [.alert, .sound, .badge]
           
           notificationCenter.requestAuthorization(options: options) {
               (didAllow, error) in
               if !didAllow {
                   print("User has declined notifications")
               }
           }
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
           notificationContent.title = "Bg"
           notificationContent.body = "BG Notifications."
           
           // Add Trigger
           let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
           
           // Create Notification Request
           let notificationRequest = UNNotificationRequest(identifier: "local_notification", content: notificationContent, trigger: notificationTrigger)
           
           // Add Request to User Notification Center
           UNUserNotificationCenter.current().add(notificationRequest) { (error) in
               if let error = error {
                   print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
               }
           }
       }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        DeviceUtilities.shared().printData("App fue eliminada del multitarea")
        let userAuthorized = QueryUtilities.shared().checkUserAuthorization()
        
        // Si está autorizado, entonces quito la pantalla de Login que se pone encima
        if userAuthorized
        {
            DeviceUtilities.shared().printData("Usuario autorizado proceda con el guardado del reporte por terminacion de app")
            let locationReport = CLLocation()
            LocationUtilities.shared().saveLocationReportObjectOnFetchLocation(locationReport,"TERMINATE")
            let notificationType = "Localizador Inalambrik fue cerrado"
            DeviceUtilities.shared().printData("Programacion de notificacion por terminacion del app")
            self.scheduleNotification(event: notificationType,interval: 2)
            sleep(3)
            DeviceUtilities.shared().printData("applicationWillTerminate")
            UIApplication.shared.isIdleTimerDisabled = true
        }
        self.saveContext()
    }
    
    func registerCategory() -> Void
    {
        let category : UNNotificationCategory = UNNotificationCategory.init(identifier: categoryIdentifier, actions: [], intentIdentifiers: [], options: [])
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        
    }
    
    func scheduleNotification (event : String, interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        
        content.title = event
        content.body = "Favor abrir el Localizador Inalambrik"
        content.categoryIdentifier = categoryIdentifier
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: interval, repeats: false)
        let identifier = "id_"+event
        let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: { (error) in
        })
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DeviceUtilities.shared().printData("didReceive notification")
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DeviceUtilities.shared().printData("PN willPresent notification")
        completionHandler([.badge, .alert, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        DeviceUtilities.shared().printData("PN Remote notification received...")
        if application.applicationState == .active
        {
            DeviceUtilities.shared().printData("PN Notification received in active state in this state does not need to do anything...")
        }
        else if application.applicationState == .background
        {
            DeviceUtilities.shared().printData("PN Notification received in background state, in this state it needs to reactive the location task...")
            if CLLocationManager.locationServicesEnabled()
            {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    DeviceUtilities.shared().printData("PN No access")
                case .authorizedAlways, .authorizedWhenInUse:
                    DeviceUtilities.shared().printData("PN Location Services are granted")
                    if LocationServiceTask.shared().locationServiceIsRunning
                    {
                        DeviceUtilities.shared().printData("PN Location service need to stop before start")
                        LocationServiceTask.shared().stopUpdatingLocation()
                    }
                    DeviceUtilities.shared().printData("PN Location service start from notification")
                    LocationServiceTask.shared().startUpdatingLocation()
                    
                }
            } else {
                DeviceUtilities.shared().printData("PN Location services are not enabled")
            }
        }
        else{
            DeviceUtilities.shared().printData("PN Notification received in inactive state.... this state unfortunately can't do anything")
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "LocalizadorInalambrik")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {

    
    func scheduleNotification(notificationType: String) {
        
        let content = UNMutableNotificationContent() // Содержимое уведомления
        let userActions = "User Actions"
        
        content.title = notificationType
        content.body = "Localizador Móvil se ha cerrado. Por favor reiniciar aplicación."
        content.sound = UNNotificationSound.default()
        content.badge = 1
        content.categoryIdentifier = userActions
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                DeviceUtilities.shared().printData("Error \(error.localizedDescription)")
            }
        }
        
        let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Abrir", options: [])
        let deleteAction = UNNotificationAction(identifier: "Delete", title: "Borrar", options: [.destructive])
        let category = UNNotificationCategory(identifier: userActions,
                                              actions: [snoozeAction, deleteAction],
                                              intentIdentifiers: [],
                                              options: [])
        
        notificationCenter.setNotificationCategories([category])
    }
}

extension AppDelegate
{
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DeviceUtilities.shared().printData("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else{
                DeviceUtilities.shared().printData("Usuario rechazo el permiso de notificaciones")
                return
                
            }
            DeviceUtilities.shared().printData("Usuario permitio las notificaciones push")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // Permite recibir el token desde el APNS
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        DeviceUtilities.shared().printData("Device Token: \(token)")
        DeviceUtilities.shared().printData("Se crea usuario con token")
        _ = User(userId: "1", deviceId: "ASD", authorizedDevice: "0", deviceIdentifierVendorID: "", apple_pn_id: token, context: CoreDataStack.shared().context)
        CoreDataStack.shared().save()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DeviceUtilities.shared().printData("Failed to register: \(error)")
    
    }

}
