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


class GlassViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var videoLayerLeft = CALayer()
    var videoLayerRight = CALayer()
    var image :CIImage?
    var context :CIContext!
    var captureSession = AVCaptureSession()
    var customPreviewLayerLeft = CALayer()
    var customPreviewLayerRight = CALayer()
    var dataOutput = AVCaptureVideoDataOutput()
    var counter :Int = 0
    
    var queue:dispatch_queue_t = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
    @IBOutlet weak var leftEye: UIView!
    @IBOutlet weak var leftEyeImage: UIImageView!
    @IBOutlet weak var rightEyeImage: UIImageView!
    @IBOutlet weak var rightEye: UIView!
    
    func setupCamera(){
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedDataWithNotification:", name: "MPC_DidReceiveDataNotification", object: nil)
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            var err: NSError? = nil
            if let videoIn : AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &err) as? AVCaptureDeviceInput {
                if(err == nil){
                    if (captureSession.canAddInput(videoIn as AVCaptureInput)){
                        captureSession.addInput(videoIn as AVCaptureDeviceInput)
                        
                        if videoDevice.lockForConfiguration(nil){
                            for vFormat in videoDevice.formats {
                                
                                // 2
                                var ranges = vFormat.videoSupportedFrameRateRanges as! [AVFrameRateRange]
                                var frameRates = ranges[0]
                                
                                // 3
                                if frameRates.maxFrameRate == 120 {
                                    
                                    // 4
                                    
                                    videoDevice.activeFormat = vFormat as! AVCaptureDeviceFormat
                                    videoDevice.activeVideoMinFrameDuration = frameRates.minFrameDuration
                                    videoDevice.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                                    
                                    
                                }
                            }
                            videoDevice.setFocusModeLockedWithLensPosition(1.0, completionHandler: nil)
                            videoDevice.unlockForConfiguration()
                        }
                    }
                    else {
                        println("Failed add video input.")
                    }
                }
                else {
                    println("Failed to create video input.")
                }
            }
            else {
                println("Failed to create video capture device.")
            }
        }
        
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ]
        if (captureSession.canAddOutput(dataOutput)) {
            NSLog("can")
            captureSession.addOutput(dataOutput)
        }
        dataOutput.setSampleBufferDelegate(self, queue: self.queue)
        dataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true
        captureSession.commitConfiguration()
        
        
        
    }
    func startCapture(){
        
        captureSession.startRunning()
    }
    
    func handleReceiveDataWithNotification(notification:NSNotification){
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:NSData = userInfo["data"] as! NSData
        
        self.rightEyeImage.image = UIImage(data: receivedData)
        self.leftEyeImage.image = UIImage(data: receivedData)

    }
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        
        var imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0)
        
        var width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        var height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        var bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        var grayColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.None.rawValue)
        var context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, bitmapInfo)
        var dstImage = CGBitmapContextCreateImage(context)
        var uiDstImage = UIImage(CGImage: dstImage)
        var messageData = UIImageJPEGRepresentation(uiDstImage, 0.5)
        var error:NSError?
       
//        var imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
//        CVPixelBufferLockBaseAddress(imageBuffer,0)
//        var processedImage = processImage(imageBuffer, param1: 0, param2: 0)
//        //appDelegate!.cbCamController.setprocessedCameraImage(processedImage)
        dispatch_async(dispatch_get_main_queue()){
            //NSLog("test")
            self.appDelegate.mpcHandler.session.sendData(messageData, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, withMode: self.appDelegate.mpcHandler.mode, error: &error)
            if self.appDelegate.renderImage != nil {
                //self.videoLayerRight.contents = dstImage
                self.leftEyeImage.image = self.appDelegate.renderImage
                self.rightEyeImage.image = self.appDelegate.renderImage
                    //UIImage(data: messageData)
                //self.videoLayerLeft.contents = self.appDelegate.renderImage
            }
            //self.videoLayerRight.contents = dstImage
            //self.videoLayerLeft.contents=dstImage
        }
        
        
    }
    func processImage(sampleBuffer: CVPixelBuffer!, param1 :Int, param2:Int)->UIImage{
        var unprocessedImage = CIImage(CVPixelBuffer: sampleBuffer)
        let context = CIContext(options:nil)
        var filter : CIFilter = CIFilter(name:"CIGaussianBlur")
        var filterSat : CIFilter = CIFilter(name: "CIColorControls")
        
        if param1 == 0 && param2 == 0{
            filterSat.setValue(unprocessedImage, forKey: kCIInputImageKey)
            filterSat.setValue(1.0, forKey: kCIInputSaturationKey)
            filterSat.setValue(1.0, forKey: kCIInputBrightnessKey)
            let cgimg = context.createCGImage(filterSat.outputImage, fromRect: filterSat.outputImage.extent())
            let newImage = UIImage(CGImage: cgimg)
            return newImage!
        }else
        {
            var ciimage :CIImage = CIImage(CVPixelBuffer: sampleBuffer)
            filter.setDefaults()
            filter.setValue(unprocessedImage, forKey: kCIInputImageKey)
            filter.setValue(30, forKey: kCIInputRadiusKey)
            let cgimg = context.createCGImage(filter.outputImage, fromRect: filter.outputImage.extent())
            let newImage = UIImage(CGImage: cgimg)
            return newImage!
            
        }
    }

    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //videoLayerLeft.backgroundColor = UIColor.greenColor().CGColor
        videoLayerLeft.frame = leftEye.bounds
        videoLayerRight.frame = rightEye.bounds
        videoLayerLeft.position = leftEye.center
        videoLayerRight.position = rightEye.center
        videoLayerLeft.setNeedsDisplay()
        videoLayerRight.setNeedsDisplay()
        self.view.layer.addSublayer(videoLayerLeft)
        self.view.layer.addSublayer(videoLayerRight)
        self.setupCamera()
        self.startCapture()
      
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
