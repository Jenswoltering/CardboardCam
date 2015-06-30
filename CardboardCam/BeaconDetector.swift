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
     var lastProximity: CLProximity?
    
    override init(){
        super.init()
        
        let uuidString = "EBEFD083-70A2-47C8-9837-E7B5634DF524"
        let beaconIdentifier = "filterBeacons"
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID,
            identifier: beaconIdentifier)
        
        let uuidString2 = "73676723-7400-0000-FFFF-0000FFFF0002"
        let beaconIdentifier2 = "changeCameraBeacon"
        let beaconUUID2:NSUUID = NSUUID(UUIDString: uuidString2)!
        let beaconRegion2:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID2,
            identifier: beaconIdentifier2)
        
        if(locationManager.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startRangingBeaconsInRegion(beaconRegion)
        locationManager.startRangingBeaconsInRegion(beaconRegion2)
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
        NSLog("didRangeBeacons");
        NSLog(readyToChangeMode.description)
            
        //Counter fuer Beacon
        if readyToChangeMode == false{
            
            counterToUnlockMode=counterToUnlockMode+1
            if counterToUnlockMode >= 5{
                readyToChangeMode=true
            }
            }else{
                counterToUnlockMode=0
            }

            var message:String = ""
            if readyToChangeMode == true {
                if(beacons.count > 0) {
                    for beacon in beacons{
                        if beacon.proximity == CLProximity.Immediate {
                            NSLog(beacon.proximityUUID.description)
                            NSLog(beacon.rssi.description)
                            NSLog(beacon.major.description)
                            NSLog(beacon.minor.description)
                            var beaconUUID :NSUUID = beacon.proximityUUID
                            if beaconUUID.UUIDString == "EBEFD083-70A2-47C8-9837-E7B5634DF524"{
                                if beacon.rssi >= -50 {
                                    appDelegate.cbCamController.stopMotionDetection()
                                    appDelegate.cbCamController.startMotionDetection()
                                    appDelegate.cbCamController.useFilter1 = !appDelegate.cbCamController.useFilter1
                                    readyToChangeMode = false
                                }
                            }//ENDIF filterBeacon
                            if beaconUUID.UUIDString == "73676723-7400-0000-FFFF-0000FFFF0002"{
                                if beacon.rssi >= -50 {
                                    appDelegate.cbCamController.useBackCamera = !appDelegate.cbCamController.useBackCamera
                                    readyToChangeMode = false
                                }
                            }//ENDIF changeCamerBeacon
                        }//ENDIF Immediate
                    }//ENDLOOP Alle Beacons
                }//ENDIF Beacons endeckt
            }//ENDIF ReadyToChange
    }
    
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.startUpdatingLocation()

            NSLog("You entered the region")
            
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            
            NSLog("You exited the region")
            
    }

    
}