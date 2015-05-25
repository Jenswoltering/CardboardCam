//
//  GlassViewController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import UIKit


class GlassViewController: UIViewController {
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var videoLayerLeft = CALayer()
    var videoLayerRight = CALayer()
    var image :CIImage?
    var context :CIContext!
    @IBOutlet weak var leftEye: UIView!
    @IBOutlet weak var leftEyeImage: UIImageView!
    @IBOutlet weak var rightEyeImage: UIImageView!
    @IBOutlet weak var rightEye: UIView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        videoLayerLeft.backgroundColor = UIColor.greenColor().CGColor
        videoLayerLeft.frame = leftEye.bounds
        videoLayerRight.frame = rightEye.bounds
        videoLayerLeft.position = leftEye.center
        videoLayerRight.position = rightEye.center
        videoLayerLeft.setNeedsDisplay()
        videoLayerRight.setNeedsDisplay()
        self.view.layer.addSublayer(videoLayerLeft)
        self.view.layer.addSublayer(videoLayerRight)
        //self.view.layer.addSubview(videoLayerRight)
        //leftEye.addSubview(videoLayerLeft)
        //rightEye.addSubview(videoLayerRight)
        // Do any additional setup after loading the view.
      
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateView(proimage :UIImage){
        NSLog("Update!")
        //CATransaction.begin()
        //self.videoLayerLeft.contents = self.appDelegate!.cbCamController.processedCameraImage
        //image = self.appDelegate!.cbCamController.processedCameraImage
            NSLog("UIImage")
            self.rightEyeImage.image = proimage
            self.videoLayerRight.contents = UIColor.redColor().CGColor
        //CATransaction.flush()
       // CATransaction.commit()
        
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
