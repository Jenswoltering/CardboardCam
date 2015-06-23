//
//  GlassViewController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics
import MultipeerConnectivity


class GlassViewController: UIViewController{
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var videoLayerLeft = CALayer()
    var videoLayerRight = CALayer()
    var didLoad = false
    var customPreviewLayerLeft = CALayer()
    var customPreviewLayerRight = CALayer()
    var counter :Int = 0
    var timer  = NSTimer()
    let animationDuration : NSTimeInterval = 1.0

    
    var GlobalMainQueue: dispatch_queue_t {
        return dispatch_get_main_queue()
    }
    
    var GlobalUserInteractiveQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
    }
    
    var GlobalUserInitiatedQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
    }
    
    var GlobalUtilityQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
    }
    
    var GlobalBackgroundQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
    }
    
    @IBOutlet weak var leftEye: UIView!
    @IBOutlet weak var leftEyeImage: UIImageView!
    @IBOutlet weak var rightEyeImage: UIImageView!
    @IBOutlet weak var rightEye: UIView!
    
    func updateImages(){
        //if appDelegate.cbCamController.renderImage. .isEmpty != true {
        leftEyeImage.image=appDelegate.cbCamController.renderImage
        rightEyeImage.image=appDelegate.cbCamController.renderImage
        //}

    }
    
    override func viewDidLoad() {
        //super.viewDidLoad()
//        videoLayerLeft.frame = leftEye.bounds
//        videoLayerRight.frame = rightEye.bounds
//        videoLayerLeft.position = leftEye.center
//        videoLayerRight.position = rightEye.center
//        videoLayerLeft.setNeedsDisplay()
//        videoLayerRight.setNeedsDisplay()
//        self.view.layer.addSublayer(videoLayerLeft)
//        self.view.layer.addSublayer(videoLayerRight)
//        didLoad = true
//        updateImages()
//        leftEyeImage.animationDuration=animationDuration
//        rightEyeImage.animationDuration=animationDuration
//        leftEyeImage.startAnimating()
//        rightEyeImage.startAnimating()
        if appDelegate.cbCamController.isViewer == true {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.04, target: self, selector: Selector("updateImages"), userInfo: nil, repeats: true)
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
