//
//  TouchIDCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/6/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//
import Foundation
import LocalAuthentication

class TouchIDCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    typealias ActionBlock = (_ cell: TouchIDCell?, _ newStatus: Bool) -> Void
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(_ sender: UISwitch) {
        if !userCachedStatus.isTouchIDEnabled {
            
            // try to enable touch id
            let context = LAContext()
            // Declare a NSError variable.
            var error: NSError?
            // Check if the device can evaluate the policy.
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                userCachedStatus.isTouchIDEnabled = true
            }
            else{
                var alertString : String = "";
                // If the security policy cannot be evaluated then show a short message depending on the error.
                switch error!.code{
                case LAError.Code.touchIDNotEnrolled.rawValue:
                    alertString = LocalString._general_touchid_not_enrolled
                case LAError.Code.passcodeNotSet.rawValue:
                    alertString = LocalString._general_passcode_not_set
                default:
                    // The LAError.TouchIDNotAvailable case.
                    alertString = LocalString._general_touchid_not_available
                }
                PMLog.D(alertString)
                PMLog.D("\(String(describing: error?.localizedDescription))")
                alertString.alertToast()
                switchView.isOn = false;
            }
        } else {
            userCachedStatus.isTouchIDEnabled = false
        }
    }
    
    func setUpSwitch(_ enabled : Bool, complete : ActionBlock) {
        switchView.isEnabled = true

        switchView.isOn = enabled;
        self.updateStatus()
    }
    
    func updateStatus() {

    }
}
