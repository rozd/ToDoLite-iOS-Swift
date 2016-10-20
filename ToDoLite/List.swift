//
//  List.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import Foundation

@objc(List)
class List: Titled
{
    //-------------------------------------------------------------------------
    //
    //  MARK: Class constants
    //
    //-------------------------------------------------------------------------
    
    static let kListDocType:String = "list"
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Class proeprties
    //
    //-------------------------------------------------------------------------
    
    override class var docType:String
    {
        return kListDocType
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Class methods
    //
    //-------------------------------------------------------------------------
    
    static func queryListsInDatabase(db:CBLDatabase) -> CBLQuery
    {
        let view:CBLView = db.viewNamed("lists")
        
        if view.mapBlock == nil
        {
            view.setMapBlock(
                {
                    (doc:[String : Any]!, emit:CBLMapEmitBlock!) in
                
                    print(doc)
                    
                    if doc["type"] as! String == kListDocType
                    {
                        emit(doc["title"]!, nil)
                    }
                },
                version: "1")
        }
        
        return view.createQuery()
    }
    
    static func updateAllListsInDatabase(db:CBLDatabase, withOwner owner:Profile) throws
    {
        let myLists:CBLQueryEnumerator!
            
        do
        {
            myLists = try List.queryListsInDatabase(db: db).run()
        }
        catch
        {
            return
        }
        
        for case let row as CBLQueryRow in myLists
        {
            if let doc = row.document
            {
                let list = List(for: doc)
                list?.owner = owner
                
                do
                {
                    try list?.save()
                }
                catch
                {
                    return
                }
            }
        }
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Properties
    //
    //-------------------------------------------------------------------------
    
    @NSManaged var owner:Profile
    
    @NSManaged var members:[String]
    
    //-------------------------------------------------------------------------
    //
    //  MARK: Methods
    //
    //-------------------------------------------------------------------------
    
    func addTaskWithTitle(title:String, withImage image:Data?, withImageContentType contentType:String) -> Task
    {
        let task = Task(forNewDocumentIn: self.database!)
        task.title = title
        task.list_id = self
        
        if image != nil
        {
            task.setImage(image: image!, contentType)
        }
        
        return task
    }
    
    // Returns a query for this list's tasks, in reverse chronological order.
    func queryTasks() -> CBLQuery
    {
        let view:CBLView = self.document!.database.viewNamed("tasksByDate")
        
        if view.mapBlock == nil
        {
            // On first query after launch, register the map function:
            view.setMapBlock(
                {
                    (doc:[String : Any], emit:CBLMapEmitBlock) in
                    
                    if doc["type"] as! String == Task.docType
                    {
                        let date = doc["created_at"]
                        let listID = doc["list_id"]
                        
                        emit([listID!, date!], doc)
                        
                        print("ok")
                    }
                },
                reduce: nil, version: "2") // bump version any time you change the MAPBLOCK body!
        }
        
        // Configure the query. Since it's in descending order, the startKey is the maximum key,
        // while the endKey is the _minimum_ key. (The empty object @{} is a placeholder that's
        // greater than any actual value.) Got that?
        let query = view.createQuery()
        query.descending = true
        let myListId = self.document?.documentID
        query.startKey = [myListId!, [:]]
        query.endKey = [myListId!]
        
        return query
    }
    
    func deleteList() throws -> Bool
    {
        let tasks:CBLQueryEnumerator = try queryTasks().run()

        for case let row as CBLQueryRow in tasks
        {
            try row.document?.currentRevision?.deleteDocument()
        }

        try self.deleteDocument()
        
        return true
    }
}
