//
//  GameScene.swift
//  BlueBot
//
//  Created by Nour on 09/05/2018.
//  Copyright © 2018 Nour Saffaf. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    /** The robot power state */
    private var botPower: Bool = false
    /** The robot speed */
    var botSpeed: Int = 1
     /** The robot timer */
    var botTimer: Int = 60
     /** The robot battery */
    var botBattery: Int = 100
     /** The robot distance per second in pixels */
    private var distance: Int = 100
     /** The robot velocity vector */
    private var velocity: CGPoint = CGPoint.zero
     /** The robot movement in X direction */
    private var directionX:CGFloat = 1.0
    /** The robot movement in Y direction */
    private var directionY:CGFloat = 1.0
    
    private var frameTime: TimeInterval = 0
    private var timeOffset: TimeInterval = 0
    private var countDownTimer: Int = 0
    
    /** The bounds where the robot can move */
    private var bounds = CGRect(x: 50.0, y: 300.0, width: 1600, height: 1300)
    
    /** The robot sprite */
    private var botSprite : SKSpriteNode!
     /** The barrier sprite used for stuck simulation */
    private var barrierSprite: SKShapeNode?
    /** The Game Camera */
    private var cameraNode : SKCameraNode!
      /** The Headline label of the simulator */
    private var simulatorLabel: SKLabelNode!
     /** The robot status label  */
    private var statusLabel: SKLabelNode!
    /** The robot time label  */
    private var timeLabel: SKLabelNode!
    /** The robot speed label  */
    private var speedLabel: SKLabelNode!
    /** The robot battery label  */
    private var batteryLabel: SKLabelNode!
    /** The Low Battery Button  */
    private var simBatteryBtn: SKSpriteNode!
    /** The Stuck Button  */
    private var simStuckBtn: SKSpriteNode!
     /** The Error- Reset Button  */
    private var simErrorBtn: SKSpriteNode!
    /** The Rechange Battery Button  */
    private var simChargeBtn: SKSpriteNode!
     /** The Timer count down label */
    private var countDownLabel: SKLabelNode!
    
    private var isLowBatterySimulating = false
    private var isStuckSimulating = false
    private var isErrorSimulating = false
    private var sentNotificationLowBattery = false
    var blueProtocol: BlueProtocol?
    
    /**
        Initial the robot sprite, camera, labels and buttons. Also Draw the bounds. For more information about [didMove](https://developer.apple.com/documentation/spritekit/skscene/1519607-didmove)
 */
    override func didMove(to view: SKView) {
        backgroundColor = .green
        drawBounds()
        
        cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.isUserInteractionEnabled = true
        
       botSprite = SKSpriteNode(imageNamed: "bot")
        botSprite.position = CGPoint(x:500, y: 500)
        print(botSprite)
       addChild(botSprite)
        
        initLabels()
        initSimulatorBtns()
        
        
    }
    
    /**
     Initial the headline and four labels on the upper right corner (status, speed, timer, battery )
     */
    private func initLabels(){
        simulatorLabel = SKLabelNode(text: "BlueBot Simulator")
        simulatorLabel.fontSize = 100.0
        simulatorLabel.fontColor = .black
        simulatorLabel.fontName = "AmericanTypewriter-Bold"
        simulatorLabel.position = CGPoint(x: 0, y: 640)
        cameraNode.addChild(simulatorLabel)
        
        statusLabel = SKLabelNode(text: "Status: Off")
        statusLabel.fontColor = .black
        statusLabel.fontSize = 35.0
        statusLabel.fontName = "AmericanTypewriter-Bold"
        statusLabel.position = CGPoint(x: 700, y: 500)
        statusLabel.horizontalAlignmentMode = .left
        cameraNode.addChild(statusLabel)
        
        speedLabel = SKLabelNode(text: "Speed: 1")
        speedLabel.fontColor = .black
        speedLabel.fontSize = 35.0
        speedLabel.fontName = "AmericanTypewriter-Bold"
        speedLabel.horizontalAlignmentMode = .left
        speedLabel.position = CGPoint(x: statusLabel.position.x, y: statusLabel.position.y - 50)
        cameraNode.addChild(speedLabel)
        
        timeLabel = SKLabelNode(text: "Timer: 60s")
        timeLabel.fontColor = .black
        timeLabel.fontSize = 35.0
        timeLabel.fontName = "AmericanTypewriter-Bold"
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: statusLabel.position.x, y: speedLabel.position.y - 50)
        cameraNode.addChild(timeLabel)
        
        batteryLabel = SKLabelNode(text: "Battery: 100%")
        batteryLabel.fontColor = .black
        batteryLabel.fontSize = 35.0
        batteryLabel.fontName = "AmericanTypewriter-Bold"
        batteryLabel.horizontalAlignmentMode = .left
        batteryLabel.position = CGPoint(x: statusLabel.position.x, y: timeLabel.position.y - 50)
        cameraNode.addChild(batteryLabel)
        
        
        countDownLabel = SKLabelNode(text: "0")
        countDownLabel.fontColor = .black
        countDownLabel.fontSize = 100.0
        countDownLabel.fontName = "AmericanTypewriter-Bold"
        countDownLabel.horizontalAlignmentMode = .center
        countDownLabel.position = CGPoint(x: 800, y: -500)
        cameraNode.addChild(countDownLabel)
        
    }
    
    /**
     Initial the four buttons on the lower right corner (recharge, Low Battery, Stuck, Error )
     */
    private func initSimulatorBtns(){
        
        simBatteryBtn = SKSpriteNode(imageNamed: "btn_battery")
        simBatteryBtn.position = CGPoint(x: self.size.width - 200, y: self.size.height/2)
        simBatteryBtn.setScale(1.7)
        simBatteryBtn.name = "sim_battery"
        addChild(simBatteryBtn)
        
        simStuckBtn = SKSpriteNode(imageNamed: "btn_stuck")
        simStuckBtn.position = CGPoint(x: simBatteryBtn.position.x, y: simBatteryBtn.position.y - 120)
        simStuckBtn.setScale(1.7)
        simStuckBtn.name = "sim_stuck"
        addChild(simStuckBtn)
        
        simErrorBtn = SKSpriteNode(imageNamed: "btn_error")
        simErrorBtn.position = CGPoint(x: simBatteryBtn.position.x, y: simStuckBtn.position.y - 120)
        simErrorBtn.name = "sim_error"
        simErrorBtn.setScale(1.7)
        addChild(simErrorBtn)
        
        simChargeBtn = SKSpriteNode(imageNamed: "btn_charge")
        simChargeBtn.position = CGPoint(x: self.size.width - 200, y: simBatteryBtn.position.y + 120)
        simChargeBtn.setScale(1.7)
        simChargeBtn.name = "sim_charge"
        addChild(simChargeBtn)
        
    }
    
    /** response to buttons clicks*/
    func touchDown(atPoint pos : CGPoint) {
       
        for node in self.nodes(at: pos) {
            if node.name == "sim_battery" {
               simulateLowBattery()
            }
            
            if node.name == "sim_stuck" {
                simulateStuck()
            }
            
            if node.name == "sim_error" {
                simulateError()
                
            }
            
            if node.name == "sim_charge" {
                botBattery = 100
                batteryLabel.text = "Battery: 100%"
                botSprite.removeAction(forKey: "Low_Battery")
                botSprite.color = .white
                
            }
        }
    }
    /** Triggers low battery state.
     */
    private func simulateLowBattery(){
        isLowBatterySimulating = !isLowBatterySimulating

        if isLowBatterySimulating {
            blueProtocol?.simulateLowBattery(state: isLowBatterySimulating)
            batteryLabel.text = "Battery: 15%"
            if botSprite.action(forKey: "Low_Battery")  == nil {
                let colorizeAction = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 1.0)
                let blinkAction =  SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 1.0)
                let actions = [colorizeAction, blinkAction]
                botSprite.run(SKAction.repeatForever(SKAction.sequence(actions)), withKey: "Low_Battery")
            }
             statusLabel.text = "Status: Low Battery"
        } else {
           batteryLabel.text = "Battery: 100%"
            botSprite.removeAction(forKey: "Low_Battery")
            botSprite.color = .white
            statusLabel.text = "Status: On"
            blueProtocol?.simulateOK()
        }
    }
    
    /** Triggers stuck state by inserting barrier sprite.*/
    private func simulateStuck(){
        isStuckSimulating = !isStuckSimulating
        
        if isStuckSimulating {
            barrierSprite = SKShapeNode(rect: CGRect(x: bounds.minX, y: bounds.height/2, width: bounds.width, height: 100))
            barrierSprite?.name = "barrier"
            barrierSprite?.fillColor = .red
            barrierSprite?.strokeColor = .red
            addChild(barrierSprite!)
        } else {
           barrierSprite?.removeFromParent()
           barrierSprite = nil
           botPower = true
           statusLabel.text = "Status: On"
             blueProtocol?.simulateOK()
        }
    }
    
    /** Simulate the error state of the robot */
    private func simulateError(){
        
        if botPower {
        isErrorSimulating = !isErrorSimulating

        if isErrorSimulating {
            botSprite.color = .red
            botSprite.colorBlendFactor = 1.0
            blueProtocol?.simulateError(state: isErrorSimulating)
            botPower = false
            statusLabel.text = "Status: Error"
        } else {
            botSprite.color = .white
            botPower = true
            statusLabel.text = "Status: On"
            blueProtocol?.simulateOK()
        }
        }
    }
  
    /** capture the mouse click on the buttons to fire the response. For move information about [mouseDown](https://developer.apple.com/documentation/appkit/nsresponder/1524634-mousedown/)
     */
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    /**
        Updates the robot settings (Speed and Timer). This function is called from the ViewController didReceiveWrite func
     
        - parameters:
            - settings: Array of UInt8 [Timer, Speed]
     */
    func setBotSettings(settings: Array<UInt8>){
       
        if settings.count == 2 {
            if settings[0] != 0 {
                botTimer = Int(settings[0])
                timeLabel.text = "Timer: \(botTimer)"
            }
            if settings[1] != 0 {
                botSpeed = Int(settings[1])
                speedLabel.text = "Speed: \(botSpeed)"
            }
        }
       
    }
    
    /** Draws black squres that represents the bounds of the room where the robot can move*/
    func drawBounds(){
        let path = CGPath(rect: bounds, transform: nil)
        let shape = SKShapeNode(path: path)
        shape.lineWidth = 10.0
        shape.strokeColor = .black
        addChild(shape)
    }
    
    /** Checks of the robot sprite intersects with the bounds and reverse the velocity directions*/
    func checkBounds(){
        if botSprite.position.x <= bounds.minX {
            botSprite.position.x = bounds.minX
            directionX = -directionX
        }
        
        if botSprite.position.x >= bounds.width {
            botSprite.position.x = bounds.width
            directionX = -directionX
        }
        
        if botSprite.position.y <= bounds.minY {
            botSprite.position.y = bounds.minY
            directionY = -directionY
        }
        
        if botSprite.position.y >= (bounds.height + bounds.minY) {
            botSprite.position.y = (bounds.height + bounds.minY)
            directionY = -directionY
        }
        
    }
    
    /**
     Starts the robot. This function is called from the ViewController togglePower func
     */
    func startBot() {
        statusLabel.text = "Status: On"
        startCountDown()
        botPower = true
    }
    
    /**
     Stops the robot. This function is called from the ViewController togglePower func
     */
    func stopBot() {
        statusLabel.text = "Status: off"
        countDownLabel.text = String(botTimer)
        botPower = false
        removeAction(forKey: "counter")
        blueProtocol?.notifyFinished()
    }
    
    /**
     Starts the Timer countdown
     */
    func startCountDown(){
        countDownTimer = botTimer
        let waitAction = SKAction.wait(forDuration: 1.0)
        let countDownAction = SKAction.run {
            self.countDownTimer = self.countDownTimer - 1
            if self.countDownTimer <= 0 {
                self.botPower = false
                self.statusLabel.text = "Status: Off"
                self.removeAction(forKey: "counter")
                self.countDownLabel.text = "0"
                
            }else {
                if !self.isStuckSimulating && !self.isErrorSimulating {
                    self.botBattery = self.botBattery - self.botSpeed
                    self.countDownLabel.text = String(self.countDownTimer)
                }
            }
        }
        let actions = SKAction.sequence([countDownAction, waitAction])
        run(SKAction.repeatForever(actions), withKey: "counter")
    }
    
    /**
     Move the robot. Called from the Update func
     */
    func moveBot(){
        if botPower {
            let moveToX = directionX * (CGFloat(distance * botSpeed) * CGFloat(timeOffset))
            let moveToY = directionY * (CGFloat(distance * botSpeed) * CGFloat(timeOffset))
            botSprite.position = CGPoint(x: botSprite.position.x + moveToX, y: botSprite.position.y + moveToY)
            checkBounds()
        }
    }
    
    /** Checks of the robot sprite intersects with the barrier sprite, call  BlueProtocol simulateStuck func to notify the central */
    func checkCollision() {
        if botPower {
            if let barrier = barrierSprite {
                if botSprite.frame.intersects(barrier.frame) {
                    botPower = false
                    blueProtocol?.simulateStuck(state: isStuckSimulating)
                    statusLabel.text = "Status: Stuck"
                }
            }
        }
    }

    /** Update the status of the robot battery */
    func updateBattery() {
        
        if botBattery <= 15  {
            if !sentNotificationLowBattery {
                simulateLowBattery()
                sentNotificationLowBattery = true
            }
        }
        
        if botBattery <= 0 {
            botBattery = 0
            simulateError()
        }
        
        batteryLabel.text = "Battery: " + String(botBattery) + "%"
    }
    
    /** Performs any scene-specific updates that need to occur before scene actions are evaluated. For more info check [update](https://developer.apple.com/documentation/spritekit/skscene/1519802-update/)
 */
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if frameTime > 0 {
            timeOffset = currentTime - frameTime
        }
        moveBot()
        updateBattery()
        if isStuckSimulating {
            checkCollision()
        }
        frameTime = currentTime
    }
}
