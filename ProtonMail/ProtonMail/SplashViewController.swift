//
//  WelcomeViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/14/15.
//
//

import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var signInButton: UIButton!
    
    private let kSegueToSignInWithNoAnimation = "splash_sign_in_no_segue"
    private let kSegueToSignIn = "splash_sign_in_segue"
    private let kSegueToSignUp = "splash_sign_up_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userCachedStatus.resetSplashCache()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func signUpAction(sender: UIButton) {
        self.performSegueWithIdentifier(kSegueToSignUp, sender: self)
    }
    
    @IBAction func signInAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToSignUp {
            let viewController = segue.destinationViewController as! SignUpUserNameViewController
            viewController.viewModel = SignupViewModelImpl()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}