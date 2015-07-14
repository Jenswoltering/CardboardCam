//
//  initViewController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import UIKit

class initViewController: UIViewController {
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var nextButton: UIButton!
    var counterTimer :NSTimer!
    var counter:Int = 0 {
        didSet {
            let fractionalProgress = Float(counter) / 100.0
            let animated = counter != 0
            progressBar.setProgress(fractionalProgress, animated: animated)
            progressLabel.text = ("\(counter)%")
        }
    }
    
    func count(){
        if self.counter <= 99{
            self.counter++
        }else{
            sleep(1)
            counterTimer.invalidate()
            nextButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.cbCamController.cameraController.startCamera()
        appDelegate.cbCamController.setupTimer()
        appDelegate.cbCamController.startBeaconDetector()
        appDelegate.cbCamController.startMotionDetection()

        progressBar.setProgress(0, animated: true)
        progressLabel.text = "0%"
        counterTimer = NSTimer.scheduledTimerWithTimeInterval(0.045, target: self, selector: Selector("count"), userInfo: nil, repeats: true)
        self.counter = 0
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
