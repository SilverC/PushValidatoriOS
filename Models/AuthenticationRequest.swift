//
//  AuthenticationRequest.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 9/10/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//

import Foundation

final class AuthenticationRequest: NSObject {
    let application_name: String
    let user_id: UUID
    let client_ip: String
    let transaction_id: UUID
    let timestamp: Date
    
    init(application_name: String, user_id: UUID, client_ip: String, transaction_id: UUID, timestamp: Date) {
        self.application_name = application_name
        self.user_id = user_id
        self.client_ip = client_ip
        self.transaction_id = transaction_id
        self.timestamp = timestamp
    }
    
    class func makeAuthenticationRequest(_ notificationDictionary: [String: AnyObject]) -> AuthenticationRequest? {
        if let application_name = notificationDictionary["ApplicationName"] as? String,
            let user_id = notificationDictionary["UserId"] as? UUID,
            let client_ip = notificationDictionary["ClientIp"] as? String,
            let transaction_id = notificationDictionary["TransactionId"] as? UUID,
            let timestamp = notificationDictionary["Timestamp"] as? Date {
            
            let request = AuthenticationRequest(application_name: application_name,
                                                user_id: user_id,
                                                client_ip: client_ip,
                                                transaction_id: transaction_id,
                                                timestamp: timestamp)
            let hashableRequest = [
                CodingKeys.ApplicationName: application_name,
                CodingKeys.UserId: user_id,
                CodingKeys.ClientIp: client_ip,
                CodingKeys.TransactionId: transaction_id,
                CodingKeys.Timestamp: timestamp
                ] as [String : Any]
             NotificationCenter.default.post(name: Notification.Name(rawValue: AuthorizationViewController.AuthenticationRequest),
                                             object: self,
                                             userInfo: hashableRequest)
            
            return request
        }
        return nil
    }
}
    
extension AuthenticationRequest: NSCoding {
    struct CodingKeys {
        static let ApplicationName = "ApplicationName"
        static let UserId = "UserId"
        static let ClientIp = "ClientIp"
        static let TransactionId = "TransactionId"
        static let Timestamp = "Timestamp"
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        if let application_name = aDecoder.decodeObject(forKey: CodingKeys.ApplicationName) as? String,
            let user_id = aDecoder.decodeObject(forKey: CodingKeys.UserId) as? UUID,
            let client_ip = aDecoder.decodeObject(forKey: CodingKeys.ClientIp) as? String,
            let transaction_id = aDecoder.decodeObject(forKey: CodingKeys.TransactionId) as? UUID,
            let timestamp = aDecoder.decodeObject(forKey: CodingKeys.Timestamp) as? Date {
            self.init(application_name: application_name, user_id: user_id, client_ip: client_ip, transaction_id: transaction_id, timestamp: timestamp)
        } else {
            return nil
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(application_name, forKey: CodingKeys.ApplicationName)
        aCoder.encode(user_id, forKey: CodingKeys.UserId)
        aCoder.encode(client_ip, forKey: CodingKeys.ClientIp)
        aCoder.encode(transaction_id, forKey: CodingKeys.TransactionId)
        aCoder.encode(timestamp, forKey: CodingKeys.Timestamp)
    }
}
