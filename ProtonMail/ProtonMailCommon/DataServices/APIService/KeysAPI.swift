//
//  KeysAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/11/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit

final class UserEmailPubKeys : ApiRequestNew<KeysResponse> {
    let email : String
    init(email : String) {
        self.email = email
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["Email" : self.email]
        return out
    }
    
    override open func path() -> String {
        return KeysAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return KeysAPI.v_get_emails_pub_key
    }
}

extension Array where Element : UserEmailPubKeys {
    var promises : [Promise<KeysResponse>] {
        var out : [Promise<KeysResponse>] = [Promise<KeysResponse>]()
        for it in self {
             out.append(it.run())
        }
        return out
    }
}


final class KeyResponse {
    var send : Int = 1 // 1 internal 2 external
    var publicKey : String?
   
    init(send : Int, pubkey: String?) {
        self.send = send
        self.publicKey = pubkey
    }
}

final class KeysResponse : ApiResponse {
    var recipientType : Int = 1 // 1 internal 2 external
    var mimeType : String?
    var keys : [KeyResponse] = [KeyResponse]()
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.recipientType = response["RecipientType"] as? Int ?? 1
        self.mimeType = response["MIMEType"] as? String
        
        if let keyRes = response["Keys"] as? [[String : Any]] {
            for keyDict in keyRes {
                let send = keyDict["Send"] as? Int ?? 0
                
                let keyFlags =  keyDict["Flags"] as? Int ?? 0
                
                let pubKey = keyDict["PublicKey"] as? String
                self.keys.append(KeyResponse(send: send, pubkey: pubKey))
            }
        }
        return true
    }
    
    func firstKey () -> String? {
        for k in keys {
            if k.send == 1 {
                return k.publicKey
            }
        }
        return nil
    }
}

//MARK : get keys salt  #not in used
final class GetKeysSalts<T : ApiResponse> : ApiRequest<T> {
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func path() -> String {
        return KeysAPI.path + "/salts" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return KeysAPI.v_get_key_salts
    }
}

final class KeySaltResponse : ApiResponse {
    var keySalts : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.keySalts = response["KeySalts"] as? [[String : Any]]
        return true
    }
}

/// message packages
final class PasswordAuth : Package {

    let AuthVersion : Int = 4
    let ModulusID : String //encrypted id
    let salt : String //base64 encoded
    let verifer : String //base64 encoded
    
    init(modulus_id : String, salt :String, verifer : String) {
        self.ModulusID = modulus_id
        self.salt = salt
        self.verifer = verifer
    }
    
    // Mark : override class functions
    func toDictionary() -> [String:Any]? {
        let out : [String : Any] = [
            "Version" : self.AuthVersion,
            "ModulusID" : self.ModulusID,
            "Salt" : self.salt,
            "Verifier" : self.verifer
        ]
        return out
    }
}


//MARK : update user's private keys
final class UpdatePrivateKeyRequest<T : ApiResponse> : ApiRequest<T> {
    
    let clientEphemeral : String! //base64 encoded
    let clientProof : String! //base64 encoded
    let SRPSession : String! //hex encoded session id
    let tfaCode : String? // optional
    let keySalt : String! //base64 encoded need random value
    
    var userLevelKeys: [Key]!
    var userAddressKeys: [Key]!
    let orgKey : String?
    
    let auth : PasswordAuth?

    
    init(clientEphemeral: String!,
         clientProof: String!,
         SRPSession: String!,
         keySalt: String!,
         userlevelKeys: [Key]!,
         addressKeys: [Key]!,
         tfaCode : String?,
         orgKey: String?,
         
         auth: PasswordAuth?
         ) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = SRPSession
        self.keySalt = keySalt
        self.userLevelKeys = userlevelKeys
        self.userAddressKeys = addressKeys
        
        //optional values
        self.orgKey = orgKey
        self.tfaCode = tfaCode
        self.auth = auth
    }
    
    override func toDictionary() -> [String : Any]? {
        var keysDict : [Any] = [Any]()
        for _key in userLevelKeys {
            if _key.is_updated {
                keysDict.append( ["ID": _key.key_id, "PrivateKey" : _key.private_key] )
            }
        }
        for _key in userAddressKeys {
            if _key.is_updated {
                keysDict.append( ["ID": _key.key_id, "PrivateKey" : _key.private_key] )
            }
        }
        
        var out : [String : Any] = [
            "ClientEphemeral" : self.clientEphemeral,
            "ClientProof" : self.clientProof,
            "SRPSession": self.SRPSession,
            "KeySalt" : self.keySalt,
            "Keys" : keysDict
            ]
        
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        if let org_key = orgKey {
             out["OrganizationKey"] = org_key
        }
        if let auth_obj = self.auth {
            out["Auth"] = auth_obj.toDictionary()
        }
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return KeysAPI.path + "/private" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return KeysAPI.v_update_private_key
    }
}


//MARK : update user's private keys
final class SetupKeyRequest<T : ApiResponse> : ApiRequest<T> {
    
    let addressID : String!
    let privateKey : String!
    let keySalt : String! //base64 encoded need random value
    
    let auth : PasswordAuth!
    
    
    init(address_id: String!, private_key : String!, keysalt:String!,
         auth: PasswordAuth!
        ) {
        self.keySalt = keysalt
        self.addressID = address_id
        self.privateKey = private_key
        self.auth = auth
    }
    
    override func toDictionary() -> [String : Any]? {
        let address : [String: Any] = [
            "AddressID" : self.addressID,
            "PrivateKey" : self.privateKey
        ]
        
        let out : [String : Any] = [
            "KeySalt" : self.keySalt,
            "PrimaryKey": self.privateKey,
            "AddressKeys" : [address] ,
            "Auth" : self.auth.toDictionary()!
        ]

        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return KeysAPI.path + "/setup" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return KeysAPI.v_setup_key
    }
}