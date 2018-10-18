//
//  UserTempCachedStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/15/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation
import UICKeyChainStore

let userDebugCached =  SharedCacheBase.getDefault()
class UserTempCachedStatus: NSObject, NSCoding {
    struct Key{
        static let keychainStore = "UserTempCachedStatusKey"
    }
    
    struct CoderKey {
        static let lastLoggedInUser = "lastLoggedInUser"
        static let touchIDEmail = "isPinCodeEnabled"
        static let isPinCodeEnabled = "isPinCodeEnabled"
        static let pinCodeCache = "pinCodeCache"
        static let autoLockTime = "autoLockTime"
        static let showMobileSignature = "showMobileSignature"
        static let localMobileSignature = "localMobileSignature"
    }
    
    var lastLoggedInUser : String!

    var touchIDEmail : String!
    var pinCodeCache : String!
    var autoLockTime : String!
    var localMobileSignature : String!
    var showMobileSignature : Bool = false
    var isPinCodeEnabled : Bool = false
    
    required init(lastLoggedInUser: String!,
                         touchIDEmail: String!,
                         isPinCodeEnabled: Bool,
                         pinCodeCache: String!,
                         autoLockTime : String!,
                         showMobileSignature: Bool,
                         localMobileSignature:String!) {
        super.init()
        self.lastLoggedInUser = lastLoggedInUser ?? ""
        self.touchIDEmail = touchIDEmail ?? ""
        self.isPinCodeEnabled = isPinCodeEnabled
        self.pinCodeCache = pinCodeCache ?? ""
        self.autoLockTime = autoLockTime ?? "-1"
        self.showMobileSignature = showMobileSignature
        self.localMobileSignature = localMobileSignature ?? ""
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(
            lastLoggedInUser: aDecoder.decodeObject(forKey: CoderKey.lastLoggedInUser) as? String,
            touchIDEmail: aDecoder.decodeObject(forKey: CoderKey.touchIDEmail) as? String,
            isPinCodeEnabled: aDecoder.decodeObject(forKey: CoderKey.isPinCodeEnabled) as? Bool ?? false,
            pinCodeCache: aDecoder.decodeObject(forKey: CoderKey.pinCodeCache) as? String,
            autoLockTime: aDecoder.decodeObject(forKey: CoderKey.autoLockTime) as? String,
            showMobileSignature: aDecoder.decodeObject(forKey: CoderKey.showMobileSignature) as? Bool ?? false,
            localMobileSignature: aDecoder.decodeObject(forKey: CoderKey.localMobileSignature) as? String);
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(lastLoggedInUser, forKey: CoderKey.lastLoggedInUser)
        aCoder.encode(touchIDEmail, forKey: CoderKey.touchIDEmail)
        aCoder.encode(isPinCodeEnabled, forKey: CoderKey.isPinCodeEnabled)
        aCoder.encode(pinCodeCache, forKey: CoderKey.pinCodeCache)
        aCoder.encode(autoLockTime, forKey: CoderKey.autoLockTime)
        aCoder.encode(showMobileSignature, forKey: CoderKey.showMobileSignature)
        aCoder.encode(localMobileSignature, forKey: CoderKey.localMobileSignature)
    }
    
    
    class func backup () {
        if UserTempCachedStatus.fetchFromKeychain() == nil && sharedUserDataService.isSignedIn {
            let u = UserTempCachedStatus(
                lastLoggedInUser: sharedUserDataService.username,
                touchIDEmail: "FIXME",
                isPinCodeEnabled: userCachedStatus.isPinCodeEnabled,
                pinCodeCache: "FIXME",
                autoLockTime: userCachedStatus.lockTime,
                showMobileSignature: sharedUserDataService.showMobileSignature,
                localMobileSignature: userCachedStatus.mobileSignature)
            u.storeInKeychain()
        }
    }
    
    class func restore() {
        if let cache = UserTempCachedStatus.fetchFromKeychain() {
            if sharedUserDataService.username == cache.lastLoggedInUser {
                userCachedStatus.isPinCodeEnabled = cache.isPinCodeEnabled
                userCachedStatus.lockTime = cache.autoLockTime ?? "-1"
                sharedUserDataService.showMobileSignature = cache.showMobileSignature
                userCachedStatus.mobileSignature = cache.localMobileSignature ?? ""
            }
        }
        UserTempCachedStatus.clearFromKeychain()
    }
    
    
    func storeInKeychain() {
        userCachedStatus.isForcedLogout = false
        sharedKeychain.keychain().setData(NSKeyedArchiver.archivedData(withRootObject: self), forKey: Key.keychainStore)
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        sharedKeychain.keychain().removeItem(forKey: Key.keychainStore) //newer version
    }
    
    class func fetchFromKeychain() -> UserTempCachedStatus? {
        if let data = UICKeyChainStore.data(forKey: Key.keychainStore) {
            if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? UserTempCachedStatus {
                return authCredential
            }
        }
        return nil
    }
}
