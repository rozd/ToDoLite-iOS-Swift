//
//  AppDelegate.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 9/17/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginViewControllerDelegate
{
    //------------------------------------------------------------------
    //
    // MARK: - Class constants
    //
    //------------------------------------------------------------------
    
//    static let kSyncGatewayUrl = "http://us-east.testfest.couchbasemobile.com:4984/todolite"
    static let kSyncGatewayUrl = "http://localhost:4984/todolite-swift"
    static let kSyncGatewayWebSocketSupport = true
    static let kGuestDBName = "guest"
    static let kStorageType = kCBLSQLiteStorage
    static let kEncryptionEnabled = false
    static let kEncryptionKey = "seekrit"
    static let kLoggingEnabled = true
    
    //------------------------------------------------------------------
    //
    // MARK: - Properties
    //
    //------------------------------------------------------------------
    
    var window: UIWindow?
    
    var currentUserId:String?
    {
        set {
            UserDefaults.standard.set(newValue, forKey: "user_id")
        }
        get {
            return UserDefaults.standard.object(forKey: "user_id") as? String
        }
    }
    
    var database:CBLDatabase?
    {
        willSet {
            self.willChangeValue(forKey: "database")
        }
        didSet {
            self.didChangeValue(forKey: "database")
        }
    }
    
    var loginViewController:LoginViewController!
    
    // Replication
    
    var push:CBLReplication?
    var pull:CBLReplication?
    
    var lastSyncError:NSError?
    
    //------------------------------------------------------------------
    //
    // MARK: - Methods
    //
    //------------------------------------------------------------------
    
    //------------------------------------
    // MARK: UIApplicationDelegate
    //------------------------------------
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions);
        
        self.loginViewController = self.window?.rootViewController as! LoginViewController
        self.loginViewController.delegate = self
        
        self.enableLogging()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        
        return handled;
    }

    //---------------------------------
    // MARK: Logging
    //---------------------------------
    
    func enableLogging()
    {
        if AppDelegate.kLoggingEnabled
        {
            CBLManager.enableLogging("Database")
            CBLManager.enableLogging("View")
            CBLManager.enableLogging("ViewVerbose")
            CBLManager.enableLogging("Query")
            CBLManager.enableLogging("Sync")
            CBLManager.enableLogging("SyncVerbose")
            CBLManager.enableLogging("ChnageTracker")
        }
    }
    
    //---------------------------------
    // MARK: Database
    //---------------------------------
    
    func databaseForName(name:String) -> CBLDatabase?
    {
        let dbName = "db\(name.md5().lowercased())"
        
        let option = CBLDatabaseOptions()
        option.create = true
        option.storageType = AppDelegate.kStorageType
        option.encryptionKey = AppDelegate.kEncryptionEnabled ? AppDelegate.kEncryptionKey : nil
        
        do
        {
            let database = try CBLManager.sharedInstance().openDatabaseNamed(dbName, with: option)
            
            return database;
        }
        catch let error
        {
            print("Cannot create database with an error : \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func databaseForUser(user:String?) -> CBLDatabase?
    {
        return user != nil ? databaseForName(name: user!) : nil;
    }
    
    func databaseForGuest() -> CBLDatabase?
    {
        return databaseForName(name: AppDelegate.kGuestDBName)
    }
    
    func migrateGuestDatabaseToUser(profile:Profile)
    {
        if let guestDB = self.databaseForGuest()
        {
            if guestDB.lastSequenceNumber > 0
            {
                var rows:CBLQueryEnumerator!
                
                do
                {
                    rows = try guestDB.createAllDocumentsQuery().run()
                }
                catch
                {
                    return
                }
                
                if let userDB = profile.database
                {
                    for case let row as CBLQueryRow in rows
                    {
                        if let doc = row.document
                        {
                            let newDoc = userDB.document(withID: doc.documentID)
                            
                            if let userProperties = doc.userProperties
                            {
                                do
                                {
                                    try newDoc?.putProperties(userProperties)
                                }
                                catch let error
                                {
                                    print("Error when saving a new document during migrating guest data : \(error.localizedDescription)")
                                    continue
                                }
                            }
                            
                            if let attachments = doc.currentRevision?.attachments
                            {
                                if attachments.count > 0
                                {
                                    let newRev = newDoc?.currentRevision?.createRevision()
                                    
                                    for att in attachments
                                    {
                                        newRev?.setAttachmentNamed(att.name, withContentType: att.contentType, content: att.content)
                                    }
                                    
                                    do
                                    {
                                        try newRev?.save()
                                    }
                                    catch let error
                                    {
                                        print("Error when saving an attachment during migrating guest data : \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                        
                        do
                        {
                            try List.updateAllListsInDatabase(db: profile.database!, withOwner: profile)
                        }
                        catch
                        {
                            print("Error when transfering the ownership of the list documents : \(error.localizedDescription)");
                        }
                        
                        do
                        {
                            try guestDB.delete()
                        }
                        catch
                        {
                            print("Error when deleting the guest database during migrating guest data : \(error.localizedDescription)")
                        }
                    }
                }
                
            }
        }
    }
    
    //---------------------------------
    // MARK: Replication
    //---------------------------------
    
    func startReplicationWithAuthenticator(authenticator:CBLAuthenticatorProtocol)
    {
        if (pull == nil && push == nil)
        {
            if let syncURL = NSURL(string: AppDelegate.kSyncGatewayUrl) as? URL
            {
                pull = database!.createPullReplication(syncURL)
                pull!.continuous = true;
             
                if !AppDelegate.kSyncGatewayWebSocketSupport
                {
                    pull?.customProperties = ["websocket" : false]
                }
                
                push = database!.createPushReplication(syncURL)
                push!.continuous = true;
                
                NotificationCenter.default
                    .addObserver(self, selector: #selector(AppDelegate.replicationProgress),
                                 name: Notification.Name.cblReplicationChange, object: pull!)
                
                NotificationCenter.default
                    .addObserver(self, selector: #selector(AppDelegate.replicationProgress),
                                 name: Notification.Name.cblReplicationChange, object: push!)
            }
        }
        
        push?.authenticator = authenticator;
        pull?.authenticator = authenticator;
        
        if (pull?.running)!
        {
            pull?.stop()
        }
        pull?.start()
        
        if (push?.running)!
        {
            push?.stop()
        }
        push?.start()
    }
    
    func stopReplication()
    {
        pull?.stop()
        
        do
        {
            try pull?.clearAuthenticationStores()
        }
        catch let error
        {
            print(error);
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.cblReplicationChange, object: pull)
        
        pull = nil
        
        push?.stop();
        
        do
        {
            try push?.clearAuthenticationStores()
        }
        catch let error
        {
            print(error);
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.cblReplicationChange, object: push)
        
        push = nil;
    }
    
    func replicationProgress(notification:NSNotification)
    {
        print("pull status: \(pull!.status.rawValue)")
        print("push status: \(push!.status.rawValue)")
        
        if (pull?.status == CBLReplicationStatus.active || push?.status == CBLReplicationStatus.active)
        {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        else
        {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        if let syncError = pull?.lastError as? NSError ?? push?.lastError as? NSError
        {
            if syncError != lastSyncError
            {
                lastSyncError = syncError
                
                if syncError.code == 404
                {
                    showMessage(message: "Authentication failed", withTitle: "Sync Error")
                    logout()
                }
                else
                {
                    showMessage(message: syncError.localizedDescription, withTitle: "Sync Error")
                }
            }
        }
    }
    
    //------------------------------------
    //  MARK: Login/Logout
    //------------------------------------
    
    func logout()
    {
        loginViewController.logoutFacebook()
    }
    
    // MARK: LoginViewControllerDelegate
    
    func didLoginAsGuest()
    {
        self.database = databaseForGuest()
        self.currentUserId = nil
    }
    
    func didLoginWithFacebookUser(userId:String, name:String?, token:String)
    {
        self.currentUserId = userId
        
        if let database = databaseForUser(user: userId)
        {
            self.database = database
            
            var profile = Profile.profileInDatabase(db: database, forExistinUserId: userId)
            
            if profile == nil
            {
                if name != nil
                {
                    profile = Profile.profieInDatabase(db: database, forNewUserId: userId, name!)
                    
                    guard profile != nil else
                    {
                        print("Cannot create a new user profile")
                        return
                    }
                    
                    do
                    {
                        try profile!.save()
                        
                        migrateGuestDatabaseToUser(profile: profile!)
                    }
                    catch
                    {
                        print("Cannot create a new user profile with error : \(error.localizedDescription)")
                    }
                }
                else
                {
                    print("Cannot create a new user profile as there is no name information.")
                }
            }
            
            if profile != nil
            {
                startReplicationWithAuthenticator(authenticator: CBLAuthenticator.facebookAuthenticator(withToken: token))
            }
            else
            {
                showMessage(message: "Cannot create a new user profile", withTitle: "Error")
            }
        }
    }
    
    func didLogout()
    {
        currentUserId = nil
        stopReplication()
        database = nil
        loginViewController.dismiss(animated: true, completion: nil)
    }

    // MARK: Alerts

    func showMessage(message:String, withTitle title:String)
    {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.window?.rootViewController?.present(controller, animated: true, completion: nil)
    }
}

