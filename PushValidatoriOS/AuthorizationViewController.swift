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
    
    @IBOutlet weak var application_label: UILabel!
    @IBOutlet weak var clientip_label: UILabel!
    @IBOutlet weak var userid_label: UILabel!
    @IBOutlet weak var transactionid_label: UILabel!
    @IBOutlet weak var timestamp_label: UILabel!
    
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
