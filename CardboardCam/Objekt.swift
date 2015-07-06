//
//  Objekt.swift
//  CardboardCam
//
//  Created by Jens Woltering on 02.07.15.
//  Copyright (c) 2015 Jens Woltering. All rights reserved.
//

import Foundation
import UIKit

class Objekt {
    var appDelegate:AppDelegate! = UIApplication.sharedApplication().delegate as? AppDelegate
    var farbe :CIColor
    var objektUUID :String
    var objektMinor :String
    var objektMajor :String
    var zielUUID :String = ""
    var zielMinor :String = ""
    var zielMajor :String = ""
    var objektRSSI :Int = 500
    var zielRSSI :Int = 800
    var objektAktiv :Bool = false
    var schwellwert :Int = 5
    var matchCounter :Int = 0
    var inaktivZaehler :Int = 0
    var imZiel :Bool = false
    
    init(pObjektUUID: String, pObjektMinor: String, pObjektMajor: String, pFarbe :CIColor) {
        self.objektUUID=pObjektUUID
        self.objektMinor = pObjektMinor
        self.objektMajor = pObjektMajor
        self.farbe = pFarbe
        
    }
    
    func setZiel(pZielUUID: String, pZielMinor:String, pZielMajor:String){
        self.zielUUID=pZielUUID
        self.zielMinor=pZielMinor
        self.zielMajor=pZielMajor
        
    }
    
    func run(beacon :AnyObject)->Bool{
        var beaconUUID :NSUUID = beacon.proximityUUID
        if beaconUUID.UUIDString == objektUUID{
            if beacon.major.description == objektMajor{
                if beacon.minor.description == objektMinor{
                    self.objektRSSI = beacon.rssi
                    if beacon.rssi >= -75 {
                        self.objektAktiv = true
                        appDelegate.cbCamController.filterColor = self.farbe
                        appDelegate.cbCamController.useFilter1 = true
                        self.inaktivZaehler=0
                         }
                    checkZiel()
                    return true
                }
             }
        }
        if beaconUUID.UUIDString == zielUUID{
            if beacon.major.description == zielMajor{
                if beacon.minor.description == zielMinor{
                    self.zielRSSI = beacon.rssi
                    checkZiel()
                    inaktivZaehler=inaktivZaehler+1
                    if inaktivZaehler>=10{
                        inaktivZaehler=10
                    }
                    return false
                }
            }
        }
        inaktivZaehler=inaktivZaehler+1
        if inaktivZaehler>=10{
            inaktivZaehler=10
        }

        return false
    }
    
    func checkZiel(){
        if (objektRSSI >= zielRSSI - self.schwellwert && objektRSSI <= zielRSSI + self.schwellwert){
            if self.matchCounter >= 2{
                self.imZiel=true
                
            }
            matchCounter = matchCounter+1
        }else{
            matchCounter=0
        }
        
    }
    
    
}