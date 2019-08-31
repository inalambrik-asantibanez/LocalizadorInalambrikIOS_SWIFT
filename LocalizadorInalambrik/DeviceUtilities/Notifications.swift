//
//  Notifications.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/29/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /*let notificationCenter = UNUserNotificationCenter.current()
    
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func userRequest() {
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
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
                print("Error \(error.localizedDescription)")
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notificacion recibida")
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,withCompletionHandler completionHandler: @escaping () -> Void)
    {
        print("Response=",response)
        
        if response.notification.request.identifier == "Local Notification"
        {
            print("Handling notifications with the Local Notification Identifier")
        }
        
        switch response.actionIdentifier
        {
            case UNNotificationDismissActionIdentifier:
                print("Dismiss Action")
            case UNNotificationDefaultActionIdentifier:
                print("Default")
            case "Abrir":
                print("Abrir panel de localizacion")
                showLocationReportViewController()
            case "Delete":
                print("Delete")
            default:
                print("Unknown action")
        }
        completionHandler()
    }*/
}
