//
//  TaskTableViewCell.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

@objc protocol TaskTableViewCellDelegate
{
    @objc optional func didSelectImageButton(button:UIButton, ofTask task:Task);
}

class TaskTableViewCell: UITableViewCell
{
    //-------------------------------------------------------------------------
    //
    //  MARK: - Properties
    //
    //-------------------------------------------------------------------------
    
    var task:Task!
    {
        willSet
        {
            self.nameLabel.text = newValue.title
            
            self.nameLabel.textColor = newValue.checked ? UIColor.gray : UIColor.black
            
            if let attachments = newValue.attachmentNames, attachments.count > 0
            {
                let firstAttachment = newValue.attachmentNamed(attachments[0])!
                
                let attachedImage = UIImage(data: firstAttachment.content!)
                
                self.imageButton.setImage(attachedImage, for: .normal)
            }
            else
            {
                self.imageButton.setImage(#imageLiteral(resourceName: "Camera-Light"), for: .normal)
            }
        }
    }
    
    // Outlets
    
    @IBOutlet weak var imageButton:UIButton!
    @IBOutlet weak var nameLabel:UILabel!
    
    // Delegates
    
    weak var delegate:TaskTableViewCellDelegate?
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Table View Cell Lifecycle
    //
    //-------------------------------------------------------------------------

    override func awakeFromNib()
    {
        super.awakeFromNib()
        
     
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Actions
    //
    //-------------------------------------------------------------------------

    @IBAction func imageButtonAction(_ sender: UIButton)
    {
        self.delegate?.didSelectImageButton?(button: sender, ofTask: self.task)
    }
}
