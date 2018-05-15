//
//  ViewController.swift
//  BlueBot
//
//  Created by Nour on 09/05/2018.
//  Copyright © 2018 Nour Saffaf. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit
import CoreBluetooth

class ViewController: NSViewController, CBPeripheralManagerDelegate, BlueProtocol {
    
    
    
    /** robot power state 0 = off , 1 = on. This value is updated from the central*/
    private var botState: Array<UInt8> = [0]
    
     /** Service Advertisement Data... not important*/
    private let botAdvertisementData = String("BlueBot")
     /** Service CBUUID*/
    private let BOT_SERVICE_UUID = CBUUID(string: "F48DA104-D6B8-43C4-A719-3A03FEA55088")
    
     /** Alert Characsteric CBUUID*/
    private let BOT_ALERT_INFO_UUID =  CBUUID(string: "7AD4DFE9-E047-45CC-88F9-08AB24264423")
    /** robot alerts values [battery, error, stuck, done]. These values when updated, the peripheral will notify the central.  */
    private var BOT_ALERT_VALUES: Array<UInt8> = [0, 0, 0, 0]
    
    /** Bot Info Characsteric CBUUID, read only [status (on/off/stuck/error), battery]*/
    private let BOT_INFO_UUID =  CBUUID(string: "2EC2C4B8-3199-40BB-88CA-C1CDFA4A897A")
    
    /** Settings Characsteric CBUUID, writable [timer, speed]*/
    private let BOT_SETTINGS_UUID =  CBUUID(string: "441CDBF6-9446-4794-B167-A7C0339CBBFD")
    
     /** Power Characsteric CBUUID, writable [on / off]*/
    private let BOT_POWERS_UUID =  CBUUID(string: "320B4788-BA18-47A7-BEE6-698E9CAF2DB0")
    
    /** CBPeripheralManager instance*/
    private var peripheralManager: CBPeripheralManager!
     /** Alert CBMutableCharacteristic instance, needs ref for alerting central*/
    private var alertCharacteristics: CBMutableCharacteristic!
    
    @IBOutlet var skView: SKView!
     /** GameScene instance*/
    private var gameScene:GameScene!
    
    private let STATUS_OFF: UInt8 = 0
    private let STATUS_ON: UInt8 = 1
    private let STATUS_ERROR: UInt8 = 2
    private let STATUS_STUCK: UInt8 = 3
    
    
    /** Init GameScene, PeripheralManager, alertCharacteristics instaces, for more info about [viewDidLoad](https://developer.apple.com/documentation/appkit/nsviewcontroller/1434476-viewdidload/)
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameScene = GameScene(size: CGSize(width: 2048, height: 2048))
        gameScene.blueProtocol = self
        gameScene.scaleMode = .aspectFill
        skView = self.view as! SKView
        skView.presentScene(gameScene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        
        alertCharacteristics = CBMutableCharacteristic(type: BOT_ALERT_INFO_UUID,
                                                       properties: .notify, value: nil,
                                                       permissions: .readable)
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        
    }
    
    /** Check the status of the bluetooth. If bluetooth is turned on call prepareService func, for more info about [CBPeripheralManager delegate](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/)
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOff:
            print("bluethooth is powered off")
        case .unknown:
            print("bluethooth error")
        case .resetting:
            print("bluethooth resetting.. ")
        case .unsupported:
            print("bluethooth unsupported")
        case .unauthorized:
            print("bluethooth unauthorized")
        case .poweredOn:
            prepareService()
            print("bluethooth powered on")
        }
    }
    
    /** Init the robot service and the characteristics and then start advertising */
    func prepareService() {
    
        let botService = CBMutableService(type: BOT_SERVICE_UUID, primary: true)
        
        let infoCharacteristics = CBMutableCharacteristic(type: BOT_INFO_UUID, properties: .read, value: nil, permissions: .readable)
        
         let botPowerCharacteristics = CBMutableCharacteristic(type: BOT_POWERS_UUID, properties: .write, value: nil, permissions: .writeable)
        
        let settingsCharacteristics = CBMutableCharacteristic(type: BOT_SETTINGS_UUID, properties: .write, value: nil, permissions: .writeable)
        
        botService.characteristics = [alertCharacteristics, settingsCharacteristics, infoCharacteristics, botPowerCharacteristics]
        
        peripheralManager.add(botService)
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[BOT_SERVICE_UUID],
                                            CBAdvertisementDataLocalNameKey: botAdvertisementData])
        
    }
    
    /** Response to read requests by the central, for more info about [CBPeripheralManager delegate](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/)
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        switch request.characteristic.uuid {
        case BOT_INFO_UUID:
            let infoArray: [UInt8] = [botState[0], UInt8(gameScene.botBattery)]
            let infoData = Data.init(bytes: infoArray)
            request.value = infoData
            peripheralManager.respond(to: request, withResult: .success)
        case BOT_SETTINGS_UUID:
            let settingArray: [UInt8] = [UInt8(gameScene.botTimer), UInt8(gameScene.botSpeed)]
            let settingsData = Data.init(bytes: settingArray)
            request.value = settingsData
            peripheralManager.respond(to: request, withResult: .success)
        case BOT_POWERS_UUID:
            let stateData = Data(bytes: botState)
            request.value = stateData
            peripheralManager.respond(to: request, withResult: .success)
        default:
            peripheralManager.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    /** Update settings after receiving write request from the central and notifies the central if settings updated correctly or not , for more info about [CBPeripheralManager delegate](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/)
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        if let request = requests.first {
            switch request.characteristic.uuid {
            case BOT_SETTINGS_UUID:
                updateSettings(data: request.value)
                peripheralManager.respond(to: request, withResult: .success)
            case BOT_POWERS_UUID:
                togglePower(data: request.value)
                peripheralManager.respond(to: request, withResult: .success)
            default:
                peripheralManager.respond(to: request, withResult: .requestNotSupported)
            }
        }
    }
    
    /**
     Handle the update of the power after receiving write request from the central. This func first convert the data from pointer Data to [UInt8] and then calls GameScene startBot or StopBot functions
     
     - parameters:
        - data: The settings data sent from the central
     
     - returns: nothing
     */
    func togglePower(data: Data?){
        if let data = data {
            let powerValue = data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> [UInt8] in
                let buffer = UnsafeBufferPointer.init(start: pointer, count: data.count)
                return Array<UInt8>(buffer)
            }
            
            if let power = powerValue.first {
                botState[0] = power
                if power == STATUS_OFF {
                     botState[0] = STATUS_OFF
                    gameScene.stopBot()
                }else if power == STATUS_ON {
                     botState[0] = STATUS_ON
                     gameScene.startBot()
                }
            }
        }
    }
    
    /**
        Handle the update of the settings after receiving write request from the central. This func first convert the data from pointer Data to [UInt8] and then calls GameScene setBotSettings func
 
        - parameters:
            - data: The settings data sent from the central
 
        - returns: nothing
 */
    func updateSettings(data: Data?) {
        if let data = data {
            let settings = data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> [UInt8] in
                let buffer = UnsafeBufferPointer.init(start: pointer, count: data.count)
                return Array<UInt8>(buffer)
            }
            
            gameScene?.setBotSettings(settings: settings)
            
        }
    }
    
    /**
     The implementation of the BlueProtocol protocol which used alert the central that the robot has low battery by updating the first index of BOT_ALERT_VALUES and then calling [updateValue](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/1393281-updatevalue/)
     
     - parameters:
        - state: Boolean that represents the state of the Low battery [on or off]
     
     - returns: nothing
     */
    func simulateLowBattery(state: Bool) {
        if let alertChar = alertCharacteristics, let central =  alertCharacteristics?.subscribedCentrals {
            BOT_ALERT_VALUES[0] = 1
            let alertData = Data.init(bytes: BOT_ALERT_VALUES)
            peripheralManager.updateValue(alertData, for: alertChar, onSubscribedCentrals: central)
            BOT_ALERT_VALUES[0] = 0
        }
        
    }
    
    /**
     The implementation of the BlueProtocol protocol which used alert the central that the robot is stuck by updating the third index of BOT_ALERT_VALUES and then calling [updateValue](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/1393281-updatevalue/)
     
     - parameters:
        - state: Boolean that represents the state of stuck [on or off]
     
     - returns: nothing
     */
    func simulateStuck(state: Bool) {
        if let alertChar = alertCharacteristics, let central =  alertCharacteristics?.subscribedCentrals {
            BOT_ALERT_VALUES[2] = 1
            let alertData = Data.init(bytes: BOT_ALERT_VALUES)
            peripheralManager.updateValue(alertData, for: alertChar, onSubscribedCentrals: central)
             BOT_ALERT_VALUES[2] = 0
        }
        botState[0] = STATUS_STUCK
    }
    
    /**
     The implementation of the BlueProtocol protocol which used alert the central that the robot has an error and needs restarting by updating the second index of BOT_ALERT_VALUES and then calling [updateValue](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/1393281-updatevalue/)
     
     - parameters:
        - state: Boolean that represents the state of the error [on or off]
     
     - returns: nothing
     */
    func simulateError(state: Bool) {
         print("simulate error")
        if let alertChar = alertCharacteristics, let central =  alertCharacteristics?.subscribedCentrals {
            BOT_ALERT_VALUES[1] = 1
            let alertData = Data.init(bytes: BOT_ALERT_VALUES)
            peripheralManager.updateValue(alertData, for: alertChar, onSubscribedCentrals: central)
            BOT_ALERT_VALUES[1] = 0
        }
         botState[0] = STATUS_ERROR
    }
    
    /**
     The implementation of the BlueProtocol protocol which used alert the central that the robot is restarted and has no errors by setting all values BOT_ALERT_VALUES to zero and then calling [updateValue](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/1393281-updatevalue/)
     
     - returns: nothing
     */
    func simulateOK(){
        if let alertChar = alertCharacteristics, let central =  alertCharacteristics?.subscribedCentrals {
            BOT_ALERT_VALUES = [0,0,0,0]
            let alertData = Data.init(bytes: BOT_ALERT_VALUES)
            peripheralManager.updateValue(alertData, for: alertChar, onSubscribedCentrals: central)
        }
        botState[0] = STATUS_ON
    }
    
    /**
     The implementation of the BlueProtocol protocol which used alert the central that the robot timer has finishedand updating the last index of BOT_ALERT_VALUES and then calling [updateValue](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/1393281-updatevalue/)
     
     - returns: nothing
     */
    func notifyFinished() {
        if let alertChar = alertCharacteristics, let central =  alertCharacteristics?.subscribedCentrals {
            BOT_ALERT_VALUES[3] = 1
            let alertData = Data.init(bytes: BOT_ALERT_VALUES)
            peripheralManager.updateValue(alertData, for: alertChar, onSubscribedCentrals: central)
            BOT_ALERT_VALUES[3] = 0
        }
         botState[0] = STATUS_OFF
    }
    
}

