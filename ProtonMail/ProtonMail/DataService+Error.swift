//
//  UserDataService+Error.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/14/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


let dataServiceDomain = NSError.protonMailErrorDomain("DataService")

extension NSError {
    
    class func CreateError(_ domain : String,
                           code: Int,
                           localizedDescription: String,
                           localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: domain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
}

protocol CustomErrorVar {
    var code : Int { get }
    
    var desc : String { get }
    
    var reason : String { get }
}

extension CustomErrorVar {
    func toError() -> NSError {
        return NSError.CreateError(dataServiceDomain,
                                   code: code,
                                   localizedDescription: desc,
                                   localizedFailureReason: reason)
    }
}


// settings     0x110000
// pwds         0x110 000
// notify email 0x110 100

// code start at 0x110000
enum UpdatePasswordError : Int, Error, CustomErrorVar {
    case invalidUserName = 0x110001
    case invalidModulsID = 0x110002
    case invalidModuls = 0x110003
    case cantHashPassword = 0x110004
    case cantGenerateVerifier = 0x110005
    case cantGenerateSRPClient = 0x110006
    case invalideAuthInfo = 0x110007
    
    // mailbox password part
    case currentPasswordWrong = 0x110008
    case newNotMatch = 0x110009
    case passwordEmpty = 0x110010
    case keyUpdateFailed = 0x110011
    
    case `default` = 0x110000
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return NSLocalizedString("Change Password") //TODO:: check with jason for localization
    }
    
    var reason : String {
        switch self {
        case .invalidUserName:
            return NSLocalizedString("Invalid UserName!")
        case .invalidModulsID:
            return NSLocalizedString("Can't get a Moduls ID!")
        case .invalidModuls:
            return NSLocalizedString("Can't get a Moduls!")
        case .cantHashPassword:
            return NSLocalizedString("Invalid hashed password!")
        case .cantGenerateVerifier:
            return NSLocalizedString("Can't create a SRP verifier!")
        case .cantGenerateSRPClient:
            return NSLocalizedString("Can't create a SRP Client")
        case .invalideAuthInfo:
            return NSLocalizedString("Can't get user auth info")
        case .currentPasswordWrong:
            return NSLocalizedString("The Password is wrong.")
        case .newNotMatch:
            return NSLocalizedString("The new password not match.")
        case .passwordEmpty:
            return NSLocalizedString("The new password can't empty.")
        case .keyUpdateFailed:
            return NSLocalizedString("The private update failed.")
        case .default:
            return NSLocalizedString("Password update failed")
        }
    }
}


// code start at 0x110100
enum UpdateNotificationEmailError : Int, Error, CustomErrorVar {
    case invalidUserName = 0x110101
    case cantHashPassword = 0x110102
    case cantGenerateVerifier = 0x110103
    case cantGenerateSRPClient = 0x110104
    case invalideAuthInfo = 0x110105
    
    case `default` = 0x110100
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return NSLocalizedString("Update Notification Email") //TODO:: check with jason for localization
    }
    
    var reason : String {
        switch self {
        case .invalidUserName:
            return NSLocalizedString("Invalid UserName!")
        case .cantHashPassword:
            return NSLocalizedString("Invalid hashed password!")
        case .cantGenerateVerifier:
            return NSLocalizedString("Can't create a SRP verifier!")
        case .cantGenerateSRPClient:
            return NSLocalizedString("Can't create a SRP Client")
        case .invalideAuthInfo:
            return NSLocalizedString("Can't get user auth info")
        case .default:
            return NSLocalizedString("Password update failed")
        }
    }
}



