//
//  BeaconDetector.swift
//  CardboardCam
//
//  Created by Jens Woltering on 22.06.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//
import UIKit
import Foundation
import CoreLocation

class BeaconDetector: NSObject, CLLocationManagerDelegate{

    let locationManager = CLLocationManager()
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var readyToChangeMode = true
    var counterToUnlockMode = 0
    
    override init(){
        super.init()
        
        let uuidString = "EBEFD083-70A2-47C8-9837-E7B5634DF524"
        let beaconIdentifier = "resetBeacon"
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID,
            identifier: beaconIdentifier)
        
        if(locationManager.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startMonitoringForRegion(beaconRegion)
        locationManager.startRangingBeaconsInRegion(beaconRegion)
        locationManager.startUpdatingLocation()
    }
    
//    func locationManager(manager: CLLocationManager!,
//        didUpdateLocations locations: [AnyObject]!){
//            
//    }
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
            NSLog("didRangeBeacons");
            if readyToChangeMode == false{
                counterToUnlockMode=counterToUnlockMode+1
                if counterToUnlockMode==5{
                    readyToChangeMode=true
                }
            }else{
                counterToUnlockMode=0
            }
            var message:String = ""
            if(beacons.count > 0) {
                let nearestBeacon:CLBeacon = beacons[0] as! CLBeacon
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    readyToChangeMode = true
                    message = "You are far away from the beacon"
                case CLProximity.Near:
                    readyToChangeMode = true
                    message = "You are near the beacon"
                case CLProximity.Immediate:
                    NSLog(nearestBeacon.rssi.description)
                    NSLog(nearestBeacon.major.description)
                    NSLog(nearestBeacon.minor.description)
                    if nearestBeacon.rssi >= -50 {
                        if readyToChangeMode == true {
                            appDelegate.cbCamController.useBackCamera = !appDelegate.cbCamController.useBackCamera
                            readyToChangeMode = false
                        }
                    }
                    message = "You are in the immediate proximity of the beacon"
                case CLProximity.Unknown:
                    // readyToChangeMode = true
                    return
                }
            } else {
                readyToChangeMode = true
                message = "No beacons are nearby"
            }
            
            NSLog("%@", message)
    }
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.startUpdatingLocation()
            
            NSLog("You entered the region")
            
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.stopUpdatingLocation()
            
            NSLog("You exited the region")
            
    }

    
}