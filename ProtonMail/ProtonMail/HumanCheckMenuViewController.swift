//
//  SignUpHumanCheckMenu.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/1/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//


import UIKit

class HumanCheckMenuViewController: UIViewController {
    
    fileprivate let kSegueToRecaptcha = "check_menu_to_recaptcha_verify_segue"
    fileprivate let kSegueToEmailVerify = "check_menu_to_email_verify_segue"
    fileprivate let kSegueToPhoneVerify = "check_menu_to_phone_verify_segue"
    
    @IBOutlet weak var recaptchaViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneViewConstraint: NSLayoutConstraint!
    
    fileprivate let kButtonHeight : CGFloat = 60.0
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSignUpFunctions()
    }
    
    internal func setupSignUpFunctions () {
        let directs = viewModel.getDirect()
        if directs.count <= 0 {
            let alert = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "signup human check error description when mobile signup disabled").alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        } else {
            for dir in directs {
                if dir == "captcha" {
                    recaptchaViewConstraint.constant = kButtonHeight
                } else if dir == "email" {
                    emailViewConstraint.constant = kButtonHeight
                } else if dir == "sms" {
                    phoneViewConstraint.constant = kButtonHeight
                }
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToRecaptcha {
            let viewController = segue.destination as! RecaptchaViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToEmailVerify {
            let viewController = segue.destination as! EmailVerifyViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToPhoneVerify {
            let viewController = segue.destination as! PhoneVerifyViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func recaptchaAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToRecaptcha, sender: self)
    }
    
    @IBAction func emailVerifyAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToEmailVerify, sender: self)
    }
    
    @IBAction func phoneVerifyAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToPhoneVerify, sender: self)
    }
    
}
