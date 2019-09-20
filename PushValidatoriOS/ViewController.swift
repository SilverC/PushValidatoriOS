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

    var data : [AnyHashable : Any] = [:]
    var qrcode: String!
    
    @IBOutlet weak var result: UILabel!

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
    
    @IBAction func unwindCancelToHome(segue: UIStoryboardSegue) {
        print("cancel unwind function")
        if segue.source is AuthorizationViewController {
            if segue.source is AuthorizationViewController {
                result.text = "Denied by user"
            }
        }
    }
    
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        print("success unwind function: \(String(describing: segue.source.title))")
        if segue.source is QRScannerController {
            if let sourceVC = segue.source as? QRScannerController {
                print("success unwind function url: \(String(describing: sourceVC.qrcode))")
                self.qrcode = sourceVC.qrcode
                let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
                let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                    if let data = data {
                        do {
                            let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            print(jsonSerialized!)
                            DispatchQueue.main.async {
                                self.result.text = "Approved by user"
                            }
                        }
                        catch let error as NSError {
                            print(error.localizedDescription)
                            DispatchQueue.main.async {
                                self.result.text = "Failed to communicate with server"
                            }
                        }
                    }
                    else if let error = error {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            self.result.text = "Failed to communicate with server"
                        }
                    }
                })
                task.resume()
            }
        }
        else {
            print("segue source did not match \(segue.source.debugDescription)")
        }
        
        dismiss(animated: true, completion: nil)
    }

}

