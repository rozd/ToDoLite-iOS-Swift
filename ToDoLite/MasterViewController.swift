//
//  MasterViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController
{
    //-------------------------------------------------------------------------
    //
    //  MARK: Lifecycle
    //
    //-------------------------------------------------------------------------
    
    deinit
    {
        self.liveQuery?.removeObserver(self, forKeyPath: "rows")
    }

    //-------------------------------------------------------------------------
    //
    //  MARK: Properties
    //
    //-------------------------------------------------------------------------
    
    var detailViewCotroller:DetailViewController?
    
    // Outlets
    
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    // Database
    
    var database:CBLDatabase!
    
    var liveQuery:CBLLiveQuery?
    
    var listResult:[Any]?

	//-------------------------------------------------------------------------
    //
    //  MARK: View Controller Lifecycle
    //
    //-------------------------------------------------------------------------
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.title = "ToDo Lists"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setup()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        self.loginButton.title = app.currentUserId != nil ? "Logout" : "Login"
        
        self.tableView.reloadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if let selected = self.tableView.indexPathForSelectedRow
        {
            self.tableView.deselectRow(at: selected, animated: false)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: -
    //
    //-------------------------------------------------------------------------
    
    //-----------------------------------
    //  MARK: Database
    //-----------------------------------
    
    
    // In this View Controller, we show an example of a Live Query
    // and KVO to update the Table View accordingly when data changed.
    // See DetailViewController and ShareViewController for
    // examples of a Live Query used with the CBLUITableSource api.
    func setup()
    {
        let app = UIApplication.shared.delegate as! AppDelegate
        
        self.database = app.database
        
        self.liveQuery = List.queryListsInDatabase(db: self.database!).asLive()
        self.liveQuery?.addObserver(self, forKeyPath: "rows", options: NSKeyValueObservingOptions(rawValue: UInt(0)), context: nil)
    }
    
    func createListWithTitile(title:String) -> List?
    {
//        let simple = Simple(forNewDocumentIn: self.database)
//        simple.type = "simple"
//        simple.name = title
//        
//        do
//        {
//            try simple.save()
//        }
//        catch
//        {
//            print("\(error.localizedDescription)")
//        }
//        
//        return nil
        
        let list = List(forNewDocumentIn: self.database)
        list.title = title
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if let currentUserId = app.currentUserId
        {
            let profile = Profile.profileInDatabase(db: self.database, forExistinUserId: currentUserId)
            list.owner = profile!
        }
        
        do
        {
            try list.save()
        }
        catch
        {
            app.showMessage(message: "Cannot create a new list", withTitle: "Error")
            return nil
        }
        
        print("after save")
        
        return list
    }
    
    //-----------------------------------
    //  MARK: Observers
    //-----------------------------------
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        self.listResult = self.liveQuery?.rows?.allObjects
        self.tableView.reloadData()
    }
    
    //-----------------------------------
    //  MARK: Navigation
    //-----------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showDetail"
        {
            if let indexPath = self.tableView.indexPathForSelectedRow
            {
                if let row = self.listResult?[indexPath.row] as? CBLQueryRow
                {
                    let list = List(for: row.document!)
                    
                    let controller = segue.destination as! DetailViewController
                    controller.list = list
                }
            }
        }
    }
    
    //-----------------------------------
    //  MARK: Buttons
    //-----------------------------------
    
    @IBAction func addButtonAction(_ sender: AnyObject)
    {
        let alert = UIAlertController(title: "New ToDo List", message: "Title for new list:", preferredStyle: .alert)
        
        alert.addTextField()
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action:UIAlertAction) in
            
            if let title = alert.textFields?.first?.text
            {
                _ = self.createListWithTitile(title: title)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func loginButtonAction(_ sender: AnyObject)
    {
        let app = UIApplication.shared.delegate as! AppDelegate
        
        app.logout()
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Table view data source
    //
    //-------------------------------------------------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.listResult != nil
        {
            return self.listResult!.count;
        }
        else
        {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "List", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        
        if let row = self.listResult?[indexPath.row] as? CBLQueryRow
        {
            cell.textLabel?.text = row.document?.property(forKey: "title") as! String?
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            if let row = self.listResult?[indexPath.row] as? CBLQueryRow
            {
                let app = UIApplication.shared.delegate as! AppDelegate
                
                let list = List(for: row.document!)
                
                if app.currentUserId == nil || app.currentUserId == list?.owner.user_id
                {
                    do
                    {
                        try _ = list?.deleteList()
                    }
                    catch
                    {
                        app.showMessage(message: error.localizedDescription, withTitle: "Error")
                    }
                }
                else
                {
                    app.showMessage(message: "Only the owner can delete the list.", withTitle: "Info")
                }
            }
            
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
}
