//
//  Profile.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/13/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import Foundation

@objc(Profile)
class Profile: CBLModel
{
    //-------------------------------------------------------------------------
    //
    //  MARK: Class constants
    //
    //-------------------------------------------------------------------------
    
    static let kProfileDocType = "profile"
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Class methods
    //
    //-------------------------------------------------------------------------
    
    static func queryProfilesInDatabase(db:CBLDatabase) -> CBLQuery
    {
        let view = db.viewNamed("profiles")
        
        if view.mapBlock == nil
        {
            view.setMapBlock(
                { (doc:[String : Any], emit:CBLMapEmitBlock) in
                
                    if doc["type"] as? String == kProfileDocType
                    {
                        emit(doc["name"], nil);
                    }
                },
                version: "1")
        }
            
        return view.createQuery()
    }
    
    static func profileInDatabase(db:CBLDatabase, forExistinUserId userId:String) -> Profile?
    {
        let profileDocId = "p:\(userId)"
        
        if let doc = db.existingDocument(withID: profileDocId)
        {
            return Profile(for: doc)
        }
        
        return nil
    }
    
    static func profieInDatabase(db:CBLDatabase, forNewUserId userId:String, _ name:String) -> Profile?
    {
        if let doc = db.document(withID: "p:\(userId)")
        {
            let profile = Profile(for: doc)
            profile?.type = kProfileDocType
            profile?.name = name
            profile?.user_id = userId
            
            return profile
        }
        
        return nil
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Lifecycle
    //
    //-------------------------------------------------------------------------
    
    
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Properties
    //
    //-------------------------------------------------------------------------
    
    @NSManaged var user_id:String
    
    @NSManaged var name:String
//    
//     @objc dynamic var type:String?
}
