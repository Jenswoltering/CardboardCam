//
//  CBCamController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 25.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import UIKit
import Foundation
import CoreImage
import CoreGraphics
import CoreMedia


class CBCamController: NSObject,CameraSessionControllerDelegate {
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var cameraController : CameraSessionController!
    var frontCamera :UIImage!
    var motionKit :MotionKit!
    var beaconDetector :BeaconDetector!
    var backCamera :UIImage!
    var backCameraBuffer :[NSData]! = []
    var renderImage :UIImage!
    var useFilter1 :Bool!
    var isViewer :Bool!
    var isRunning :Bool!
    var useBackCamera :Bool!
    var filterStaerke :Double!
    var image :CIImage?
    var counter :Int = 0
    var messageData :NSData!
    let context = CIContext(options:[kCIContextUseSoftwareRenderer : false])
    var filter = CIFilter(name: "CIGaussianBlur")
    
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
    
    override init() {
        super.init()
        isViewer = true
        useBackCamera=true
        useFilter1 = false
        isRunning = true
        cameraController = CameraSessionController()
        cameraController.sessionDelegate = self
        motionKit = MotionKit()
    }
    
    func startMotionDetection(){
        motionKit.getAttitudeFromDeviceMotion(interval: 0.5) { (attitude) -> () in
            
            
        }
    }
    func stopMotionDetection(){
        motionKit.stopDeviceMotionUpdates()
    }
    
    func startBeaconDetector(){
        if isViewer==true{
            beaconDetector = BeaconDetector()
        }
    }
    
    func setFrontCameraImage(image :UIImage){
        self.frontCamera = image
    }
    
    func setBackCameraBufferImage(image :NSData){
        if (backCameraBuffer.count >= 15) {
            backCameraBuffer.removeAll(keepCapacity: false)
            backCameraBuffer.append(image)
        }else{
            backCameraBuffer.append(image)
        }
        
    }
    
    func setIsViewer(mode :Bool){
        self.isViewer = mode
    }
    
    
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        self.run()
        let outputImage :CIImage!
        var imageBuffer :CVImageBufferRef =  CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0)
        var ciImage = CIImage(CVPixelBuffer: imageBuffer)
        if (isViewer==true){
            if useFilter1 == true {
                outputImage = self.processImage(ciImage, effect: 0, value: 5)
                
            } else {
                outputImage =  ciImage
            }
                var cgImg = self.context.createCGImage(outputImage, fromRect: outputImage.extent())
                self.setFrontCameraImage(UIImage(CGImage: cgImg)!)
        }else{
                outputImage =  ciImage
                var cgImg = self.context.createCGImage(outputImage, fromRect: outputImage.extent())
                var uiImage = UIImage(CGImage: cgImg)
                var compressedImage = UIImageJPEGRepresentation(uiImage, 0.45)
                self.setBackCameraBufferImage(compressedImage!)
        }
        self.run()
    }
    
    
    func processImage(inputImage :CIImage, effect :Int, value :Double) -> CIImage{
        self.filter.setValue(inputImage, forKey: kCIInputImageKey)
        self.filter.setValue(value, forKey: kCIInputRadiusKey)
        return self.filter.outputImage
    }
    
    
    func run(){
            // Wenn Viewer dann lade Bild in den RenderBuffer
            if (isViewer == true){
                if (useBackCamera == true){
                    if (backCamera != nil){
                        renderImage=backCamera
                    }
                    
                    
                }else{
                    if (frontCamera != nil){
                        renderImage=frontCamera
                    }
                }
                
            }
            
            //Wenn Sender dann Sende Bild auf Kamerabuffer an Empfänger
            dispatch_sync(GlobalMainQueue, { () -> Void in
                if (self.isViewer==false) && (self.backCameraBuffer.isEmpty == false){
                    self.appDelegate.mpcHandler.session.sendData(self.backCameraBuffer.first, toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
                    self.backCameraBuffer.removeAtIndex(0)
                }

            })
        //UpdateGUI
      
    }
    
}