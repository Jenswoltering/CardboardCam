//
//  avController.swift
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

class avController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,NSObjectProtocol{
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
        
        var width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        var height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        var bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        var grayColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.None.rawValue)
        var context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, bitmapInfo)
        var dstImage = CGBitmapContextCreateImage(context)
        dispatch_sync(dispatch_get_main_queue()){
           // self.customPreviewLayerLeft.contents = dstImage
           // self.customPreviewLayerRight.contents = dstImage
        }
        
        
    }
    
    func convertImageFromCMSampleBufferRef(sampleBuffer:CMSampleBuffer) -> CIImage{
        let pixelBuffer:CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        var ciImage:CIImage = CIImage(CVPixelBuffer: pixelBuffer)
        return ciImage;
    }

    
}