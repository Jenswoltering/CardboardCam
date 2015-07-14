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
    var objektFilter0 :Objekt!
    var objektFilter1 :Objekt!
    var objektFilter2 :Objekt!
    var objektFilter3 :Objekt!
    var objektFilter4 :Objekt!
    var objektFilter5 :Objekt!
    var objektWrapper :[Objekt] = []
    var lastProximity: CLProximity?
    var counterInaktiv = 0
    var aktiverFilter :Objekt!

    
    override init(){
        super.init()
        let uuidString = "73676723-7400-0000-FFFF-0000FFFF0002"
        let beaconIdentifier = "filterBeacons"
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID,
            identifier: beaconIdentifier)
        // Dump Filter als Platzhalter
        objektFilter0 = Objekt(pObjektUUID: "0", pObjektMinor: "0", pObjektMajor: "0", pfilter: appDelegate.cbCamController.filterColorInvert)
        objektFilter1 = Objekt(pObjektUUID: "73676723-7400-0000-FFFF-0000FFFF0002", pObjektMinor: "1", pObjektMajor: "1",  pfilter : appDelegate.cbCamController.filterBumbDistortion)
        objektFilter2 = Objekt(pObjektUUID: "73676723-7400-0000-FFFF-0000FFFF0002", pObjektMinor: "2", pObjektMajor: "1",  pfilter: appDelegate.cbCamController.filterColorCross)
        objektFilter3 = Objekt(pObjektUUID: "73676723-7400-0000-FFFF-0000FFFF0002", pObjektMinor: "1", pObjektMajor: "2",  pfilter: appDelegate.cbCamController.filterFlipHori)
//        objektFilter4 = Objekt(pObjektUUID: "73676723-7400-0000-FFFF-0000FFFF0002", pObjektMinor: "2", pObjektMajor: "2",  pfilter: appDelegate.cbCamController.filterFlipVerti)
        objektFilter4 = Objekt(pObjektUUID: "73676723-7400-0000-FFFF-0000FFFF0002", pObjektMinor: "1", pObjektMajor: "3",  pfilter: appDelegate.cbCamController.filterColorInvert)
        objektWrapper=[objektFilter1, objektFilter2, objektFilter3,objektFilter4]
        aktiverFilter = objektFilter0
        
        if(locationManager.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startMonitoringForRegion(beaconRegion)
        locationManager.startRangingBeaconsInRegion(beaconRegion)
        locationManager.startUpdatingLocation()
    }
    
    func naehsterFilterBeacon(beacons: [AnyObject]) ->AnyObject? {
        var beaconUUID :NSUUID
        var naehsterBeacon :AnyObject = beacons[0]
        var naehsteRSSI :Int = -200
        for beacon in beacons{
            beaconUUID = beacon.proximityUUID
            if beaconUUID.UUIDString == "73676723-7400-0000-FFFF-0000FFFF0002" && beacon.major != 0{
                if beacon.proximity != CLProximity.Unknown{
                    if beacon.rssi >= naehsteRSSI && beacon.rssi != 0 {
                        naehsteRSSI = beacon.rssi
                        naehsterBeacon = beacon
                    }

                }
            }
        }
        //Nicht der Reset und nicht unknown
        if naehsterBeacon.major != 0 && naehsterBeacon.rssi != 0{
            return naehsterBeacon
        }else{
            return nil
        }
    }
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
        if readyToChangeMode == false{
            counterToUnlockMode=counterToUnlockMode+1
            if counterToUnlockMode >= 5{
                readyToChangeMode=true
            }
        }else{
            appDelegate.cbCamController.useBackCamera = true
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
        //Wenn Beacons Vorhanden
        if(beacons.count > 0) {
            //Logging beacons
//            for beacon in beacons{
//                NSLog("Major:" + beacon.major.description + " Minor:" + beacon.minor.description + " RSSI:" + beacon.rssi.description + " Proxmity:" + beacon.proximity.rawValue.description )
//            }
            //Den naehsten Beacon ermitteln
            if naehsterFilterBeacon(beacons) != nil{
                var beacon: AnyObject = naehsterFilterBeacon(beacons)!
                var beaconUUID :NSUUID = beacon.proximityUUID
//                NSLog("Naechster Beacon = Major:" + beacon.major.description + " Minor:" + beacon.minor.description + " RSSI:" + beacon.rssi.description + " Proxmity:" + beacon.proximity.rawValue.description )
                //Wenn Beaconentfernung nicht unknown (doppelte Abfrage da in naehsterBeacon schon vorhanden)
                if beacon.proximity != CLProximity.Unknown {
                    //Bereich eingrenzen auf max NEAR
                    if (beacon.proximity == CLProximity.Near || beacon.proximity == CLProximity.Immediate) {
                        //durch alle erstellten Objekte laufen
                        for einObjekt in objektWrapper{
                            //Wenn sich ein Objekt angesprochen fuehlt
                            if einObjekt.run(beacon)==true{
                                //pruefen ob das Objekt bereits aktiv ist
                                if einObjekt.objektMajor == aktiverFilter.objektMajor && einObjekt.objektMinor == aktiverFilter.objektMinor {
                                        readyToChangeFilter=false
                                        //counter hinabsetzen um es nicht zu deaktivieren
                                        if counterInaktiv >= 1 {
                                            counterInaktiv = counterInaktiv - 1
                                        }
                                    }
                                //Wenn bereit zum Aendern dann filter setzen
                                if readyToChangeFilter{
                                    aktiverFilter = einObjekt
                                    appDelegate.cbCamController.useFilter=true
                                    appDelegate.cbCamController.filterToUse = einObjekt.filter
                                    readyToChangeFilter=false
                                    counterToUnlockFilter = 0
                                }
                            }
                        }
                    }
                }
            }
                    
            //Pruefen ob sich unter den Beacons der Kamerawechsel Beacon befindet
            for beacon in beacons{
                var beaconUUID :NSUUID = beacon.proximityUUID
                if (beaconUUID.UUIDString == "73676723-7400-0000-FFFF-0000FFFF0002" && beacon.major == 0 && beacon.rssi >= -40 && beacon.rssi != 0 ) {
                    appDelegate.cbCamController.useBackCamera = false
                    readyToChangeMode=false
                    
                    if counterToUnlockMode >= 1 {
                        counterToUnlockMode = counterToUnlockMode - 1
                    }
                }
                
                if (beaconUUID.UUIDString == "73676723-7400-0000-FFFF-0000FFFF0002" && beacon.major == 2 && beacon.minor == 2 && beacon.rssi >= -40 && beacon.rssi != 0 ) {
                    if appDelegate.cbCamController.showIntro == false {
                        appDelegate.cbCamController.showIntro=true
                        appDelegate.cbCamController.loadIntro()
                    }
                    
                }

                
            }
        }
        //Filter deaktivieren wenn: readyToChange und Counter > 5
        if readyToChangeFilter{
            if counterInaktiv >= 8{
                appDelegate.cbCamController.useFilter = false
                aktiverFilter = objektFilter0
                counterInaktiv = 0
            }
        }
    }
    
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
//            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
//            manager.startUpdatingLocation()
//            NSLog("You entered the region")
            
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            
            NSLog("You exited the region")
            
    }

    
}