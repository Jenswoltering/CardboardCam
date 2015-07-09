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
import CoreImage
import CoreGraphics

class BeaconDetector: NSObject, CLLocationManagerDelegate{

    let locationManager = CLLocationManager()
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var readyToChangeMode = true
    var readyToChangeFilter = true
    var counterToUnlockMode = 0
    var counterToUnlockFilter = 0
    var objektFilter1 :Objekt!
    var objektFilter2 :Objekt!
    var objektFilter3 :Objekt!
    var objektFilter4 :Objekt!
    var objektWrapper :[Objekt] = []
    var lastProximity: CLProximity?
    var counterInaktiv = 0

    
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
        objektFilter1 = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "1", pObjektMajor: "1",  pfilter : appDelegate.cbCamController.filterMonochrome)
        //objektFilter2 = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "2", pObjektMajor: "1",  pfilter: appDelegate.cbCamController.filterTorusLensDistortion)
        objektFilter3 = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "1", pObjektMajor: "2",  pfilter: appDelegate.cbCamController.filterPinchDistortion)
        objektFilter4 = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "2", pObjektMajor: "2",  pfilter: appDelegate.cbCamController.filterColroInvert)
        
        objektWrapper=[objektFilter1,objektFilter3,objektFilter4]
        
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
        if readyToChangeMode == false{
                
            counterToUnlockMode=counterToUnlockMode+1
            if counterToUnlockMode >= 5{
                readyToChangeMode=true
            }
        }else{
                counterToUnlockMode=0
        }
        if readyToChangeFilter == false{
                
            counterToUnlockFilter=counterToUnlockFilter+1
        
            if counterToUnlockFilter >= 5{
                readyToChangeFilter=true
            }
        }else{
            counterToUnlockFilter=0
            counterInaktiv = counterInaktiv + 1
        }
    
            
        var message:String = ""
                if(beacons.count > 0) {
                    for beacon in beacons{
                        var beaconUUID :NSUUID = beacon.proximityUUID
                        NSLog(beaconUUID.UUIDString)
                        NSLog(beacon.rssi.description)
                        if (beacon.proximity == CLProximity.Near || beacon.proximity == CLProximity.Immediate) {
                            for einObjekt in objektWrapper{
                                if einObjekt.run(beacon)==true{
                                    if readyToChangeFilter{
                                        appDelegate.cbCamController.useFilter=true
                                        appDelegate.cbCamController.filterToUse = einObjekt.filter
                                        readyToChangeFilter=false
                                    }
                                }
                                if (beaconUUID.UUIDString == "73676723-7400-0000-FFFF-0000FFFF0002" && beacon.rssi >= -60 && beacon.rssi != 0 ) {
                                    if readyToChangeMode{
                                        appDelegate.cbCamController.useBackCamera = !appDelegate.cbCamController.useBackCamera
                                        readyToChangeMode=false
                                    }
                                    
                                }
                            }
                        }//ENDIF near
                        else {
                           
                        }
                    }//ENDLOOP Alle Beacons
                    if readyToChangeFilter{
                        if counterInaktiv >= 5{
                            appDelegate.cbCamController.useFilter = false
                            readyToChangeFilter = false
                            counterToUnlockFilter = 0
                            counterInaktiv = 0
                        }
                    }
                    
            }//ENDIF Beacons endeckt
            
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