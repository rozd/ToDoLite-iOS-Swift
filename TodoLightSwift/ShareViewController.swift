//
//  ShareViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/15/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

class ShareViewController: UITableViewController, CBLUITableDelegate
{
    //-------------------------------------------------------------------------
    //
    //  MARK: - Variables
    //
    //-------------------------------------------------------------------------
    
    private var database:CBLDatabase!
    private var app:AppDelegate!
    private var myDocId:String!
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Properties
    //
    //-------------------------------------------------------------------------
    
    var list:List!
    {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    // Outlets
    
    @IBOutlet weak var dataSource:CBLUITableSource!
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - View Controller Lifecycle
    //
    //-------------------------------------------------------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.app = UIApplication.shared.delegate as! AppDelegate
        self.database = app.database
        self.myDocId = "p:\(app.currentUserId)"
        
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //-------------------------------------------------------------------------
    //
    //  MARK: - Methods
    //
    //-------------------------------------------------------------------------
    
    func configureView()
    {
        self.dataSource.query = Profile.queryProfilesInDatabase(db: self.database).asLive()
        self.dataSource.labelProperty = "name"
        self.dataSource.deletionAllowed = false
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Delegates
    //
    //-------------------------------------------------------------------------

    //------------------------------------
    //  MARK: CBLUITableDelegate
    //------------------------------------
    
    func couchTableSource(_ source: CBLUITableSource, willUse cell: UITableViewCell, for row: CBLQueryRow)
    {
        let personId = row.document!.documentID
        
        // if the person's id is in the list of members, or is the owner we are happy.
        var isMember = false
        
        if myDocId == personId
        {
            isMember = true
        }
        else
        {
            let intersection = NSMutableSet(array: list.members)
            intersection.intersect(Set([myDocId]))
            
            isMember = intersection.count > 0
        }
        
        if isMember
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }
    }
    
    //------------------------------------
    //  MARK: UITableViewDelegate
    //------------------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let row = self.dataSource.row(at: indexPath)
        {
            let toggleMemberID = row.document!.documentID
            
            var members:[String] = list.members 
            
            let index = members.index(of: toggleMemberID)
            
            if index == NSNotFound
            {
                members.append(toggleMemberID)
                
                list.members = members
            }
            else
            {
                list.members = members.filter({ $0 != toggleMemberID })
            }
        }
    }
}
