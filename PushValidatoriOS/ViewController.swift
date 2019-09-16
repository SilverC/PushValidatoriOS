//
//  ViewController.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 8/28/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) {
            (granted, error) in
            if granted {
                print("yes")
            } else {
                print("No")
            }
        }
    }

    @IBAction func sendNotification(_ sender: Any) {
        // 1
        let content = UNMutableNotificationContent()
        content.title = "Notification Tutorial"
        content.subtitle = "Subtitle"
        content.body = "Notification triggered"
        content.userInfo = [
            AnyHashable("ApplicationName"): "Sample Web App",
            AnyHashable("UserId"): UUID().uuidString,
            AnyHashable("ClientIp"): "192.168.10.1",
            AnyHashable("TransactionId"): UUID().uuidString,
            AnyHashable("Timestamp"): NSDate().timeIntervalSince1970
        ]
        
        // 3
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
        
        // 4
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        print("Sent local notification")
    }
}

