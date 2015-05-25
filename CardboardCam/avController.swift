//
//  AVController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics

class AVController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,NSObjectProtocol{
    var captureSession = AVCaptureSession()
    var customPreviewLayerLeft = CALayer()
    var customPreviewLayerRight = CALayer()
    var dataOutput = AVCaptureVideoDataOutput()
    var queue:dispatch_queue_t = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
    
    func setupCamera(){
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
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        var imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0)
        var processedImage = processImage(imageBuffer, param1: 1, param2: 1)
           dispatch_sync(dispatch_get_main_queue()){
           NSLog("test")
            // self.customPreviewLayerLeft.contents = dstImage
           // self.customPreviewLayerRight.contents = dstImage
        }
        
        
    }
    func processImage(sampleBuffer: CVPixelBuffer, param1 :Int, param2:Int)->CIImage{
        var unprocessedImage :CIImage
        if param1 == 0 && param2 == 0{
            unprocessedImage = CIImage(CVPixelBuffer: sampleBuffer)
            return unprocessedImage
        }else
        {
            
            var ciimage :CIImage = CIImage(CVPixelBuffer: sampleBuffer)
            var filter : CIFilter = CIFilter(name:"CIGaussianBlur")
            var filterSat : CIFilter = CIFilter(name: "CIColorControls")
            
            filter.setDefaults()
            
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            filter.setValue(30, forKey: kCIInputRadiusKey)
            
            
            
            ciimage  = filter.outputImage
            
            filterSat.setValue(ciimage, forKey: kCIInputImageKey)
            filterSat.setValue(1.0, forKey: kCIInputSaturationKey)
            
            ciimage = filterSat.outputImage
            return ciimage

        }
    }
    func convertImageFromCMSampleBufferRef(sampleBuffer:CMSampleBuffer) -> CIImage{
        let pixelBuffer:CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        var ciImage:CIImage = CIImage(CVPixelBuffer: pixelBuffer)
        return ciImage;
    }

    
}