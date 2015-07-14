//
//  MPCHandler.swift
//  TicTacToe
//
//  Created by Training on 12/09/14.
//  Copyright (c) 2014 Training. All rights reserved.
//

import UIKit
import MultipeerConnectivity


class MPCHandler: NSObject, MCSessionDelegate, NSStreamDelegate {
   
    var peerID:MCPeerID!
    var session:MCSession!
    var browser:MCBrowserViewController!
    var advertiser:MCAdvertiserAssistant? = nil
    var mode = MCSessionSendDataMode.Unreliable
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    
    func setupPeerWithDisplayName (displayName:String){
        peerID = MCPeerID(displayName: displayName)
    }
    
    func setupSession(){
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        session = MCSession(peer: peerID)
        session.delegate = self
    }
    
    func setupBrowser(){
        browser = MCBrowserViewController(serviceType: "CBC", session: session)
    
    }
    
    func advertiseSelf(advertise:Bool){
        if advertise{
            advertiser = MCAdvertiserAssistant(serviceType: "CBC", discoveryInfo: nil, session: session)
            advertiser!.start()
        }else{
            advertiser!.stop()
            advertiser = nil
        }
    }
    
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        let userInfo = ["peerID":peerID,"state":state.rawValue]
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("MPC_DidChangeStateNotification", object: nil, userInfo: userInfo)
        })
        
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        if (self.appDelegate.cbCamController.isViewer == true){
            let userInfo = ["data":data, "peerID":peerID]
            let receivedData:NSData = userInfo["data"] as! NSData
            var backCameraBuffer =  NSKeyedUnarchiver.unarchiveObjectWithData(receivedData)! as! [NSData]
            dispatch_barrier_sync(appDelegate.criticQueue, { () -> Void in
                self.appDelegate.cbCamController.backCameraBuffer = backCameraBuffer
            })
            
        }
        if (self.appDelegate.cbCamController.isViewer == false){
            if data != nil{
                let parameters = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
                appDelegate.cbCamController.useBackCamera = parameters.objectForKey("useBackCamera")!.boolValue
                appDelegate.cbCamController.useFilter = parameters.objectForKey("useFilter")!.boolValue
                appDelegate.cbCamController.xMotion = parameters.objectForKey("xMotion")!.doubleValue
                appDelegate.cbCamController.yMotion = parameters.objectForKey("yMotion")!.doubleValue
                appDelegate.cbCamController.zMotion = parameters.objectForKey("zMotion")!.doubleValue
                
                if (parameters.objectForKey("filterName")!.description != "keinFilter"){
                    var alleFilter = appDelegate.cbCamController.filterWrapper
                    for einFilter in alleFilter {
                        if einFilter.name() == parameters.objectForKey("filterName")!.description{
                            appDelegate.cbCamController.filterToUse = einFilter
                        }
                    }
                }
                if appDelegate.cbCamController.useFilter == true{
                    if appDelegate.cbCamController.filterToUse.name() == appDelegate.cbCamController.filterColorCross.name(){
                        appDelegate.cbCamController.updateVectors()
                    }
                }
                
            }
        }
    }
    
        
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
//        stream.delegate=self
//        stream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
//        stream.open()
//        dispatch_async(dispatch_get_main_queue(), {
//            if (stream.hasBytesAvailable){
//                NSLog("HallO")
//            }
//
//        })
    }
    
    
    
    
}
