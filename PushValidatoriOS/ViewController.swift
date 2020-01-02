//
//  ViewController.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 8/28/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData

class ViewController: UIViewController {

    var data : [AnyHashable : Any] = [:]
    var qrcode: String!
    var transactionID: UUID!
    
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
        print(data)
        self.transactionID = UUID.init(uuidString: data["TransactionId"] as! String)
    }

    @IBAction func sendNotification(_ sender: Any) {
        // 1
        let content = UNMutableNotificationContent()

        content.title = "Notification Tutorial"
        content.subtitle = "Subtitle"
        content.body = "Notification triggered"
        content.userInfo = [
            AnyHashable("ApplicationName"): "Sample Web App",
            AnyHashable("UserName"): "fake@test.com",
            AnyHashable("ClientIp"): "192.168.10.1",
            AnyHashable("GeoLocation"): "Harrisonburg, VA, USA",
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
    
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
    
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        print("success unwind function: \(String(describing: segue.source.title))")
        
        if segue.source is QRScannerController {
            if let sourceVC = segue.source as? QRScannerController {
                
                if sourceVC.qrcode == nil {
                    dismiss(animated: true, completion: nil)
                    print("qrcode value not set, doing nothing...")
                    return
                }
                
                print("success unwind function url: \(String(describing: sourceVC.qrcode))")
                self.qrcode = sourceVC.qrcode
                
                // Parse query params from QR code
                let queryItems = URLComponents(string: self.qrcode)?.queryItems
                let fingerprintItem = queryItems?.filter({$0.name == "fingerprint"}).first
                let fingerprint = fingerprintItem?.value ?? "Fingerprint value not found"
                print(fingerprint)
                
                let ipItem = queryItems?.filter({$0.name == "ip"}).first
                let ip = ipItem?.value ?? "IP not found"
                print(ip)
                
                let uriItem = queryItems?.filter({$0.name == "url"}).first
                let uri = uriItem?.value ?? "URI not found"
                print(uri)
                
                // Get deviceId
                guard let appDelegate =
                  UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                let context = appDelegate.persistentContainer.viewContext
                let deviceIdFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Device")
                var deviceId = ""
                do {
                    let results = try context.fetch(deviceIdFetchRequest)
                    deviceId = results[0].value(forKey: "id") as! String
                } catch let error as NSError {
                    print("Could not retrieve deviceId. \(error), \(error.userInfo)")
                }
                print("token retreived from core data: \(deviceId)")
                
                // Sign data
                let dataString = self.transactionID.uuidString + "True" + fingerprint + ip + uri
                print(dataString)
                let dataToSign = dataString.data(using: .utf8)! as CFData
                print(hexStringFromData(input: dataToSign))
                print(dataString.sha256())
                let getquery: [String: Any] = [
                    kSecClass as String:              kSecClassKey,
                    kSecAttrApplicationTag as String: deviceId,
                    kSecAttrKeyType as String:        kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String:  256,
                    kSecAttrTokenID as String:        kSecAttrTokenIDSecureEnclave,
                    kSecReturnRef as String:          true
                ]
                var item: CFTypeRef?
                let status = SecItemCopyMatching(getquery as CFDictionary, &item)
                
                // If key exists then use it; otherwise generate one
                var signatureString = ""
                if status == errSecSuccess {
                    print("Found existing key")
                    let privateKey = (item as! SecKey)
                    let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
                    var error: Unmanaged<CFError>?
                    guard let signature = SecKeyCreateSignature(privateKey,
                        algorithm,
                        dataToSign,
                        &error) as Data? else {
                            print("Failed to sign data. \(String(describing: error))")
                            return
                        }
                    print(hexStringFromData(input: signature as NSData))
                    signatureString = signature.base64EncodedString()
                    print(signatureString)
                    let publicKey = SecKeyCopyPublicKey(privateKey)!
                    let verify = SecKeyVerifySignature(publicKey,
                        algorithm,
                        dataToSign,
                        signature as CFData,
                        &error)
                    print("Result of verification: \(verify)")
                    let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error)! as Data
                    let keyConverter = AsymmetricKeyConverter()
                    let pemKey = keyConverter.exportPublicKeyToPEM(publicKeyData, keyType: kSecAttrKeyTypeECSECPrimeRandom as String, keySize: 256)
                    print(pemKey ?? "Failed to convert key to PEM format")
                }
                
                // Build json data object
                let json: [String: Any] = [
                                   "ServerURI": "\(String(describing: uri))",
                                   "CertificateFingerprint": "\(String(describing: fingerprint))",
                                   "ServerIP": "\(String(describing: ip))",
                                   "Result": "True",
                                   "TransactionId": "\(self.transactionID.uuidString)",
                                   "Signature": signatureString
                               ]
                print(json)
                
                let url = URL(string: "https://psuhvalidator.com/transactions/update")!
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

