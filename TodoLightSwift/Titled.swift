//
//  Titled.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import Foundation

@objc(Titled)
class Titled: CBLModel
{
    //-------------------------------------------------------------------------
    //
    //  MARK: Class constants
    //
    //-------------------------------------------------------------------------
    
    class var docType:String
    {
        assert(false, "Unimplemented method +[\(self) docType]")
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Properties
    //
    //-------------------------------------------------------------------------
 
    @NSManaged var title:String
    
    @NSManaged var created_at:Date?
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Overridden properties
    //
    //-------------------------------------------------------------------------
    
    override var description: String
    {
        return "\(type(of: self))[\(self.document?.abbreviatedID) \(self.title)]"
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Methods
    //
    //-------------------------------------------------------------------------
    
    override func awakeFromInitializer()
    {
        self.type = type(of: self).docType
        
        if self.created_at == nil
        {
            self.created_at = Date()
        }
    }
}
