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
    
    func flipFilter()->CIFilter{
        var mirror :CGAffineTransform = CGAffineTransformMakeScale(-1, 1)
        let parameters : CIParameters = [
            kCIInputTransformKey: NSValue(CGAffineTransform: mirror)
        ]
        let filter = CIFilter(name: "CIAffineTransform", withInputParameters:parameters)
        return filter
    }
    
}