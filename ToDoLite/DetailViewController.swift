//
//  DetailViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController, UITextFieldDelegate, UIActionSheetDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate, TaskTableViewCellDelegate
{
    //-------------------------------------------------------------------------
    //
    //  MARK: - Class constants
    //
    //-------------------------------------------------------------------------
    
    static let kImageDataContentType = "image/jpeg"
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Lifecycle
    //
    //-------------------------------------------------------------------------
    
    deinit
    {
        self.liveQuery?.removeObserver(self, forKeyPath: "rows")
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Variables
    //
    //-------------------------------------------------------------------------
    
    private var taskToAddImageTo:Task?
    private var imageForNewTask:UIImage?
    private var imageToDisplay:UIImage?
    private var imagePickerPopover:UIPopoverPresentationController?
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Properties
    //
    //-------------------------------------------------------------------------
    
    var list:List!
    
    var database:CBLDatabase!
    
    var liveQuery:CBLLiveQuery?
    
    var tasks:[Any]?
    
    //-------------------------------------
    //  Outlets
    //-------------------------------------
    
    @IBOutlet weak var addItemTextField:UITextField!
    
    @IBOutlet weak var addImageButton:UIButton!
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - View Controller Livecycle
    //
    //-------------------------------------------------------------------------

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = self.list.title
        self.addImageButton?.isEnabled = true
        self.addItemTextField?.isEnabled = true
        
        self.liveQuery = self.list.queryTasks().asLive()
        self.liveQuery?.addObserver(self, forKeyPath: "rows", options: NSKeyValueObservingOptions(rawValue: UInt(0)), context: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        // Hide the share button if the current user is guest or is not the owner of the list:
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if app.currentUserId != self.list.owner.user_id
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        
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
    //  MARK: - Methods
    //
    //-------------------------------------------------------------------------
    
    //------------------------------------
    //  MARK: Controls
    //------------------------------------
    
    func updateAddImageButtonWithImage(image:UIImage?)
    {
        if image != nil
        {
            self.addImageButton.setImage(image, for: .normal)
        }
        else
        {
            self.addImageButton.setImage(UIImage(named: "Camera"), for: .normal)
        }
    }
    
    //------------------------------------
    //  MARK: Image picking
    //------------------------------------
    
    var hasCamera:Bool
    {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func displayAddImageActionSheetFor(sender:UIView, forTask task:Task?)
    {
        self.taskToAddImageTo = task
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler:
            {
                (action:UIAlertAction) in
                
                DispatchQueue.main.async
                {
                    self.displayImagePickerForSender(sender: sender, .camera)
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Choose Existing", style: .default, handler:
        {
            (action:UIAlertAction) in
            
            DispatchQueue.main.async
            {
                self.displayImagePickerForSender(sender: sender, .photoLibrary)
            }
        }))
        
        if imageForNewTask != nil
        {
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler:
            {
                (action:UIAlertAction) in
                
                if self.imageForNewTask != nil
                {
                    self.updateAddImageButtonWithImage(image: nil)
                    
                    self.imageForNewTask = nil
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func displayImagePickerForSender(sender:UIView, _ sourceType:UIImagePickerControllerSourceType)
    {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        
        // present the controller
        // on iPad, this will be a Popover
        // on iPhone, this will be an action sheet
        picker.modalPresentationStyle = .popover
        
        self.present(picker, animated: true, completion: nil)
        
        if let popover = picker.popoverPresentationController
        {
            popover.sourceView = sender
        }
    }
    
    //------------------------------------
    //  MARK: Utils
    //------------------------------------
    
    func dataForImage(image:UIImage) -> Data?
    {
        return UIImageJPEGRepresentation(image, 0.5)
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Observers
    //
    //-------------------------------------------------------------------------
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        self.tasks = self.liveQuery?.rows?.allObjects
        
        self.tableView.reloadData()
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Navigation
    //
    //-------------------------------------------------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "share"
        {
            let controller = segue.destination as! ShareViewController
            controller.list = self.list
        }
        else if segue.identifier == "showImage"
        {
            let controller = segue.destination as! ImageViewController
            controller.image = self.imageToDisplay
            
            imageToDisplay = nil
        }
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Actions
    //
    //-------------------------------------------------------------------------
    
    @IBAction func addImageButtonAction(_ sender: UIButton)
    {
        self.addItemTextField.resignFirstResponder()
        
        self.displayAddImageActionSheetFor(sender: sender, forTask: nil)
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Delegates
    //
    //-------------------------------------------------------------------------
    
    //----------------------------------
    //  MARK: UITextFieldDelegate
    //----------------------------------
    
    // Called when the text field's Return key is tapped.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if let title = addItemTextField?.text
        {
            addItemTextField?.text = nil
            
            let image = imageForNewTask != nil ? self.dataForImage(image: imageForNewTask!) : nil
            
            let task = self.list.addTaskWithTitle(title: title, withImage: image, withImageContentType: DetailViewController.kImageDataContentType)
            
            do
            {
                try task.save()
                
                imageForNewTask = nil
                
                self.updateAddImageButtonWithImage(image: nil)
            }
            catch
            {
                let app = UIApplication.shared.delegate as! AppDelegate
                
                app.showMessage(message: "Couldn't save new task due to : \(error.localizedDescription)", withTitle: "Error")
            }
        }
        
        textField.resignFirstResponder()
        
        return true
    }
    
    //----------------------------------
    //  MARK: UIImagePickerViewDelegate
    //----------------------------------
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        {
            if taskToAddImageTo != nil
            {
                taskToAddImageTo?.setImage(image: self.dataForImage(image: selectedImage)!, DetailViewController.kImageDataContentType)
                
                do
                {
                    try taskToAddImageTo?.save()
                }
                catch
                {
                    let app = UIApplication.shared.delegate as! AppDelegate
                    
                    app.showMessage(message: "Couldn't save the image to the task", withTitle: "Error")
                }
            }
            else
            {
                imageForNewTask = selectedImage
                
                self.updateAddImageButtonWithImage(image: selectedImage)
            }
        }
        
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //----------------------------------
    // MARK: Table View Datasource
    //----------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.tasks != nil ? self.tasks!.count : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Task", for: indexPath) as! TaskTableViewCell
        
        if let row = self.tasks?[indexPath.row] as? CBLQueryRow
        {
            let task = Task(for: row.document!);
            cell.task = task
            cell.delegate = self
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let row = self.tasks?[indexPath.row] as? CBLQueryRow
        {
            if let task = Task(for: row.document!)
            {
                task.checked = !task.checked
                
                do
                {
                    try task.save()
                }
                catch
                {
                    let app = UIApplication.shared.delegate as? AppDelegate
                    
                    app?.showMessage(message: "Failed to update the task", withTitle: "Error")
                }
            }
            
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            if let row = self.tasks?[indexPath.row] as? CBLQueryRow
            {
                let task = Task(for: row.document!)
                
                do
                {
                    try _ = task?.deleteTask()
                }
                catch
                {
                    let app = UIApplication.shared.delegate as! AppDelegate
                    
                    app.showMessage(message: "Can't delete task due to : \(error.localizedDescription)", withTitle: "Error")
                }
            }
            
            // Delete the row from the data source
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    //----------------------------------
    //  MARK: UIScrollViewDelegate
    //----------------------------------
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        self.addItemTextField.resignFirstResponder()
    }

    //----------------------------------
    //  MARK: TaskTableViewCellDelegate
    //----------------------------------
    
    func didSelectImageButton(button: UIButton, ofTask task: Task)
    {
        self.addItemTextField.resignFirstResponder()
        
        if let attachment = task.attachmentNamed("image")
        {
            self.imageToDisplay = UIImage(data: attachment.content!)
            
            self.performSegue(withIdentifier: "showImage", sender: self)
        }
        else
        {
            self.displayAddImageActionSheetFor(sender: button, forTask: task)
        }
    }
}
