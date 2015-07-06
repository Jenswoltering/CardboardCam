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
    var drehung :Double = 0
    var useFilter1 :Bool!
    var useFilter2 :Bool!
    var useFilter3 :Bool!
    var useFilter4 :Bool!
    var useFilter5 :Bool!
    var isViewer :Bool!
    var isRunning :Bool!
    var useBackCamera :Bool!
    var filterStaerke :Double!
    var filterColor :CIColor!
    var image :CIImage?
    var counter :Int = 0
    var pulsingDirection :Bool = true
    var pulsingValue :Double = 0
    var messageData :NSData!
    let context = CIContext(options:[kCIContextUseSoftwareRenderer : false])
    var filter = CIFilter(name: "CIColorMonochrome")
    
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
        useFilter2 = true
        useFilter3 = false
        useFilter4 = false
        useFilter5 = false
        isRunning = true
        filterColor = CIColor(red: 1.0, green: 1.0, blue: 1.0)
        cameraController = CameraSessionController()
        cameraController.sessionDelegate = self
        motionKit = MotionKit()
        //self.startMotionDetection()
    }
    
    //Kann weg
    func startMotionDetection(){
        motionKit.getAttitudeFromDeviceMotion(interval: 0.2) { (attitude) -> () in
            var yaw = attitude.yaw
            self.drehung = self.normalisiereInput(yaw)
            NSLog(yaw.description)
        }
    }
    
    //Kann weg
    func normalisiereInput(input :Double)->Double{
        var schwellwert :Double = 15
        var maxWert :Double = 360
        var output :Double
        output = input / maxWert
        return output
        
    }
    
    //Kann weg
    func stopMotionDetection(){
        motionKit.stopDeviceMotionUpdates()
        self.drehung=0
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
        if useFilter2 == true {
            outputImage = self.processImage(ciImage, effect: 0, value: 1.0, farbe: self.filterColor)
            
        } else {
            outputImage =  ciImage
        }
        var cgImg = self.context.createCGImage(outputImage, fromRect: outputImage.extent())
        
        
        
        if (isViewer==true){
                self.setFrontCameraImage(UIImage(CGImage: cgImg)!)
        }else{
            var uiImage = UIImage(CGImage: cgImg)
            var compressedImage = UIImageJPEGRepresentation(uiImage, 0.45)
            self.setBackCameraBufferImage(compressedImage!)
        }
        self.run()
    }
    
    
    func processImage(inputImage :CIImage, effect :Int, value :Double, farbe :CIColor) -> CIImage{
        var tempFilter :CIFilter!
        if self.useFilter1 == true {
            self.filter.setValue(inputImage, forKey: kCIInputImageKey)
            self.filter.setValue(farbe, forKey: kCIInputColorKey)
            self.filter.setValue(value, forKey: kCIInputIntensityKey)
            return self.filter.outputImage
        }
        if self.useFilter2 == true {
            tempFilter = CIFilter(name: "CITorusLensDistortion")
            tempFilter.setValue(inputImage, forKey: kCIInputImageKey)
            tempFilter.setValue([320, 240], forKey: kCIAttributeTypePosition)
            //radius
            tempFilter.setValue(160, forKey: kCIAttributeTypeDistance)
            return tempFilter.outputImage
        }
        if self.useFilter3 == true {
            tempFilter = CIFilter(name: "CIColorInvert")
            tempFilter.setValue(inputImage, forKey: kCIInputImageKey)
            return tempFilter.outputImage
            
        }
        if self.useFilter4 == true {
            tempFilter = CIFilter(name: "CIPinchDistortion")
            tempFilter.setValue(inputImage, forKey: kCIInputImageKey)
            tempFilter.setValue([320, 240], forKey: kCIAttributeTypePosition)
            tempFilter.setValue(160, forKey: kCIAttributeTypeDistance)
            tempFilter.setValue(0.5, forKey: kCIAttributeTypeScalar)
            return tempFilter.outputImage
            
        }
        if self.useFilter5 == true {
            tempFilter = CIFilter(name: "CIColorCrossPolynomial")
            tempFilter.setValue(inputImage, forKey: kCIInputImageKey)
            //ToDO Vektoren eintragen
            return tempFilter.outputImage
        }
        else {
            return inputImage
        }
    }
    
    func prepareParameterForMessage() -> NSData{
        var parameters = ["useBackcamera": self.useBackCamera.description, "farbeRot": self.filterColor.red().description, "farbeGruen": self.filterColor.green().description, "farbeBlaue": self.filterColor.blue().description, "useFilter":self.useFilter1.description]
        var parameterMessage = NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        return parameterMessage!
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
//                dispatch_sync(GlobalMainQueue, { () -> Void in
//                    self.appDelegate.mpcHandler.session.sendData(self.prepareParameterForMessage(), toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
//                })

                
            }
            
            //Wenn Sender dann Sende Bild auf Kamerabuffer an Empfänger
            if (self.isViewer==false) && (self.backCameraBuffer.isEmpty == false){
                    dispatch_sync(GlobalMainQueue, { () -> Void in
                    self.appDelegate.mpcHandler.session.sendData(self.backCameraBuffer.first, toPeers: self.appDelegate.mpcHandler.session.connectedPeers!, withMode: self.appDelegate.mpcHandler.mode, error: nil)
                    self.backCameraBuffer.removeAtIndex(0)

                    })
            }
        //UpdateGUI
      
    }
    
}