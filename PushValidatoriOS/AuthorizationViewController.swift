//
//  AuthorizationViewController.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 9/6/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//

import UIKit

class AuthorizationViewController: UIViewController {
    static let AuthenticationRequest = "AuthenticationRequestNotification"
    var data : [AnyHashable : Any] = [:]
    var qrcode: String!
    
    @IBOutlet weak var application_label: UILabel!
    @IBOutlet weak var clientip_label: UILabel!
    @IBOutlet weak var userid_label: UILabel!
    @IBOutlet weak var transactionid_label: UILabel!
    @IBOutlet weak var timestamp_label: UILabel!
    
    @IBAction func cancelButtonClicked(_ sender: UIButton) {
        print("Cancel button clicked")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AuthorizationViewController.receivedAuthenticationRequestFeedNotification(_:)),
                                               name: NSNotification.Name(rawValue: AuthorizationViewController.AuthenticationRequest),
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func receivedAuthenticationRequestFeedNotification(_ notification: Notification) {
        data = notification.userInfo!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        application_label.text = data["ApplicationName"] as? String
        clientip_label.text = data["ClientIp"] as? String
        userid_label.text = data["UserId"] as? String
        transactionid_label.text = data["TransactionId"] as? String
        timestamp_label.text = formatter.string(from: NSDate(timeIntervalSince1970: (data["Timestamp"] as! TimeInterval)) as Date)
    }

    // MARK: - Navigation
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        print("unwind function")
        if segue.source is QRScannerController {
            if let sourceVC = segue.source as? QRScannerController {
                print("unwind function url: \(String(describing: sourceVC.qrcode))")
                qrcode = sourceVC.qrcode
                let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
                let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                    if let data = data {
                        do {
                            let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            print(jsonSerialized!)
                        }
                        catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    }
                    else if let error = error {
                        print(error.localizedDescription)
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
