//
//  GameScene.swift
//  Space
//
//  Created by Mr.Long on 2/10/19.
//  Copyright © 2019 LoNguyen. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var bullet: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var shooterTime = 0.5
    var gameTimer: Timer!
    var shooter_timer: Timer!
    var score: Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
            
        }
    }
    
    
    
    var posibleAlien = ["alien","alien2","alien3"]
    var checkContact = 0
    enum Space:UInt32 {
        case player = 0
        case alien = 1
        case bullet = 4
    }
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        setupBackgroud()
        setupPlayer()
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: (self.frame.width / 2 - scoreLabel.frame.width / 2) * -1, y: (self.frame.height / 2 - scoreLabel.frame.height))
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        shooter_timer = Timer.scheduledTimer(timeInterval: shooterTime, target: self, selector: #selector(createBullet), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let acceleData = data{
                let acceleration =  acceleData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
                
            }
        }
    }
    func setupBackgroud(){
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -10
    }
    func setupPlayer(){
        player = SKSpriteNode(imageNamed: "shuttle")
        player.name = "player"
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = Space.player.rawValue
        player.physicsBody?.contactTestBitMask = Space.alien.rawValue
        player.physicsBody?.collisionBitMask = 0
        
        
        
        player.position = CGPoint(x: 0, y: -1 * (self.frame.size.height / 2 - player.size.height))
        
        self.addChild(player)
    }
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        if player.position.x < -(self.frame.size.width / 2){
            player.position = CGPoint(x: (self.frame.size.width / 2) - 20, y: player.position.y)
        }else if player.position.x > (self.frame.size.width / 2){
            player.position = CGPoint(x: -(self.frame.size.width / 2 - 20), y: player.position.y)
        }
    }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for touch in (touches){
//            let location = touch.location(in: self)
//            player.position = location
//        }
//    }
    
    @objc func createBullet(){
        bullet = SKSpriteNode(imageNamed: "torpedo")
        bullet.size = CGSize(width: player.size.width / 5, height: player.size.width / 5)
        bullet.name = "bullet"
        bullet.physicsBody = SKPhysicsBody(texture: bullet.texture!, size: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = Space.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = Space.alien.rawValue
        bullet.physicsBody?.collisionBitMask = 0
        
        
        
        bullet.position = player.position
        bullet.zPosition = -2
        self.addChild(bullet)
        shootBullet()
    }
    func shootBullet(){
//        let shoot: SKAction = SKAction.moveTo(y: 1000, duration: 3)
        var arrayAction = [SKAction]()
        arrayAction.append(SKAction.moveTo(y: self.frame.height / 2 - 20, duration: 3))
        arrayAction.append(SKAction.removeFromParent())
        
        bullet.run(SKAction.sequence(arrayAction))
    }
    @objc func addAlien(){
        posibleAlien = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: posibleAlien) as! [String]


        let alien = SKSpriteNode(imageNamed: posibleAlien[0])
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: Int(self.frame.size.width / 2 * -1) , highestValue: Int(self.frame.size.width / 2))
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height / 2)
        alien.name = "alien"
        alien.physicsBody = SKPhysicsBody(texture: alien.texture!, size: alien.size)
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.affectedByGravity = true
        alien.physicsBody?.categoryBitMask = Space.alien.rawValue
        alien.physicsBody?.contactTestBitMask = Space.bullet.rawValue
        alien.physicsBody?.contactTestBitMask = Space.player.rawValue
        alien.physicsBody?.collisionBitMask = 0
//        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size) // không cho node nằm chồng lên nhau
        
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -(self.frame.size.height / 2 - 20)), duration: 6))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
        
        
        self.addChild(alien)
    }
    func explosion(location: CGPoint){
        let explosionNode: SKEmitterNode = SKEmitterNode(fileNamed: "Explosion")!
        explosionNode.position = location
        self.addChild(explosionNode)
        self.run(SKAction.wait(forDuration: 10)){
            explosionNode.removeFromParent()
        }
        score += 5
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA.categoryBitMask
        let bodyB = contact.bodyB.categoryBitMask
        if (bodyA == Space.bullet.rawValue && bodyB == Space.alien.rawValue) || (bodyB == Space.bullet.rawValue && bodyA == Space.alien.rawValue){
            contactAlienBullet(bodyA: contact.bodyA.node as! SKSpriteNode, bodyB: contact.bodyB.node as! SKSpriteNode, location: contact.contactPoint)
        }
    }
    func contactAlienBullet(bodyA: SKSpriteNode, bodyB: SKSpriteNode, location: CGPoint){
//        if checkContact == 0{
//            checkContact = 1
//            explosion(location: location)
//        }
//        bodyA.removeFromParent()
//        bodyB.removeFromParent()

        
        
        let explosionNode = SKEmitterNode(fileNamed: "Explosion")!
        explosionNode.position = location
        self.addChild(explosionNode)
        bodyA.removeFromParent()
        bodyB.removeFromParent()
        self.run(SKAction.wait(forDuration: 1)){
            explosionNode.removeFromParent()
        }
        score += 5
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
//        checkContact = 0
    }
}
