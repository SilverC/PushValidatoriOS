//
//  RegisterController.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 11/14/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class RegisterController : UIViewController {
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var registerCodeFrameView: UIView?
    
    var qrcode: String!
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestAuthorization()
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Move the message label and top bar to the front
        //view.bringSubviewToFront(messageLabel)
        //view.bringSubviewToFront(topbar)
        
        // Initialize QR Code Frame to highlight the QR code
        registerCodeFrameView = UIView()
        
        if let qrCodeFrameView = registerCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods
    func requestAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            return
        // The user has previously granted permission to access the camera.
        case .notDetermined:
            // We have never requested access to the camera before.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    guard granted else {
                        // The user denied the camera access request.
                        return
                    }
                    
                    // The user has granted permission to access the camera.
                }
            }
        case .denied, .restricted:
            // The user either previously denied the access request or the
            // camera is not available due to restrictions.
            return ()
        @unknown default:
            fatalError()
        }
    }
}

extension RegisterController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            registerCodeFrameView?.frame = CGRect.zero
            //messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            registerCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                print("Found QR code: \(metadataObj.stringValue ?? "unable to parse metadataObj.stringValue")")
                qrcode = metadataObj.stringValue
                
                //Parse values from qrcode
                let queryItems = URLComponents(string: qrcode)?.queryItems
                let secretItem = queryItems?.filter({$0.name == "secret"}).first
                let secret = secretItem?.value ?? "Secret value not found"
                print(secret)
                
                let key = Data(base64Encoded: secret)!
                print(key.description)
                
                let deviceIdItem = queryItems?.filter({$0.name == "id"}).first
                let deviceId = deviceIdItem?.value ?? "Device ID not found"
                print(deviceId)
                
                // Get token
                guard let appDelegate =
                  UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                let context = appDelegate.persistentContainer.viewContext
                let tokenFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Device")
                var token = ""
                do {
                    let results = try context.fetch(tokenFetchRequest)
                    token = results[0].value(forKey: "token") as! String
                    results[0].setValue(deviceId, forKey: "id")
                    results[0].setValue(secret, forKey: "secret")
                    try context.save()
                } catch let error as NSError {
                    print("Could not save or retrieve data. \(error), \(error.userInfo)")
                }
                print("token retreived from core data: \(token)")
                
                //Get Public Key
                
                //Check for exiting key
                let getquery: [String: Any] = [
                    kSecClass as String:              kSecClassKey,
                    kSecAttrApplicationTag as String: deviceId,
                    kSecAttrKeyType as String:        kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String:  256,
                    kSecAttrTokenID as String:        kSecAttrTokenIDSecureEnclave,
                    kSecReturnRef as String:          true
                ]
                var item: CFTypeRef?
                var publicKey: SecKey?
                let status = SecItemCopyMatching(getquery as CFDictionary, &item)
                
                // If key exists then use it; otherwise generate one
                if status == errSecSuccess {
                    print("Found existing key")
                    let privateKey = (item as! SecKey)
                    publicKey = SecKeyCopyPublicKey(privateKey)
                }
                else {
                    print("Unable to find an existing key")
                    let access =
                    SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                    .privateKeyUsage,
                                                    nil)!   // Ignore error
                    let attributes: [String: Any] = [
                      kSecAttrKeyType as String:            kSecAttrKeyTypeEC,
                      kSecAttrKeySizeInBits as String:      256,
                      kSecAttrTokenID as String:            kSecAttrTokenIDSecureEnclave,
                      kSecPrivateKeyAttrs as String: [
                        kSecAttrIsPermanent as String:      true,
                        kSecAttrApplicationTag as String:   deviceId,
                        kSecAttrAccessControl as String:    access
                      ]
                    ]
                    var error: Unmanaged<CFError>?
                    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                        print("Failed to produce private key")
                        captureSession.stopRunning()
                        self.performSegue(withIdentifier: "unwindFromRegisterDone", sender: self)
                        return
                    }

                    publicKey = SecKeyCopyPublicKey(privateKey)//"TestPublicKey"
                }
                
                var error: Unmanaged<CFError>?
                let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, &error)! as Data
                let keyConverter = AsymmetricKeyConverter()
                let pemKey = keyConverter.exportPublicKeyToPEM(publicKeyData, keyType: kSecAttrKeyTypeECSECPrimeRandom as String, keySize: 256)
                print(pemKey ?? "Failed to convert key to PEM format")
                
                // Build HMAC
                let data = deviceId + "\(token)" + (pemKey ?? "TestPublicKey")
                print(data)
                let hmac = data.hmac(algorithm: .sha256, key: key)
                print("HMAC : " + hmac)
                
                // Update device in service
                let json: [String: Any] = [
                    "DeviceId": "\(String(describing: deviceId))",
                    "DeviceToken": "\(token)",
                    "PublicKey": pemKey ?? "TestPublicKey",
                    "HMAC": hmac
                ]
                print(json)
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                let url = URL(string: "https://pushvalidatorservice.azurewebsites.net/Devices/Update")!
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                let configuration = URLSessionConfiguration.default
                
                let task = URLSession(configuration: configuration, delegate: self, delegateQueue: nil).dataTask(with: request, completionHandler: { data, response, error in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("Response Status Code:")
                        print(httpResponse.statusCode)
                        if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                            print("Successfully registered device")
                        }
                        else {
                           print("Failed to communicate with server")
                        }
                    }
//                    if let data = data {
//                        do {
//                            let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                            print(jsonSerialized!)
//                        }
//                        catch let error as NSError {
//                            print(error.localizedDescription)
//                        }
//                    }
//                    else if let error = error {
//                        print(error.localizedDescription)
//                    }
                })
                task.resume()
                
                //launchApp(decodedURL: metadataObj.stringValue!)
                //messageLabel.text = metadataObj.stringValue
                captureSession.stopRunning()
                self.performSegue(withIdentifier: "unwindFromRegisterDone", sender: self)
            }
        }
    }
    
    
}

extension RegisterController: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Used bypass delegate")
        let protectionSpace = challenge.protectionSpace
        guard let serverTrust = protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
        // trust certificate
        //let cred = challenge.protectionSpace.serverTrust.map { URLCredential(trust: $0) }
        //completionHandler(.useCredential, cred)
    }
}
