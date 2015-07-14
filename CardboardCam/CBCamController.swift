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
    var xMotion :Double!
    var yMotion :Double!
    var zMotion :Double!
    var isRunning :Bool!
    var motionKit :MotionKit!
    var useBackCamera :Bool = true
    var image :CIImage?
    var showIntro :Bool!
    var counter :Int = 0
    var messageData :NSData!
    var messageTimer  = NSTimer()
    var GUITimer = NSTimer()
    var frameTimer = NSTimer()
    var buffer :Int = 0
    var imagesForAnimation :[UIImage] = []
    var imagesForAnimationBuffer :[UIImage] = []
    let context = CIContext(options:[kCIContextUseSoftwareRenderer : false])
    //======================================================================
    //Filter deklarieren
    var filterMonochrome :CIFilter!
    //var filterTorusLensDistortion :CIFilter!
    var filterColorInvert :CIFilter!
    var filterPinchDistortion :CIFilter!
    var filterBumbDistortion : CIFilter!
    var filterColorCross :CIFilter!
    var filterFlipHori :CIFilter!
    var filterFlipVerti :CIFilter!
    
    var filterWrapper:[CIFilter]!
    
    
    
    var redArray : [CGFloat]!
    var greenArray : [CGFloat]!
    var blueArray : [CGFloat]!
    var greenVector :CIVector!
    var blueVector :CIVector!
    var redVector :CIVector!
    
    
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
        showIntro = true
        isRunning = true
        self.xMotion = 1
        self.yMotion = 0
        self.zMotion = 0
        cameraController = CameraSessionController()
        cameraController.sessionDelegate = self
        filterCollection = FilterCollection()
        self.filterMonochrome = filterCollection.colorMonochrome(UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), intensity: 1.0)
        self.filterPinchDistortion = filterCollection.pinchDistortion(CGPoint(x: 320, y: 240), radius: 160, scale: 0.5)
        self.filterBumbDistortion = filterCollection.bumpDistortion(CGPoint(x: 320, y: 240), radius: 200, scale: 3)
        self.filterColorInvert = filterCollection.colorInvent()
        self.filterFlipHori = filterCollection.flipHorizontalFilter()
        self.filterFlipVerti = filterCollection.flipVertikalFilter()
        //self.filterTorusLensDistortion = filterCollection.torusLensDistortion(CGPoint(x: 320, y: 240), radius: 100, width: 20, refraction: 0.5)
        redArray = [CGFloat(self.zMotion),CGFloat(self.xMotion),CGFloat(self.yMotion),0,0,0,0,0,0]
        greenArray  = [CGFloat(self.xMotion),CGFloat(self.yMotion),CGFloat(self.zMotion),0,0,0,0,0,0]
        blueArray = [CGFloat(self.yMotion),CGFloat(self.xMotion),CGFloat(self.zMotion),0,0,0,0,0,0]
        redVector = CIVector(values: redArray, count: Int(redArray.count))
        greenVector = CIVector(values: greenArray, count: Int(greenArray.count))
        blueVector = CIVector(values: blueArray, count: Int(blueArray.count))
        self.filterColorCross = filterCollection.colorCrossPolynomial(self.redVector, greenCoefficients: self.greenVector, blueCoefficients: self.blueVector)
        filterWrapper = [filterPinchDistortion,filterMonochrome,filterColorInvert,filterColorCross,filterBumbDistortion, filterFlipHori]
        loadIntro()
    }
    
    func startMotionDetection(){
        if self.isViewer == true{
            self.motionKit = MotionKit()
            motionKit.getAttitudeFromDeviceMotion(interval: 0.4) {
                (attitude) -> () in
                self.xMotion = self.normalize(attitude.roll)
                self.yMotion = self.normalize(attitude.pitch)
                self.zMotion = self.normalize(attitude.yaw)
            }

        }
    }
    
    
    func loadIntro(){
        let frameCount = 460
        var imageNames:[String] = []
        let fixedName = "animation_"
        var frameNumber:Int
        for frameNumber = 0; frameNumber <= frameCount; ++frameNumber{
            imageNames.append( fixedName +  String(format: "%05d", frameNumber))
            var file :String = NSBundle.mainBundle().pathForResource(imageNames.last!, ofType: "png")!
            self.imagesForAnimation.append(UIImage(contentsOfFile: file)!)
        }
        NSLog("images loaded")
    }
    
    func setupTimer(){
        if self.isViewer == true {
            messageTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("sendStatusMessage"), userInfo: nil, repeats: true)
            GUITimer = NSTimer.scheduledTimerWithTimeInterval(0.035, target: self, selector: Selector("run"), userInfo: nil, repeats: true)
        }
    }
    
    
    func normalize(value :Double)->Double{
        var min :Double = -3
        var max :Double = 3
        return (value-min)/(max-min)
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
    
    func updateVectors(){
        self.redArray = [CGFloat(self.zMotion),CGFloat(self.xMotion),CGFloat(self.yMotion),0,0,0,0,0,0]
        self.greenArray  = [CGFloat(self.xMotion),CGFloat(self.yMotion),CGFloat(self.zMotion),0,0,0,0,0,0]
        self.blueArray  = [CGFloat(self.yMotion),CGFloat(self.xMotion),CGFloat(self.zMotion),0,0,0,0,0,0]
        self.redVector = CIVector(values: redArray, count: Int(redArray.count))
        self.greenVector = CIVector(values: greenArray, count: Int(greenArray.count))
        self.blueVector = CIVector(values: blueArray, count: Int(blueArray.count))
        filterColorCross.setValue(redVector, forKey: "inputRedCoefficients")
        filterColorCross.setValue(greenVector, forKey: "inputGreenCoefficients")
        filterColorCross.setValue(blueVector, forKey: "inputBlueCoefficients")
        //self.filterColorCross = filterCollection.colorCrossPolynomial(self.redVector, greenCoefficients: self.greenVector, blueCoefficients: self.blueVector)
        
    }
    
    func processImage(inputImage :CIImage, value :Double) -> CIImage{
            self.filterToUse.setValue(inputImage, forKey: kCIInputImageKey)
            return self.filterToUse.outputImage
    }
    
    func prepareParameterForMessage() -> NSData{
        var parameters :NSDictionary
        if self.useFilter == true {
            parameters  = ["useBackCamera": self.useBackCamera.description, "useFilter":self.useFilter.description, "filterName": self.filterToUse.name(), "xMotion" :self.xMotion, "yMotion" : self.yMotion, "zMotion" : self.zMotion]
            
        }else{
            parameters  = ["useBackCamera": self.useBackCamera.description, "useFilter":self.useFilter.description, "filterName": "keinFilter", "xMotion" :self.xMotion, "yMotion" : self.yMotion, "zMotion" : self.zMotion]
        }
        var parameterMessage = NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        return parameterMessage!
        
    }
    
    func run(){
            // Wenn Viewer dann lade Bild in den RenderBuffer
            if (isViewer == true){
                if(showIntro == true){
                    if imagesForAnimationBuffer.isEmpty == false{
                        dispatch_barrier_sync(appDelegate.criticQueue, { () -> Void in
                            self.renderImage=self.imagesForAnimationBuffer.first
                            NSLog("loaded frame No.:" + self.counter.description)
                            self.counter = self.counter + 1
                            if (self.imagesForAnimationBuffer.isEmpty == false){
                                self.imagesForAnimationBuffer.removeAtIndex(0)
                            }
                            if (self.backCameraBuffer.isEmpty == false){
                                    self.backCameraBuffer.removeAtIndex(0)
                            }
                        })

                    }else{
                        NSLog("end intro")
                        showIntro = false
                        imagesForAnimationBuffer = imagesForAnimation
                        imagesForAnimation.removeAll(keepCapacity: false)
                    }
                }else{
                
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
            }
            //Wenn Sender dann Sende Bild auf Kamerabuffer an Empfänger
            if (self.isViewer==false) && (self.backCameraBuffer.isEmpty == false){
                
            }
            //UpdateGUI
      
    }
    
}