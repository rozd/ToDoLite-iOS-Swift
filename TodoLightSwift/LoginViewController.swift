//
//  LoginViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 9/17/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

protocol LoginViewControllerDelegate: class
{
    func didLoginAsGuest()
    func didLoginWithFacebookUser(userId:String, name:String, token:String)
    func didLogout();
}

class LoginViewController: UIViewController
{
    // MARK: Lifecycle
    
    // MARK: ViewController lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Actions
    
    @IBAction func loginWithFacebook(_ sender: AnyObject)
    {
        
    }
    
    @IBAction func loginWithGoogle(_ sender: AnyObject)
    {
        
    }
    
    @IBAction func loginAsGuest(_ sender: AnyObject)
    {
        
    }
}
