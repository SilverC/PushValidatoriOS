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
    //var request:AuthenticationRequest = nil
    
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
        application_label.text = notification.userInfo!["ApplicationName"] as? String
        clientip_label.text = notification.userInfo!["ClientIp"] as? String
        userid_label.text = notification.userInfo!["UserId"] as? String
        transactionid_label.text = notification.userInfo!["TransactionId"] as? String
        timestamp_label.text = notification.userInfo!["Timestamp"] as? String
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
