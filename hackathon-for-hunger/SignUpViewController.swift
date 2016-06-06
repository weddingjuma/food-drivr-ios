//
//  SignUpViewController.swift
//  hackathon-for-hunger
//
//  Created by ivan lares on 4/4/16.
//  Copyright © 2016 Hacksmiths. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var driverImageView: UIImageView!
    @IBOutlet weak var donorImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageViews = [driverImageView!, donorImageView!]
        addImageViewGestureRecognizer(imageViews)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func cancelButtonClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /** Adds gesture recognizers to each image view in an array of passed in image
     *  views
     *
     *  @param imageViews - an array of imageviews
     *  @return None
     */
    func addImageViewGestureRecognizer(imageViews: [UIImageView]) {
        for imageView in imageViews {
            let gestureRecognizer = UIGestureRecognizer(target: imageView, action: "didTapImageView:")
            imageView.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func didTapImageView(sender: AnyObject) {
        let button = SignupButtons(rawValue: sender.tag)
        switch button! {
        case .Donor:
            performSegueWithIdentifier("ShowDonorSignup", sender: self)
        case .Driver:
            performSegueWithIdentifier("ShowDriverSignup", sender: self)
        }
    }
    
    /** Maps to the tap set in storyboard for these image view buttons.
     *
     */
    enum SignupButtons: Int {
        case Driver = 101,
             Donor
    }
    
}
