//
//  PendingDonationsDashboard.swift
//  hackathon-for-hunger
//
//  Created by Anas Belkhadir on 11/04/2016.
//  Copyright © 2016 Hacksmiths. All rights reserved.
//

import UIKit
import RealmSwift

class PendingDonationsDashboard: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl!
    var activityIndicator : ActivityIndicatorView!
    private let dashboardPresenter = DashboardPresenter(donationService: DonationService())
    var pendingDonations: Results<Donation>?

    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        dashboardPresenter.attachView(self)
        activityIndicator = ActivityIndicatorView(inview: self.view, messsage: "Syncing")
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(PendingDonationsDashboard.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        dashboardPresenter.fetch([DonationStatus.Pending.rawValue])
    }
    
    
    func refresh(sender: AnyObject) {
        self.startLoading()
        dashboardPresenter.fetchRemotely([DonationStatus.Pending.rawValue])
        refreshControl?.endRefreshing()
    }

    @IBAction func toggleMenu(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toDriverMapDetailPendingFromDashboard") {
            
            if let donation = sender as? Donation {
                let donationVC = segue.destinationViewController as! DriverMapDetailPendingVC
                donationVC.mapViewPresenter = MapViewPresenter(donationService: DonationService(), donation: donation)
            }
        }
        
        if (segue.identifier == "acceptedDonation") {
            
            if let donation = sender as? Donation {
                let donationVC = segue.destinationViewController as! DriverMapPickupVC
                
                donationVC.donation = donation
            }
        }

    }
    
    deinit {
        print("DEINITIALIZING")
    }
}

extension PendingDonationsDashboard:  UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingDonations?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let identifier = "pendingDonation"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! PendingDonationsDashboardTableViewCell
        cell.indexPath = indexPath
        cell.information = pendingDonations![indexPath.row]
        cell.addBorderTop(size: 1, color: UIColor.lightGrayColor())
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?
    {
        let accept = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Accept Donation" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            let donation = self.pendingDonations![indexPath.row]
            self.activityIndicator.title = "Accepting"
            self.dashboardPresenter.updateDonationStatus(donation, status: .Accepted)
        })
        accept.backgroundColor = UIColor(red: 20/255, green: 207/255, blue: 232/255, alpha: 1)
        
        
        return [accept]
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
        })
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("toDriverMapDetailPendingFromDashboard", sender: pendingDonations![indexPath.row])
    }
    
    //empty implementation
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
}

extension PendingDonationsDashboard: DashboardView {
    
    func startLoading() {
        self.activityIndicator.startAnimating()
    }
    
    func finishLoading() {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.title = "Syncing"
    }
    
    func donations(sender: DashboardPresenter, didSucceed donations: Results<Donation>) {
        self.finishLoading()
        self.pendingDonations = donations
        self.tableView.reloadData()
    }
    
    func donations(sender: DashboardPresenter, didFail error: NSError) {
        self.finishLoading()
        if error.code == 401 {
            let refreshAlert = UIAlertController(title: "Unable To Sync.", message: "Your session has expired. Please log back in", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                self.logout()
            }))
            presentViewController(refreshAlert, animated: true, completion: nil)
        }
    }
    
    func donationStatusUpdate(sender: DashboardPresenter, didSucceed donation: Donation) {
        self.finishLoading()
        let index = pendingDonations!.indexOf(donation)
        self.performSegueWithIdentifier("acceptedDonation", sender: donation)
        let indexPath = NSIndexPath(forRow: index!, inSection: 0)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    func donationStatusUpdate(sender: DashboardPresenter, didFail error: NSError) {
        self.finishLoading()
        if error.code == 401 {
            let refreshAlert = UIAlertController(title: "Unable To Sync.", message: "Your session has expired. Please log back in", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                self.logout()
            }))
            presentViewController(refreshAlert, animated: true, completion: nil)
        } else {
            let refreshAlert = UIAlertController(title: "Unable To Accept.", message: "Donation might have already been accepted. Resync your donations?.", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                self.startLoading()
                self.dashboardPresenter.fetchRemotely([DonationStatus.Pending.rawValue])
            }))
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
                
            }))
            presentViewController(refreshAlert, animated: true, completion: nil)
        }
        
    }
}





