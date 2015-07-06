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
    var objektBlau :Objekt!
    var objektRot :Objekt!
    var objektGruen :Objekt!
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
        objektBlau = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "1", pObjektMajor: "1", pFarbe: CIColor(red: 0.0, green: 0.0, blue: 1.0))
        objektBlau.setZiel("EBEFD083-70A2-47C8-9837-E7B5634DF524",  pZielMinor: "2",  pZielMajor: "1")
        
        
        objektRot = Objekt(pObjektUUID: "EBEFD083-70A2-47C8-9837-E7B5634DF524", pObjektMinor: "1", pObjektMajor: "2", pFarbe: CIColor(red: 1.0, green: 0.0, blue: 0.0))
        objektRot.setZiel("EBEFD083-70A2-47C8-9837-E7B5634DF524", pZielMinor: "2", pZielMajor: "2")

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
        var message:String = ""
                if(beacons.count > 0) {
                    for beacon in beacons{
                        if beacon.proximity == CLProximity.Near {
                            if beacon.major.description == objektBlau.objektMajor{
                                self.objektBlau.run(beacon)
                            }
                            if beacon.major.description == objektRot.objektMajor{
                                self.objektRot.run(beacon)
                            }
                            
                        }//ENDIF near
                        else {
                            if (objektBlau.objektAktiv == true && objektBlau.inaktivZaehler>=4){
                                appDelegate.cbCamController.useFilter1=false
                                objektBlau.objektAktiv=false
                            }
                            if (objektRot.objektAktiv == true && objektRot.inaktivZaehler>=4){
                                appDelegate.cbCamController.useFilter1=false
                                objektRot.objektAktiv=false
                            }

                        }
                    }//ENDLOOP Alle Beacons
                    NSLog("ObjektBlau")
                    NSLog(objektBlau.objektRSSI.description)
                    NSLog(objektBlau.zielRSSI.description)
                    NSLog(objektBlau.imZiel.description)
                    NSLog("ObjektRot")
                    NSLog(objektRot.objektRSSI.description)
                    NSLog(objektRot.zielRSSI.description)
                    NSLog(objektRot.imZiel.description)
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