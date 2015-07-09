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
    typealias CIParameters = Dictionary<String, AnyObject>
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var cameraController : CameraSessionController!
    var frontCamera :UIImage!
    var motionKit :MotionKit!
    var beaconDetector :BeaconDetector!
    var backCamera :UIImage!
    var backCameraBuffer :[NSData] = []
    var backCameraBufferTransmit :[String:AnyObject] = ["":""]
    var renderImage :UIImage!
    var drehung :Double = 0
    var filterToUse :CIFilter!
    var useFilter :Bool!
    var isViewer :Bool!
    var isRunning :Bool!
    var useBackCamera :Bool = true
    var image :CIImage?
    var counter :Int = 0
    var pulsingDirection :Bool = true
    var pulsingValue :Double = 0
    var messageData :NSData!
    var messageTimer  = NSTimer()
    var frameTimer = NSTimer()
    var buffer :Int = 0
    let context = CIContext(options:[kCIContextUseSoftwareRenderer : false])
    let parametersTorus : CIParameters = [
        kCIInputRadiusKey:100,
        kCIInputCenterKey:CIVector(CGPoint: CGPoint(x: 320, y: 240) ),
        kCIInputScaleKey:0.5,
        ]
    let parametersPinch : CIParameters = [
        kCIInputRadiusKey:160,
        kCIInputCenterKey:CIVector(CGPoint:CGPoint(x: 320, y: 240)),
        kCIInputScaleKey:0.5,
       ]
    
    var filterMonochrome = CIFilter(name: "CIColorMonochrome")
    //var filterTorusLensDistortion = CIFilter(name: "CITorusLensDistortion")
    var filterTorusLensDistortion :CIFilter!
    var filterColroInvert = CIFilter(name: "CIColorInvert")
    //var filterPinchDistortion = CIFilter(name: "CIPinchDistortion")
    var filterPinchDistortion :CIFilter!
    var filterColorCross = CIFilter(name: "CIColorCrossPolynomial")
    var filterWrapper:[CIFilter]!
    
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
        useFilter = false
        isRunning = true
        cameraController = CameraSessionController()
        cameraController.sessionDelegate = self

        self.filterPinchDistortion = CIFilter(name: "CIPinchDistortion", withInputParameters: self.parametersPinch)
        //self.filterTorusLensDistortion = CIFilter(name: "CITorusLensDistortion", withInputParameters: self.parametersTorus)
        //FilterMonochrom
        self.filterMonochrome.setValue(CIColor(red: 0.0, green: 0.0, blue: 1.0), forKey: kCIInputColorKey)
        self.filterMonochrome.setValue(1.0, forKey: kCIInputIntensityKey)
        filterWrapper = [filterPinchDistortion,filterMonochrome,filterColroInvert,filterColorCross]
        //FilterTorusLensDistortion
//        var center = CGPoint(x: 320, y: 240)
//        self.filterTorusLensDistortion.setValue(CIVector(CGPoint: center), forKey: kCIInputCenterKey)
//        self.filterTorusLensDistortion.setValue(160, forKey: kCIAttributeTypeDistance)
        //FilterColorInvert
        //nichts zu Konfigurieren
        //Filter PinchDistortion
//        self.filterPinchDistortion.setValue([320, 240], forKey: kCIAttributeTypePosition)
//        self.filterPinchDistortion.setValue(160, forKey: kCIAttributeTypeDistance)
//        self.filterPinchDistortion.setValue(0.5, forKey: kCIAttributeTypeScalar)
    }
    
    func setupTimer(){
        if self.isViewer == true {
            messageTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("sendStatusMessage"), userInfo: nil, repeats: true)
        }
    }
    
    
    //Kann weg
    func filterPulsing()->Double{
        if pulsingDirection == true {
            pulsingValue=pulsingValue+0.1
            if pulsingValue >= 10{
                pulsingDirection=false
            }
        }else{
            pulsingValue=pulsingValue-0.1
            if pulsingValue <= 0{
                pulsingDirection=true
            }

        }
        return pulsingValue
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
        if (backCameraBuffer.count >= 5) {
            var buffer = NSKeyedArchiver.archivedDataWithRootObject(backCameraBuffer)
            self.appDelegate.mpcHandler.session.sendData(buffer, toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
            backCameraBuffer.removeAll(keepCapacity: false)
            backCameraBuffer.append(image)
        }else{
            backCameraBuffer.append(image)
        }
        
    }
    
    func setIsViewer(mode :Bool){
        self.isViewer = mode
    }
    
    func sendStatusMessage(){
        dispatch_async(GlobalUserInitiatedQueue, { () -> Void in
            self.appDelegate.mpcHandler.session.sendData(self.prepareParameterForMessage(), toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
        })

    }
    
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        self.run()
        let outputImage :CIImage!
        var imageBuffer :CVImageBufferRef =  CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0)
        var ciImage = CIImage(CVPixelBuffer: imageBuffer)
        if useFilter == true {
            outputImage = self.processImage(ciImage, value: 0.39)
            
        } else {
            outputImage =  ciImage
        }
        var cgImg = self.context.createCGImage(outputImage, fromRect: outputImage.extent())
        
        
        
        if (isViewer==true){
                self.setFrontCameraImage(UIImage(CGImage: cgImg)!)
        }else{
            dispatch_sync(GlobalMainQueue, { () -> Void in
                var uiImage = UIImage(CGImage: cgImg)
                var compressedImage = UIImageJPEGRepresentation(uiImage, 0.4)
                self.setBackCameraBufferImage(compressedImage!)
            })
        }
        self.run()
    }
    
    
    func processImage(inputImage :CIImage, value :Double) -> CIImage{
            self.filterToUse.setValue(inputImage, forKey: kCIInputImageKey)
            return self.filterToUse.outputImage
    }
    
    func prepareParameterForMessage() -> NSData{
        var parameters :NSDictionary
        if self.useFilter == true {
             parameters  = ["useBackCamera": self.useBackCamera.description, "useFilter":self.useFilter.description, "filterName": self.filterToUse.name()]
            
        }else{
            parameters  = ["useBackCamera": self.useBackCamera.description, "useFilter":self.useFilter.description, "filterName": "keinFilter"]
        }
        var parameterMessage = NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        return parameterMessage!
        
    }
    
    func run(){
            // Wenn Viewer dann lade Bild in den RenderBuffer
            if (isViewer == true){
                if (useBackCamera == true){
                    if (backCameraBuffer.isEmpty == false){
                        renderImage=UIImage(data:backCameraBuffer.first!)
                        backCameraBuffer.removeAtIndex(0)
                    }
                }else{
                    if (frontCamera != nil){
                        renderImage=frontCamera
                    }
                }
            }
            //Wenn Sender dann Sende Bild auf Kamerabuffer an Empfänger
            if (self.isViewer==false) && (self.backCameraBuffer.isEmpty == false){
                
//                dispatch_async(GlobalMainQueue, { () -> Void in
//                    if self.buffer == 12 {
//                        self.appDelegate.mpcHandler.session.sendData(self.backCameraBuffer.first, toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
//                    self.buffer = 0
//                    }else{
//                        self.buffer = self.buffer + 1
//                    }
//                    self.backCameraBuffer.removeAtIndex(0)
//                })

            }
        //UpdateGUI
      
    }
    
}