//
//  NotificationManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 31/08/22.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    func createNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        content.sound = .default
        
        let date = Date()
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().add(request) { error in
            if let err = error {
                print(err.localizedDescription)
            }
        }
        
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("The notification is about to be presented")
        completionHandler([.badge, .alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.actionIdentifier
        switch identifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismissed")
            completionHandler()
        case UNNotificationDefaultActionIdentifier:
            print("Open app")
            completionHandler()
        default:
            print("Called")
            completionHandler()
        }
    }
}
