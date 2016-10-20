//
//  Task.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import Foundation

@objc(Task)
class Task : Titled
{
    //-------------------------------------------------------------------------
    //
    //  MARK: Class constants
    //
    //-------------------------------------------------------------------------
    
    static let kTaskDocType = "task"
    static let kTaskImageName = "image"
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Class properties
    //
    //-------------------------------------------------------------------------
    
    override class var docType:String
    {
        return kTaskDocType
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Properties
    //
    //-------------------------------------------------------------------------
    
    @NSManaged weak var list_id:List!
    
    @NSManaged var checked:Bool
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Methods
    //
    //-------------------------------------------------------------------------
    
    func setImage(image:Data, _ contentType:String)
    {
        setAttachmentNamed(Task.kTaskImageName, withContentType: contentType, content: image)
    }
    
    func deleteTask() throws -> Bool
    {
        try deleteDocument()
        
        return true
    }
}
