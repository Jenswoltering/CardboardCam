//
//  CBCamController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 25.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import Foundation
import CoreImage

class CBCamController: NSObject {
    var rotaionDegree :Int
    var position :Int
    var processedCameraImage :CIImage
    //var renderGUI :GlassViewController
    //let renderGUI :GlassViewController
    override init() {
        processedCameraImage = CIImage.emptyImage()
        rotaionDegree=0
        position=0
        
    }
    
    func setprocessedCameraImage(image :CIImage){
        self.processedCameraImage = image
    }
    
    func render(){
        
    }
    
}