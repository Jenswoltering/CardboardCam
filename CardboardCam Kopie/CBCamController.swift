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
    var beaconDetector :BeaconDetector!
    var backCamera :UIImage!
    var backCameraBuffer :[NSData] = []
    var backCameraBufferTransmit :[String:AnyObject] = ["":""]
    var filterCollection :FilterCollection!
    var renderImage :UIImage!
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
    var GUITimer = NSTimer()
    var frameTimer = NSTimer()
    var buffer :Int = 0
    let context = CIContext(options:[kCIContextUseSoftwareRenderer : false])
    //======================================================================
    //Filter deklarieren
    var filterMonochrome :CIFilter!
    //var filterTorusLensDistortion :CIFilter!
    var filterColorInvert :CIFilter!
    var filterPinchDistortion :CIFilter!
    var filterBumbDistortion : CIFilter!
    var filterColorCross :CIFilter!
    var filterWrapper:[CIFilter]!
    //=====================================================================
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
        filterCollection = FilterCollection()
        self.filterMonochrome = filterCollection.colorMonochrome(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), intensity: 1.0)
        self.filterPinchDistortion = filterCollection.pinchDistortion(CGPoint(x: 320, y: 240), radius: 160, scale: 0.5)
        self.filterBumbDistortion = filterCollection.bumpDistortion(CGPoint(x: 320, y: 240), radius: 200, scale: 3)
        self.filterColorInvert = filterCollection.flipFilter()
        //self.filterTorusLensDistortion = filterCollection.torusLensDistortion(CGPoint(x: 320, y: 240), radius: 100, width: 20, refraction: 0.5)
        var redArray : [CGFloat] = [0.7,1,0.4,0.3,1,0,0.1,0,0]
        var greenArray :[CGFloat] = [0,1,0.2,0,0,1,0,0.4,0]
        var blueArray :[CGFloat] = [1,0,0.9,0.8,0.9,0,0,1,0]
        var redVector = CIVector(values: redArray, count: Int(redArray.count))
        var greenVector = CIVector(values: greenArray, count: Int(greenArray.count))
        var blueVector = CIVector(values: blueArray, count: Int(blueArray.count))
        self.filterColorCross = filterCollection.colorCrossPolynomial(redVector, greenCoefficients: greenVector, blueCoefficients: blueVector)
        filterWrapper = [filterPinchDistortion,filterMonochrome,filterColorInvert,filterColorCross,filterBumbDistortion]
    }
    
    func setupTimer(){
        if self.isViewer == true {
            messageTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("sendStatusMessage"), userInfo: nil, repeats: true)
            GUITimer = NSTimer.scheduledTimerWithTimeInterval(0.035, target: self, selector: Selector("run"), userInfo: nil, repeats: true)
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
        if (backCameraBuffer.count >= 3) {
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
            dispatch_barrier_sync(appDelegate.criticQueue, { () -> Void in
                var uiImage = UIImage(CGImage: cgImg)
                var compressedImage = UIImageJPEGRepresentation(uiImage, 0.4)
                self.setBackCameraBufferImage(compressedImage!)
            })
        }
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
                        dispatch_barrier_sync(appDelegate.criticQueue, { () -> Void in
                            self.renderImage=UIImage(data:self.backCameraBuffer.first!)
                            if (self.backCameraBuffer.isEmpty == false){
                                self.backCameraBuffer.removeAtIndex(0)
                            }
                        })
                    }
                }else{
                    if (frontCamera != nil){
                        renderImage=frontCamera
                    }
                }
            }
            //Wenn Sender dann Sende Bild auf Kamerabuffer an Empfänger
            if (self.isViewer==false) && (self.backCameraBuffer.isEmpty == false){
                
            }
            //UpdateGUI
      
    }
    
}