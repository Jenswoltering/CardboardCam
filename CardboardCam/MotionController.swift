//
//  MotionController.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.05.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import Foundation
import CoreMotion


class MotionController: NSObject{
    let motionKit = MotionKit()
    let updataInterval = 0.001
    let queue = NSOperationQueue.mainQueue()
   
    
    func start(){
        
        motionKit.getGravityAccelerationFromDeviceMotion(interval: 0.2) {
            (x, y, z) -> () in
            // x, y and z values are here
             println("X: \(x) Y: \(y) Z \(z)")
        }
        
        motionKit.getAttitudeFromDeviceMotion(interval: 0.2) {
            (attitude) -> () in
            var roll = attitude.roll
            var pitch = attitude.pitch
            var yaw = attitude.yaw
            var rotationMatrix = attitude.rotationMatrix
            var quaternion = attitude.quaternion
            println("\(quaternion)")
        }
        
        motionKit.getRotationRateFromDeviceMotion(interval: 0.2) {
            (x, y, z) -> () in
            println("RotX: \(x) RotY: \(y) RotZ \(z)")        }
    }
    
    
    

    
    
    func degrees(radians:Double) -> Int {
        return (Int)(180 / M_PI * radians)
    }
    
   
}