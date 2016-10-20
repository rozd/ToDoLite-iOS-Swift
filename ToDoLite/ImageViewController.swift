//
//  ImageViewController.swift
//  TodoLightSwift
//
//  Created by Max Rozdobudko on 10/14/16.
//  Copyright © 2016 Max Rozdobudko. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController
{
    //-------------------------------------------------------------------------
    //
    //  MARK: - Properties
    //
    //-------------------------------------------------------------------------
    
    var image:UIImage!
    {
        didSet
        {
            self.imageView?.image = self.image
        }
    }
    
    // Outlets
    
    @IBOutlet weak var imageView:UIImageView!
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - View Controller Lifecycle
    //
    //-------------------------------------------------------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        self.imageView.image = self.image
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    //-------------------------------------------------------------------------
    //
    //  MARK: - Gesture Recognizer
    //
    //-------------------------------------------------------------------------
    
    func handleTap(recognizer:UITapGestureRecognizer)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
