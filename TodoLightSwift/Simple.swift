//
//  Simple.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/16/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import Foundation

@objc(Simple)
class Simple : Titled
{
    override class var docType:String
    {
        return "simple"
    }
    
    @NSManaged var name:String?
    
    @NSManaged var owner:Profile?
}
