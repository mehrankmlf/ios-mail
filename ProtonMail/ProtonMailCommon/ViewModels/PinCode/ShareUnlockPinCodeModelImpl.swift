//
//  ShareUnlockPinCodeModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

class ShareUnlockPinCodeModelImpl : PinCodeViewModel {
    
    let titleText : String = LocalString._enter_pin_to_unlock_inbox
    
    var currentStep : PinCodeStep = .enterPin
    
    var enterPin : String = ""
    
    override func title() -> String {
        return titleText
    }
    
    override func cancel() -> String {
        return LocalString._general_confirm_action
    }
    
    override func showConfirm() -> Bool {
        return false
    }
    
    override func confirmString () -> String {
        return ""
    }
    
    override func setCode (_ code : String) -> PinCodeStep {
        switch currentStep {
        case .enterPin:
            enterPin = code
            currentStep = .done
        case .reEnterPin, .done:
            break
        default:
            enterPin = ""
            currentStep = .enterPin
        }
        
        return currentStep
    }
    
    override func isPinMatched() -> Bool {
        if !enterPin.isEmpty && !userCachedStatus.pinCode.isEmpty && enterPin == userCachedStatus.pinCode {
            userCachedStatus.pinFailedCount = 0;
            return true
        } else {
            userCachedStatus.pinFailedCount += 1
            currentStep = .enterPin
            return false
        }
    }
    
    override func getPinFailedRemainingCount() -> Int {
        return 10 - userCachedStatus.pinFailedCount;
    }
    
    override func getPinFailedError() -> String {
        let c = 10 - userCachedStatus.pinFailedCount
        if c <= 1 {
            return "\(c) \(LocalString._attempt_remaining_until_secure_data_wipe)"
        } else if c < 4 {
            return "\(c) \(LocalString._attempts_remaining_until_secure_data_wipe)"
        }
        return "\(LocalString._incorrect_pin) \(c) \(LocalString._attempts_remaining)"
    }
    
    override func checkTouchID() -> Bool {
        return true
    }
}