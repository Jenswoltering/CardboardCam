//
//  ViewController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 21.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ConnectionViewController: UIViewController,MCBrowserViewControllerDelegate {
    
    var appDelegate:AppDelegate!
    
    @IBOutlet weak var startButton: UIBarButtonItem!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var controllerLabel: UILabel!
    @IBOutlet weak var participantLabel: UILabel!
    
    @IBOutlet weak var senderSwitch: UISwitch!
    @IBOutlet weak var empfaengerSwitch: UISwitch!
    @IBAction func connectDevices(sender: AnyObject) {
        if appDelegate.mpcHandler.session != nil{
            appDelegate.mpcHandler.setupBrowser()
            appDelegate.mpcHandler.browser.delegate = self
            self.presentViewController(appDelegate.mpcHandler.browser, animated: true, completion: nil)
            
        }

    }
    
    @IBAction func empfaengerChanged(sender: UISwitch) {
        if (empfaengerSwitch.on == true){
            senderSwitch.setOn(false,animated :true)
        }else{
            senderSwitch.setOn(true,animated :true)
        }
        NSLog(empfaengerSwitch.on.description)
        appDelegate.cbCamController.setIsViewer(empfaengerSwitch.on)
        
    }
    
    @IBAction func senderChanged(sender: UISwitch) {
        if (senderSwitch.on == true){
            empfaengerSwitch.setOn(false,animated :true)
        }else{
            empfaengerSwitch.setOn(true,animated :true)
        }

        NSLog(empfaengerSwitch.on.description)
        appDelegate.cbCamController.setIsViewer(empfaengerSwitch.on)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.mpcHandler.setupPeerWithDisplayName(UIDevice.currentDevice().name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "peerChangedStateWithNotification:", name: "MPC_DidChangeStateNotification", object: nil)
        
               
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func peerChangedStateWithNotification(notification:NSNotification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        
        let state = userInfo.objectForKey("state") as! Int
        
        if state == MCSessionState.Connected.rawValue{
            self.navigationItem.title = "Connected"
            startButton.enabled = true
            headlineLabel.hidden = false
            controllerLabel.hidden = false
            participantLabel.hidden = false
            senderSwitch.hidden = false
            empfaengerSwitch.hidden = false
            appDelegate.cbCamController = CBCamController()
            appDelegate.cbCamController.isViewer = empfaengerSwitch.on
                      
                    }
        if state == MCSessionState.NotConnected.rawValue{
            self.navigationItem.title = "Not Connected"
            startButton.enabled = false
            headlineLabel.hidden = true
            controllerLabel.hidden = true
            participantLabel.hidden = true
            senderSwitch.hidden = true
            empfaengerSwitch.hidden = true
           
        }
        if state == MCSessionState.Connecting.rawValue{
            self.navigationItem.title = "Connecting"
            startButton.enabled = false
            headlineLabel.hidden = true
            controllerLabel.hidden = true
            participantLabel.hidden = true
            senderSwitch.hidden = true
            empfaengerSwitch.hidden = true
        }
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController!) {
        appDelegate.mpcHandler.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController!) {
        appDelegate.mpcHandler.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}

