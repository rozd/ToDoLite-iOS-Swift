//
//  LoginViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 9/17/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit
import FBSDKLoginKit

protocol LoginViewControllerDelegate: class
{
    func didLoginAsGuest()
    func didLoginWithFacebookUser(userId:String, name:String, token:String)
    func didLogout();
}

class LoginViewController: UIViewController
{
    // MARK: Lifecycle
    
    // MARK: Properties
    
    weak var delegate:LoginViewControllerDelegate?
    
    lazy var facebookLoginManager:FBSDKLoginManager = FBSDKLoginManager.init();
    
    // MARK: ViewController lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    // MARK: Navigation
    
    func start()
    {
        print("Start")
    }
    
    // MARK: Facebook
    
    func loginWithFacebook(callback:@escaping (_ success:Bool, _ error:Error?) -> Void)
    {
        self.facebookLoginManager.logIn(withReadPermissions: ["email"], from: self)
        {
            (loginResult:FBSDKLoginManagerLoginResult?, error:Error?) in
            
            if error != nil || loginResult!.isCancelled
            {
                print(error);
                
                callback(false, error);
            }
            else
            {
                let graphRequest = FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields" : "name"])
                
                _ = graphRequest?.start(completionHandler: { (connection:FBSDKGraphRequestConnection?, result:Any?, error:Error?) in
                    if (error == nil)
                    {
                        self.observerFacebookAccessTokenChange()
                        self.facebookUserDidLoginWithToken(token: loginResult?.token, userInfo: result as! [String : AnyObject])
                        callback(true, nil)
                    }
                    else
                    {
                        self.facebookLoginManager.logOut()
                        callback(false, error)
                    }
                })
                
            }
        }
    }
    
    func logoutFacebook()
    {
        self.unobserveFacebookAccessTokenChange()
        self.facebookLoginManager.logOut()
        self.delegate?.didLogout()
    }
    
    func facebookUserDidLoginWithToken(token:FBSDKAccessToken?, userInfo info:[String:AnyObject])
    {
        assert(token != nil, "Facebook Access Token is nil")
        
        self.delegate?.didLoginWithFacebookUser(userId: token!.userID, name: info["name"] as! String, token: token!.tokenString)
    }
    
    func observerFacebookAccessTokenChange()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FBSDKAccessTokenDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.observerFacebookAccessTokenChange), name: NSNotification.Name.FBSDKAccessTokenDidChange, object: nil);
    }
    
    func unobserveFacebookAccessTokenChange()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FBSDKAccessTokenDidChange, object: nil)
    }
    
    // MARK: Actions
    
    @IBAction func facebookButtonTapped(_ sender: AnyObject)
    {
        self.loginWithFacebook
        {
            (success, error) in
            
            if success
            {
                self.start()
            }
            else
            {
                let app:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                app.showMessage(message: "Facebook Login Error. Please try again.", withTitle: "Error")
            }
        }
    }
    
    @IBAction func googleButtonTapped(_ sender: AnyObject)
    {
        
    }
    
    @IBAction func guestButtonTapped(_ sender: AnyObject)
    {
        self.delegate?.didLoginAsGuest()
        
        self.start()
    }
    
    // MARK: Notification handlers
    
    func facebookAccessTokenChnaged(notification:NSNotification)
    {
        let message = "Facebook token is expired. Please login again to review your session."
        
        let controller = UIAlertController(title: "Facebook", message: message, preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action:UIAlertAction) in
            self.logoutFacebook();
        }))
    }
}
