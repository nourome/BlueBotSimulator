//
//  BlueDelegate.swift
//  BlueBot
//
//  Created by Nour on 11/05/2018.
//  Copyright © 2018 Nour Saffaf. All rights reserved.
//

import Foundation

/**
 BlueProtocol is used for communication between ViewController and GameScene.
 */
protocol BlueProtocol {
    /**
        This function triggers robot battery status.
     
        - parameters:
            - state: low battery on/off
 */
    func simulateLowBattery(state: Bool)
    /**
     This function triggers robot stuck status.
     
        - parameters:
            - state: low battery on/off
     */
    func simulateStuck(state: Bool)
    
    /**
     This function triggers error robot status.
     
        - parameters:
            - state: low battery on/off
     */
    func simulateError(state: Bool)
    
    /**
     This function notifies that timer ended.
     */
    func notifyFinished()
    
    /**
     This function reset the robot.
     */
    func simulateOK()
    
}
