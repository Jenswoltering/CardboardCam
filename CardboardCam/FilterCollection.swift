//
//  FilterCollection.swift
//  CardboardCam
//
//  Created by Jens Woltering on 09.07.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
typealias CIParameters = Dictionary<String, AnyObject>


class FilterCollection {
    func torusLensDistortion(center: CGPoint, radius: Float, width: Float, refraction: Float) -> CIFilter {
            let parameters : CIParameters = ["":""
//                kCIInputCenterKey:CIVector(CGPoint:center),
//                kCIInputRadiusKey:radius,
//                kCIInputWidthKey:width,
//                "inputRefraction": refraction
        ]
            let filter = CIFilter(name:"CITorusLensDistortion")
            return filter
    }
    
    
    func bumpDistortion(center: CGPoint, radius: Float, scale: Float) -> CIFilter {
            let parameters : CIParameters = [
                kCIInputRadiusKey:radius,
                kCIInputCenterKey:CIVector(CGPoint:center),
                kCIInputScaleKey:scale
            ]
            let filter = CIFilter(name:"CIBumpDistortion", withInputParameters:parameters)
            return filter
        
    }
    
    func pinchDistortion(center: CGPoint, radius: Float, scale:Float) -> CIFilter {
            let parameters : CIParameters = [
                kCIInputRadiusKey:radius,
                kCIInputCenterKey:CIVector(CGPoint:center),
                kCIInputScaleKey:scale]
                let filter = CIFilter(name:"CIPinchDistortion", withInputParameters:parameters)
            return filter
    }
    
    func colorInvent() -> CIFilter{
        let filter = CIFilter(name: "CIColorInvert")
        return filter
    }
    
    func colorCrossPolynomial(redCoefficients: CIVector, greenCoefficients: CIVector, blueCoefficients: CIVector) -> CIFilter {
            let parameters : CIParameters = [
                "inputRedCoefficients": redCoefficients,
                "inputGreenCoefficients": greenCoefficients,
                "inputBlueCoefficients": blueCoefficients]
            let filter = CIFilter(name:"CIColorCrossPolynomial", withInputParameters:parameters)
            return filter
    }
    
    func colorMonochrome(color: UIColor, intensity: Float) -> CIFilter {
            let parameters : CIParameters = [
                kCIInputColorKey:CIColor(CGColor:color.CGColor),
                kCIInputIntensityKey:intensity]
            let filter = CIFilter(name:"CIColorMonochrome", withInputParameters:parameters)
            return filter
    }
    
}