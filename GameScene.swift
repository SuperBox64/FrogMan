//
//  GameScene.swift
//  FrogMan
//
//  Created by SuperBox64m on 1/2/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Physics categories
    struct PhysicsCategory {
        static let none      : UInt32 = 0
        static let player    : UInt32 = 0b1
        static let obstacle  : UInt32 = 0b10
        static let platform  : UInt32 = 0b100
        static let baseline  : UInt32 = 0b1000
        static let ground    : UInt32 = 0b10000
        static let ringLeft  : UInt32 = 0b100000
        static let ringRight : UInt32 = 0b1000000
    }
    
    // Player dimensions
    private let playerSize = CGSize(width: 25, height: 35)
    
    // Game nodes
    private var player: SKShapeNode!
    private var platforms: [SKShapeNode] = []
    private var triangles: [SKShapeNode] = []
    private var basketballs: [SKShapeNode] = []
    
    // Game state
    private var isJumping = false
    private var canShoot = true
    private var score = 0
    private var scoreLabel: SKLabelNode!
    
    // Platform constants
    private let PLATFORM_SPACING: CGFloat = 0.125
    
    // Jump forces
    struct JumpForce {
        // Standing jump - increase significantly
        static let STANDING_VERTICAL: CGFloat = 600    // Increased from 500
        static let STANDING_HORIZONTAL: CGFloat = 0
        
        // Running jump - adjust proportionally
        static let RUNNING_VERTICAL: CGFloat = 450     // Increased from 350
        static let RUNNING_HORIZONTAL: CGFloat = 100   // Keep horizontal momentum
    }
    
    // Add this property at the top with other properties
    private let MOVE_SPEED: CGFloat = 200.0
    private let MAX_GAPS_PER_PLATFORM = 3 // Maximum number of gaps per platform
    private var isMovingLeft = false
    private var isMovingRight = false
    private let PLATFORM_HEIGHT: CGFloat = 15.0
    private let MIN_PLATFORM_WIDTH: CGFloat = 80.0 // Smaller minimum platform width
    private let PLATFORM_SLOPE: CGFloat = 0.05 // Consistent slope for rolling
    private var lastUpdateTime: TimeInterval = 0
    private var isUpPressed = false
    
    // Add color constants at the top
    private let UNIFORM_BLUE = NSColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1.0) // Dark blue
    private let UNIFORM_GOLD = NSColor(red: 0.8, green: 0.7, blue: 0.0, alpha: 1.0) // Athletic gold
    private let SKIN_COLOR = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Keep skin tone
    
    // At the top of the class with other constants
    private let platformHeights: [CGFloat] = [0.2, 0.35, 0.5, 0.65, 0.8]
    
    // Add to class properties
    private var lives = 5
    private var livesLabel: SKLabelNode!
    private var lastPlatformY: CGFloat = 0  // Track last platform player touched
    private var lastPlatformX: CGFloat = 0  // Track last platform section player touched
    private var scoredBalls: Set<SKShapeNode> = []  // Track balls we've scored points for
    private let BALL_DETECTION_RADIUS: CGFloat = 100
    private var scoredPlatforms: Set<SKNode> = []  // Track platforms we've scored points for
    private var currentLevel = 1
    private var levelLabel: SKLabelNode!
    
    // Add property to track if we're currently spawning
    private var isSpawningBall = false
    
    // Constants for positioning
    private let BASELINE_HEIGHT: CGFloat = 20  // Increased from 5 to 20
    private let PLAYER_START_HEIGHT: CGFloat = 40  // Height above baseline
    
    // Add property to store spawn points
    private var spawnPoints: [(x: CGFloat, y: CGFloat)] = []
    
    // Constants for player movement
    private let JUMP_FORCE: CGFloat = -400  // Increase jump force (negative because y-axis is inverted)
    private let GROUND_HEIGHT: CGFloat = 30  // Increase height above baseline
    
    // Add at top of class
    private var isHandlingCollision = false
    
    // Add property for ground line
    private var canJump = false
    
    // Add property at top of class
    private var baselineScored = false
    
    // Add property to track active spawn points
    private var activeSpawnPoints: Set<CGPoint> = []
    
    // Add these properties at the top of the class
    private var totalPlatforms = 0  // Track total platforms that need to be green
    private var totalIndicators = 0  // Track total indicators that need to be gray
    
    // Add these properties at the top of the class
    private var lastPlayerY: CGFloat = 0  // Track player's last Y position
    private var ballsBeingJumpedOver: Set<SKShapeNode> = []  // Track balls we're currently jumping over
    private var jumpedBalls: Set<SKShapeNode> = []  // Track balls we've already jumped over
    
    // Add property to track which indicators have active balls
    private var indicatorsWithActiveBalls: Set<SKNode> = []
    
    // Add property to track indicator cooldowns
    private var indicatorCooldowns: [SKNode: TimeInterval] = [:]
    private let SPAWN_COOLDOWN: TimeInterval = 4.0  // 4 seconds cooldown
    
    // Add property at top of class
    private var gameStarted = false
    
    // At top of class with other properties
    private let VECTOR_LETTERS: [String: [[CGPoint]]] = [
        "F": [[CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 0, y: 0),
               CGPoint(x: 0, y: 50), CGPoint(x: 30, y: 50)]],
        
        "R": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 30, y: 100),
               CGPoint(x: 30, y: 100), CGPoint(x: 40, y: 80),
               CGPoint(x: 40, y: 80), CGPoint(x: 40, y: 60),
               CGPoint(x: 40, y: 60), CGPoint(x: 30, y: 50),
               CGPoint(x: 30, y: 50), CGPoint(x: 0, y: 50),
               CGPoint(x: 15, y: 50), CGPoint(x: 40, y: 0)]],
        
        "O": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
               CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 0),
               CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0)]],
        
        "G": [[CGPoint(x: 0, y: 0), CGPoint(x: 40, y: 0),
               CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
               CGPoint(x: 40, y: 60), CGPoint(x: 20, y: 60),
               CGPoint(x: 40, y: 60), CGPoint(x: 40, y: 0)]],
        
        "M": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 20, y: 50),
               CGPoint(x: 20, y: 50), CGPoint(x: 40, y: 100),
               CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 0)]],
        
        "A": [[CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 100),
               CGPoint(x: 20, y: 100), CGPoint(x: 40, y: 0),
               CGPoint(x: 10, y: 50), CGPoint(x: 30, y: 50)]],
        
        "N": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 0),
               CGPoint(x: 40, y: 0), CGPoint(x: 40, y: 100)]],
               
        "P": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
               CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 50),
               CGPoint(x: 40, y: 50), CGPoint(x: 0, y: 50)]],
               
        "S": [[CGPoint(x: 40, y: 100), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 0, y: 50),
               CGPoint(x: 0, y: 50), CGPoint(x: 40, y: 50),
               CGPoint(x: 40, y: 50), CGPoint(x: 40, y: 0),
               CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0)]],
               
        "C": [[CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0),
               CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100)]],
               
        "E": [[CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0),
               CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
               CGPoint(x: 0, y: 50), CGPoint(x: 30, y: 50)]],
               
        "T": [[CGPoint(x: 20, y: 0), CGPoint(x: 20, y: 100),
               CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100)]],
               
        "V": [[CGPoint(x: 0, y: 100), CGPoint(x: 20, y: 0),
               CGPoint(x: 20, y: 0), CGPoint(x: 40, y: 100)]],
        
        " ": [[CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)]]  // Empty space with O-width
    ]
    
    // Add these properties at the top of the class
    private let BASELINE_LINE_WIDTH: CGFloat = 2.0
    private let DEATH_ZONE_WIDTH: CGFloat = 50.0
    private let DEATH_ZONE_SPACING: CGFloat = 25.0  // 25 pixels between red zones
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Basic scene setup
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        
        // Debug visualization
        view?.showsPhysics = true
        view?.showsFPS = true
        view?.showsNodeCount = true
        
        // Scene physics
        let edgeLoop = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.physicsBody = edgeLoop
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 0.0
        self.physicsBody?.categoryBitMask = PhysicsCategory.ground
        self.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player
        
        // Show title screen
        showTitleScreen()
    }
    
    private func showTitleScreen() {
        // Create FROGMAN text node first
        let titleNode = createVectorText("FROGMAN", 
                                       position: .zero,  // Temporary position
                                       color: .green,
                                       scale: 1.0)
        
        // Center horizontally using the node's actual width
        let frogmanX = frame.midX - (titleNode.calculateAccumulatedFrame().width / 2)
        titleNode.position = CGPoint(x: frogmanX, y: frame.midY + 50)
        titleNode.name = "titleScreen"
        addChild(titleNode)
        
        // Create SPACE TO START text node
        let startText = createVectorText("SPACE TO START",
                                       position: .zero,  // Temporary position
                                       color: .white,
                                       scale: 0.5)
        
        // Center horizontally using the node's actual width
        let spaceToStartX = frame.midX - (startText.calculateAccumulatedFrame().width / 2)
        startText.position = CGPoint(x: spaceToStartX, y: frame.midY - 50)
        startText.name = "titleScreen"
        addChild(startText)
    }
    
    private func startGame() {
        // Remove title screen
        children.filter { $0.name == "titleScreen" }.forEach { $0.removeFromParent() }
        
        // Create score labels FIRST
        setupScore()
        
        // Create player
        setupPlayer()
        
        // Set initial level
        currentLevel = 1
        
        // Now setup the level (which uses the labels)
        setupLevel()
        
        gameStarted = true
    }
    
    // Add this function to handle common setup
    private func setupLevel() {
        // Get player's current position if they exist
        let safeZone = CGRect(
            x: player?.position.x ?? 0 - playerSize.width,
            y: player?.position.y ?? 0 - playerSize.height,
            width: playerSize.width * 2,
            height: playerSize.height * 2
        )
        
        // Clear any existing platforms/obstacles
        platforms.forEach { $0.removeFromParent() }
        platforms.removeAll()
        
        // Create new platforms, avoiding player's safe zone
        createPlatformsForLevel(avoidingZone: safeZone)
        
        // 1. Remove ALL existing nodes except player and score labels
        children.forEach { node in
            if node != player && 
               node != scoreLabel && 
               node != livesLabel && 
               node != levelLabel {
                node.removeFromParent()
            }
        }
        
        // Clear all arrays and tracking
        platforms.removeAll()
        basketballs.removeAll()
        scoredPlatforms.removeAll()
        
        // Reset counters
        totalPlatforms = 0
        
        // 2. Setup platforms first
        setupPlatforms()
        
        // 3. Reset player position if player exists
        if player == nil {
            setupPlayer()
        } else {
        player.position = CGPoint(x: size.width * 0.05, y: playerSize.height/2)
        player.physicsBody?.velocity = .zero
        }
        
        // 4. Start continuous ball spawning
        isSpawningBall = false  // Reset the flag
        spawnReplacementBall()  // This will start the continuous spawn cycle
        
        // 5. Reset state
        baselineScored = false
        
        // 6. Update level display if label exists
        if levelLabel == nil {
            setupScore() // Create labels if they don't exist
        }
        
        // Add baseline with death zones
        createBaselineWithDeathZones()
    }

    private func createPlatformsForLevel(avoidingZone: CGRect) {
        // Create platforms at different heights
        for height in platformHeights {
            let platformY = size.height * height
            var currentX: CGFloat = 0
            
            while currentX < size.width {
                let sectionWidth = size.width * CGFloat.random(in: 0.1...0.2)
                let platformSection = CGRect(
                    x: currentX,
                    y: platformY,
                    width: sectionWidth,
                    height: PLATFORM_HEIGHT
                )
                
                // Only create platform if it doesn't intersect with safe zone
                if !platformSection.intersects(avoidingZone) {
                    createPlatformSection(from: currentX,
                                       to: currentX + sectionWidth,
                                       at: platformY,
                                       slope: CGFloat.random(in: -PLATFORM_SLOPE...PLATFORM_SLOPE))
                }
                
                currentX += sectionWidth + (size.width * CGFloat.random(in: 0.05...0.1))
            }
        }
    }
    
    // New function to handle ball replacement with delay
    private func spawnReplacementBall() {
        if isSpawningBall { return }  // Only prevent multiple spawn sequences
        
        isSpawningBall = true
        
        // Random delay between 1-3 seconds for next spawn sequence
        let randomDelay = TimeInterval.random(in: 1...3)
        
        // Create and run delayed spawn action
        let waitAction = SKAction.wait(forDuration: randomDelay)
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let randomX = CGFloat.random(in: size.width * 0.1...size.width * 0.9)
            
            // Create spawn indicator line first
            let spawnLine = SKShapeNode(rectOf: CGSize(width: 20, height: 10))
            spawnLine.position = CGPoint(x: randomX, y: self.size.height * 0.9)
            spawnLine.fillColor = .clear
            spawnLine.strokeColor = .red
            spawnLine.lineWidth = 2
            spawnLine.name = "spawnLine"
            self.addChild(spawnLine)
            
            // Wait 3 seconds, then spawn the ball
            let spawnBallAction = SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.run {
                    let newBasketball = self.createNewBasketball(platformHeights: self.platformHeights)
                    newBasketball.position = CGPoint(x: randomX, y: self.size.height * 0.9)
                    self.addChild(newBasketball)
                    self.basketballs.append(newBasketball)
                    spawnLine.removeFromParent()  // Remove the indicator after ball spawns
                }
            ])
            spawnLine.run(spawnBallAction)
            
            isSpawningBall = false  // Reset the spawning flag
            
            // Immediately queue up the next spawn sequence
            self.spawnReplacementBall()
        }
        
        self.run(SKAction.sequence([waitAction, spawnAction]))
    }
    
    // Helper to create pixel-perfect blocks
    private func createPixelBlock(size: CGSize, color: NSColor) -> SKShapeNode {
        let block = SKShapeNode(rectOf: size)
        block.fillColor = .clear
        block.strokeColor = color
        block.lineWidth = 2

        return block
    }
    
    // Helper function to calculate slope
    private func calculateSlope(sectionCenterX: CGFloat, centerX: CGFloat, isMiddleSection: Bool, currentLevel: Int) -> CGFloat {
        if currentLevel == 1 {
            // Level 1: Normal pattern
            if isMiddleSection {
                return (sectionCenterX < centerX) ? 0.05 : -0.05  // ^ shape for middle
            } else {
                return (sectionCenterX < centerX) ? -0.05 : 0.05  // v shape for sides
            }
        } else {
            // Level 2 and up: Opposite pattern
            if isMiddleSection {
                return (sectionCenterX < centerX) ? -0.05 : 0.05  // v shape for middle
            } else {
                return (sectionCenterX < centerX) ? 0.05 : -0.05  // ^ shape for sides
            }
        }
    }
    
    private func setupPlatforms() {
        // Reset counters at start of level
        totalPlatforms = 0
        
        // Create 4 platforms with heights reduced by 5 pixels each (~1% of screen height)
        let platformHeights: [CGFloat] = [
            0.2,  // Bottom platform
            0.4,  // Second platform
            0.6,  // Third platform
            0.8   // Top platform
        ]
        
        // Create array of required hole counts to ensure variety
        var holeCounts = [2, 3, 4]  // Guaranteed numbers
        holeCounts.append(Int.random(in: 2...4))  // Random for the fourth level
        holeCounts.shuffle()  // Randomize which level gets which number
        
        print("Level \(currentLevel) platform heights: \(platformHeights)")
        
        // Create platform sections with random angles
        for (index, height) in platformHeights.enumerated() {
            let platformY = size.height * height
            var holePositions: [(start: CGFloat, width: CGFloat)] = []
            
            // Use the pre-determined number of holes for this level
            let targetHoles = holeCounts[index]
            print("Creating \(targetHoles) holes for platform at height \(height)")
            
            // Divide platform into sections to ensure spread
            let platformWidth = size.width * 0.7  // Use 70% of screen width for holes
            let sectionWidth = platformWidth / CGFloat(targetHoles)
            
            for section in 0..<targetHoles {
                let sectionStart = size.width * 0.15 + sectionWidth * CGFloat(section)
                let holeWidth = size.width * CGFloat.random(in: 0.08...0.1)  // 8-10% of screen width
                
                // Place hole within its section
                let minX = sectionStart + sectionWidth * 0.1  // 10% buffer at start
                let maxX = sectionStart + sectionWidth * 0.9 - holeWidth  // 10% buffer at end
                let holeStart = CGFloat.random(in: minX...maxX)
                
                    holePositions.append((start: holeStart, width: holeWidth))
            }
            
            holePositions.sort { $0.start < $1.start }
            
            // Create platform sections between holes with random slopes
            var currentX: CGFloat = 0
            
            for hole in holePositions {
                if hole.start > currentX {
                    let randomSlope = CGFloat.random(in: -0.1...0.1)
                    createPlatformSection(from: currentX, to: hole.start, at: platformY, slope: randomSlope)
                }
                currentX = hole.start + hole.width
            }
            
            // Final section
            if currentX < size.width {
                let randomSlope = CGFloat.random(in: -0.1...0.1)
                createPlatformSection(from: currentX, to: size.width, at: platformY, slope: randomSlope)
            }
        }
        
        print("Created \(totalPlatforms) platform sections")
    }
    
    private func createPlatformSection(from startX: CGFloat, to endX: CGFloat, at height: CGFloat, slope: CGFloat) -> SKShapeNode {
        let platform = SKShapeNode()
        let path = CGMutablePath()
        
        // Wave parameters adjusted for gentler slopes
        let amplitude: CGFloat = 6.0  // Reduced amplitude for gentler waves
        let frequency: CGFloat = 0.01  // Reduced frequency for longer, more slope-like waves
        let thickness: CGFloat = PLATFORM_HEIGHT
        
        // Create points for the wave
        var points: [CGPoint] = []
        let numPoints = 30  // Fewer points since we're making simpler shapes
        
        // Generate top wave points
        for i in 0...numPoints {
            let x = startX + (endX - startX) * CGFloat(i) / CGFloat(numPoints)
            let progress = CGFloat(i) / CGFloat(numPoints)
            let baseY = height + (endX - startX) * slope * progress
            let waveY = baseY + amplitude * sin(x * frequency * .pi * 2)
            points.append(CGPoint(x: x, y: waveY))
        }
        
        // Start the path at the first point
        path.move(to: CGPoint(x: points[0].x, y: points[0].y - thickness/2))
        
        // Draw bottom wave (offset by thickness)
        for i in 0...numPoints {
            let x = points[i].x
            let y = points[i].y - thickness
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
                    } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Draw up the right side
        path.addLine(to: points[numPoints])
        
        // Draw top wave (reverse direction)
        for i in (0...numPoints).reversed() {
            path.addLine(to: points[i])
        }
        
        // Close the path
        path.closeSubpath()
        
        platform.path = path
        platform.fillColor = .clear
        platform.strokeColor = UNIFORM_GOLD
        platform.lineWidth = 2

        // Create physics body from the path
        platform.physicsBody = SKPhysicsBody(polygonFrom: path)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.friction = 0.2
        platform.physicsBody?.restitution = 0
        platform.physicsBody?.categoryBitMask = PhysicsCategory.platform
        
        addChild(platform)
        platforms.append(platform)
        
        // Count each platform section we create
        if platform.name != "baseline" {
            totalPlatforms += 1
        }
        
        return platform
    }
    
    private func setupScore() {
        // Remove old SKLabelNode setup
    }
    
    private func updateScoreLevelLives() {
        // Remove existing nodes
        children.filter { $0.name == "scoreNode" || $0.name == "levelNode" || $0.name == "livesNode" }.forEach { $0.removeFromParent() }
        
        // Draw score
        let scoreNode = drawVectorNumber(score, at: CGPoint(x: size.width * 0.1, y: size.height * 0.95))
        scoreNode.name = "scoreNode"
        addChild(scoreNode)
        
        // Draw level
        let levelNode = drawVectorNumber(currentLevel, at: CGPoint(x: size.width * 0.5, y: size.height * 0.95))
        levelNode.name = "levelNode"
        addChild(levelNode)
        
        // Draw lives
        let livesNode = drawVectorNumber(lives, at: CGPoint(x: size.width * 0.9, y: size.height * 0.95))
        livesNode.name = "livesNode"
        addChild(livesNode)
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:  // Space
            if !gameStarted {
                startGame()
                return
            }
            if isPaused {
                restartGame()
            } else {
                handleJump()
            }
            
        case 123:  // Left arrow
            isMovingLeft = true
            isMovingRight = false
        case 124:  // Right arrow
            isMovingRight = true
            isMovingLeft = false
            
        default:
            break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let playerBody = player?.physicsBody else { return }
        
        switch event.keyCode {
        case 0x7B:  // Left arrow
            isMovingLeft = false
            if !isMovingRight {
                playerBody.velocity.dx = 0
                playerBody.linearDamping = 1.0  // Restore damping when stopping
            } else {
                // If right is still pressed, immediately switch to right movement
                playerBody.velocity.dx = MOVE_SPEED
            }
            
        case 0x7C:  // Right arrow
            isMovingRight = false
            if !isMovingLeft {
                playerBody.velocity.dx = 0
                playerBody.linearDamping = 1.0  // Restore damping when stopping
            } else {
                // If left is still pressed, immediately switch to left movement
                playerBody.velocity.dx = -MOVE_SPEED
            }
            
        default:
            break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateScoreLevelLives()
        
        // Remove any delay/pause in movement
        if isMovingLeft {
            let newX = player.position.x - MOVE_SPEED * CGFloat(1.0/60.0)
            player.position.x = max(playerSize.width/2, newX)
        }
        
        if isMovingRight {
            let newX = player.position.x + MOVE_SPEED * CGFloat(1.0/60.0)
            player.position.x = min(size.width - playerSize.width/2, newX)
        }
        
        // Add ring rotation update and check ALL balls every frame
        for ball in basketballs {
            if let ringContainer = ball.childNode(withName: "ringContainer") {
                // Counter-rotate the ring container to keep rings upright
                ringContainer.zRotation = -ball.zRotation
                
                // Get ring
                if let ring = ringContainer.childNode(withName: "ring") as? SKShapeNode {
                    // Convert player position to ball's coordinate space
                    let playerPosInBall = ball.convert(player.position, from: self)
                    let distanceToCenter = hypot(playerPosInBall.x, playerPosInBall.y)
                    
                    // Check if player is touching the ring
                    if distanceToCenter < 70 && distanceToCenter > 50 { // Ring collision range
                        // Check metadata instead of color
                        if let isActive = ring.userData?["isActive"] as? Bool, isActive {
                            // Create explosion effect
                            createVectorExplosion(at: ball.position)
                            score += 10
                            showScorePopup(amount: 10, at: player.position, color: .green)
                            ball.removeFromParent()
                            if let index = basketballs.firstIndex(of: ball) {
                                basketballs.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
        
        // Check if player exists and is descending
        if let playerNode = self.player,  // Check if player exists first
           let velocity = playerNode.physicsBody?.velocity.dy {
            if velocity < 0 { // Negative velocity means descending
                // Retract legs if they exist
                if let leftLeg = playerNode.childNode(withName: "leftLeg"),
                   let rightLeg = playerNode.childNode(withName: "rightLeg") {
                    
                    // Only animate if legs aren't already retracting
                    if leftLeg.hasActions() == false {
                        // Retract animation
                        let retractAction = SKAction.group([
                            SKAction.scale(to: 0.5, duration: 0.2),
                            SKAction.rotate(toAngle: 0, duration: 0.2)
                        ])
                        
                        leftLeg.run(retractAction)
                        rightLeg.run(retractAction)
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Get the platform and player from the collision
        let platform = [contact.bodyA.node, contact.bodyB.node].first { node in
            node?.physicsBody?.categoryBitMask == PhysicsCategory.platform
        } as? SKShapeNode
        
        let player = [contact.bodyA.node, contact.bodyB.node].first { node in
            node?.physicsBody?.categoryBitMask == PhysicsCategory.player
        }
        
        // Handle platform color changes
        if let platform = platform, let player = player {
            // Get contact normal
            let normal = contact.contactNormal
            
            // Check if contact is from above (normal.dy is negative when hitting from top)
            if normal.dy < -0.8 {  // Using -0.8 to allow for slight angles
                // Check if platform hasn't been scored yet
                if platform.userData?["scored"] as? Bool != true {
                    // Top collision - turn green
                    platform.strokeColor = .green
                    platform.fillColor = .clear
                    platform.lineWidth = 2
                    
                    // Add score and show popup only if not previously scored
                    score += 10
                    showScorePopup(amount: 10, at: contact.contactPoint, color: .green)
                    
                    // Mark platform as scored
                    platform.userData = NSMutableDictionary()
                    platform.userData?["scored"] = true
                    
                    // Check if level is complete
                    checkLevelCompletion()
                }
            } else if platform.strokeColor == UNIFORM_GOLD {
                // Side collision with gold platform - turn orange first
                platform.strokeColor = .orange
                platform.fillColor = .clear
                platform.lineWidth = 2
                
                // Award 5 points for turning platform orange
                score += 5
                showScorePopup(amount: 5, at: contact.contactPoint, color: .orange)
                
                // Check for balls on this platform
                var ballsToRemove: [SKShapeNode] = []
                for ball in basketballs {
                    if let ballPhysics = ball.physicsBody,
                       let platformPhysics = platform.physicsBody {
                        let contactBodies = ballPhysics.allContactedBodies()
                        if contactBodies.contains(platformPhysics) {
                            // Create implosion effect
                            createVectorImplosion(at: ball.position)
                            
                            // Award 7 points for each ball
                            score += 7
                            showScorePopup(amount: 7, at: ball.position, color: .orange)
                            
                            ballsToRemove.append(ball)
                        }
                    }
                }
                
                // Remove all affected balls
                for ball in ballsToRemove {
                    ball.removeFromParent()
                    if let index = basketballs.firstIndex(of: ball) {
                        basketballs.remove(at: index)
                    }
                }
            }
        }
        
        // Check for player and ball collision
        if collision == (PhysicsCategory.player | PhysicsCategory.obstacle) {
            // Decrease life
            lives -= 1
            
            // Update lives display immediately
            updateScoreLevelLives()
            
            // Create death animation
            createDeathAnimation()
            
            // Wait for death animation to complete before respawning
            let respawnDelay = SKAction.wait(forDuration: 0.7)
            let respawnAction = SKAction.run { [weak self] in
                // Check for game over
                if self?.lives ?? 0 <= 0 {
                    self?.gameOver()
                } else {
                    self?.setupPlayer()  // Only respawn if still have lives
                }
            }
            
            run(SKAction.sequence([respawnDelay, respawnAction]))
        }
        
        // Check for ground contact to enable jumping
        if collision == (PhysicsCategory.player | PhysicsCategory.ground) ||
           collision == (PhysicsCategory.player | PhysicsCategory.platform) ||
           collision == (PhysicsCategory.player | PhysicsCategory.baseline) {
            print("Ground contact detected")
            canJump = true
            
            // Get the player node from collision
            let playerNode = [contact.bodyA.node, contact.bodyB.node].first { node in
                node?.physicsBody?.categoryBitMask == PhysicsCategory.player
            }
            
            // Handle landing animation
            if let player = playerNode,
               let leftLeg = player?.childNode(withName: "leftLeg"),
               let rightLeg = player?.childNode(withName: "rightLeg") {
                
                // Kill any existing animations
                leftLeg.removeAllActions()
                rightLeg.removeAllActions()
                
                // Simple landing sequence with shorter legs (0.5 scale)
                let landSequence = SKAction.sequence([
                    // 1. Quick spread with short legs (0.5 scale)
                    SKAction.run {
                        // Scale to half size for landing
                        leftLeg.run(SKAction.scale(to: 0.5, duration: 0.1))
                        rightLeg.run(SKAction.scale(to: 0.5, duration: 0.1))
                        // Spread legs slightly
                        leftLeg.run(SKAction.rotate(toAngle: -.pi/4, duration: 0.1))
                        rightLeg.run(SKAction.rotate(toAngle: .pi/4, duration: 0.1))
                    },
                    
                    SKAction.wait(forDuration: 0.1),
                    
                    // 2. Remove legs
                    SKAction.run {
                        leftLeg.removeFromParent()
                        rightLeg.removeFromParent()
                    }
                ])
                
                leftLeg.run(landSequence)
                rightLeg.run(landSequence)
            }
        }
    }
    
    private func gameOver() {
        // Clear the scene except for score display
        children.forEach { node in
            if node != scoreLabel && node != livesLabel && node != levelLabel {
                node.removeFromParent()
            }
        }
        
        // Create GAME OVER text
        let gameOverText = createVectorText("GAME OVER", 
                                          position: CGPoint(x: frame.midX, y: frame.midY + 50),
                                          color: .red,
                                          scale: 1.0)
        
        // Calculate actual width and center it
        let gameOverX = frame.midX - (gameOverText.calculateAccumulatedFrame().width / 2)
        gameOverText.position = CGPoint(x: gameOverX, y: frame.midY + 50)
        addChild(gameOverText)
        
        // Create SPACE TO START text
        let startText = createVectorText("SPACE TO START",
                                       position: CGPoint(x: frame.midX, y: frame.midY - 50),
                                       color: .white,
                                       scale: 0.5)
        
        // Calculate actual width and center it
        let startX = frame.midX - (startText.calculateAccumulatedFrame().width / 2)
        startText.position = CGPoint(x: startX, y: frame.midY - 50)
        addChild(startText)
        
        // Reset game state
        gameStarted = false
        lives = 5
        score = 0
        currentLevel = 1
    }
    
    // Add helper function to reset limb positions
    private func resetLimbs() {
        let resetAction = SKAction.rotate(toAngle: 0, duration: 0.1)
        player.childNode(withName: "leftLeg")?.run(resetAction)
        player.childNode(withName: "rightLeg")?.run(resetAction)
        player.childNode(withName: "leftArm")?.run(resetAction)
        player.childNode(withName: "rightArm")?.run(resetAction)
    }
    
    private func setupBasketball() {
        // Always start with 6 basketballs
        let numBasketballs = 6
        
        for _ in 0..<numBasketballs {
            createNewBasketball(platformHeights: platformHeights)
        }
    }
    
    // Add new function to create a single basketball
    private func createNewBasketball(platformHeights: [CGFloat]) -> SKShapeNode {
        // Create the ball first
        let ball = SKShapeNode(circleOfRadius: 12)
        ball.fillColor = .clear  // No fill
        ball.strokeColor = .orange  // Orange outline
        ball.lineWidth = 2  // 1-pixel outline
        ball.name = "ball"
        
        // Physics for ball
        let physicsBody = SKPhysicsBody(circleOfRadius: 12)
        physicsBody.categoryBitMask = PhysicsCategory.obstacle
        physicsBody.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.baseline
        physicsBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.platform
        physicsBody.restitution = 0.5
        physicsBody.friction = 0.2
        physicsBody.allowsRotation = true
        physicsBody.linearDamping = 0.1
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        ball.physicsBody = physicsBody
        
        // Create ring container that won't rotate
        let ringContainer = SKNode()
        ringContainer.name = "ringContainer"
        ball.addChild(ringContainer)
        
        // Create ring and set initial color
        let ring = SKShapeNode(path: {
            let path = CGMutablePath()
            path.addArc(center: CGPoint.zero,
                        radius: 55,
                        startAngle: 0,
                        endAngle: 2 * .pi,
                        clockwise: true)
            return path
        }())
        ring.strokeColor = .white
        ring.lineWidth = 2
        ring.name = "ring"
        ring.userData = NSMutableDictionary()
        ring.userData?["isActive"] = true  // Track if ring can be interacted with
        ringContainer.addChild(ring)
        
        // Create the color alternating sequence with metadata
        let toRed = SKAction.run { 
            ring.strokeColor = .red
            ring.userData?["isActive"] = false
        }
        let toWhite = SKAction.run { 
            ring.strokeColor = .white
            ring.userData?["isActive"] = true
        }
        let waitRed = SKAction.wait(forDuration: 2.0)
        let waitWhite = SKAction.wait(forDuration: 2.0)
        
        let pulseSequence = SKAction.sequence([
            toRed,
            waitRed,
            toWhite,
            waitWhite
        ])
        
        // Run the sequence forever
        ring.run(SKAction.repeatForever(pulseSequence))
        
        // Initialize ring state
        ball.userData = ["ringTouched": false]
        
        return ball
    }
    
    // Add restart function
    private func restartGame() {
        // Remove game over label
        children.filter { $0.name == "gameOverLabel" }.forEach { $0.removeFromParent() }
        
        // Reset score and lives
        score = 0
        lives = 5

        
        // Reset to level 1
        currentLevel = 1
        
        // Use common setup for level
        setupLevel()
        
        // Unpause the game
        isPaused = false
    }
    
    // Add new function for level progression
    private func startNextLevel() {
        
        let levelComplete = SKLabelNode(text: "Level Complete!")
        levelComplete.position = CGPoint(x: size.width/2, y: size.height/2)
        levelComplete.fontName = "Courier"
        levelComplete.fontSize = 36
        levelComplete.fontColor = .green
        addChild(levelComplete)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        levelComplete.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    private func handleLifeLost() {
        // Remove the player completely
        player.removeFromParent()
        
        // Recreate the player from scratch
        setupPlayer()
        
        // Reset jump state
        canJump = true
    }
    
    private func handleJump() {
        if canJump {
            print("Attempting jump")
            player.physicsBody?.velocity.dy = 0
            
            // Create and show legs for jump if they don't exist
            let leftLeg = player.childNode(withName: "leftLeg") ?? createLShapedLeg(pixelSize: 5, isLeft: true)
            let rightLeg = player.childNode(withName: "rightLeg") ?? createLShapedLeg(pixelSize: 5, isLeft: false)
            
            if leftLeg.parent == nil { player.addChild(leftLeg) }
            if rightLeg.parent == nil { player.addChild(rightLeg) }
            
            // Simple vector-style jump animation
            let jumpSequence = SKAction.sequence([
                // 1. Start with short legs
                SKAction.run {
                    // Scale legs to 0.5 their size initially
                    leftLeg.setScale(0.5)
                    rightLeg.setScale(0.5)
                    // Quick crouch with short legs
                    leftLeg.run(SKAction.rotate(toAngle: -.pi/4, duration: 0.1))
                    rightLeg.run(SKAction.rotate(toAngle: .pi/4, duration: 0.1))
                },
                
                SKAction.wait(forDuration: 0.1),
                
                // 2. Explosive extension with full-size legs
                SKAction.run {
                    // Scale to full size during extension
                    leftLeg.run(SKAction.scale(to: 1.0, duration: 0.05))
                    rightLeg.run(SKAction.scale(to: 1.0, duration: 0.05))
                    leftLeg.run(SKAction.rotate(toAngle: .pi/6, duration: 0.05))
                    rightLeg.run(SKAction.rotate(toAngle: -.pi/6, duration: 0.05))
                }
            ])
            
            leftLeg.run(jumpSequence)
            rightLeg.run(jumpSequence)
            
            // Apply jump forces
            if isMovingLeft || isMovingRight {
                // Running jump
                player.physicsBody?.applyImpulse(CGVector(
                    dx: isMovingLeft ? -JumpForce.RUNNING_HORIZONTAL : JumpForce.RUNNING_HORIZONTAL,
                    dy: JumpForce.RUNNING_VERTICAL
                ))
            } else {
                // Standing jump
                player.physicsBody?.applyImpulse(CGVector(
                    dx: JumpForce.STANDING_HORIZONTAL,
                    dy: JumpForce.STANDING_VERTICAL
                ))
            }
            
            // Create and extend legs
            createLShapedLeg(pixelSize: playerSize.width, isLeft: true)
            createLShapedLeg(pixelSize: playerSize.width, isLeft: false)
            
            // Reset leg size and rotation
            if let leftLeg = player.childNode(withName: "leftLeg"),
               let rightLeg = player.childNode(withName: "rightLeg") {
                leftLeg.setScale(1.0)
                rightLeg.setScale(1.0)
                leftLeg.zRotation = 0
                rightLeg.zRotation = 0
            }
            
            canJump = false
        }
    }
    
    private func setupPlayer() {
        // Create main container node
        player = SKShapeNode()
        
        // Vector-style head outline
        let headOutline = SKShapeNode()
        let headPath = CGMutablePath()
        let headWidth: CGFloat = 25
        let headHeight: CGFloat = 35  // Keeping original height
        
        // Create octagonal head shape
        let points: [CGPoint] = [
            CGPoint(x: -headWidth/2, y: -headHeight/4),      // Left middle
            CGPoint(x: -headWidth/2, y: headHeight/4),       // Left upper middle
            CGPoint(x: -headWidth/4, y: headHeight/2),       // Left upper corner
            CGPoint(x: headWidth/4, y: headHeight/2),        // Right upper corner
            CGPoint(x: headWidth/2, y: headHeight/4),        // Right upper middle
            CGPoint(x: headWidth/2, y: -headHeight/4),       // Right middle
            CGPoint(x: headWidth/4, y: -headHeight/2),       // Right lower corner
            CGPoint(x: -headWidth/4, y: -headHeight/2)       // Left lower corner
        ]
        
        // Draw head outline
        headPath.move(to: points[0])
        for point in points[1...] {
            headPath.addLine(to: point)
        }
        headPath.closeSubpath()
        
        headOutline.path = headPath
        headOutline.strokeColor = .green
        headOutline.lineWidth = 2
        headOutline.fillColor = .clear
        player.addChild(headOutline)
        
        // Vector-style eyes (stop sign shaped)
        let eyeSize: CGFloat = 8
        let eyeY = headHeight/6
        
        // Function to create stop sign shaped eye
        func createStopSignEye(isLeft: Bool) -> SKShapeNode {
            let eye = SKShapeNode()
            let eyePath = CGMutablePath()
            let center = CGPoint(x: isLeft ? -headWidth/4 : headWidth/4, y: eyeY)
            let numSides = 8
            
            // Create octagon points
            for i in 0..<numSides {
                let angle = CGFloat(i) * .pi * 2 / CGFloat(numSides) - .pi/8 // Rotate by -22.5 degrees
                let point = CGPoint(
                    x: center.x + cos(angle) * eyeSize/2,
                    y: center.y + sin(angle) * eyeSize/2
                )
                
                if i == 0 {
                    eyePath.move(to: point)
                } else {
                    eyePath.addLine(to: point)
                }
            }
            eyePath.closeSubpath()
            
            eye.path = eyePath
            eye.strokeColor = .white
            eye.lineWidth = 2
            eye.fillColor = .clear
            return eye
        }
        
        // Create and add eyes
        let leftEye = createStopSignEye(isLeft: true)
        let rightEye = createStopSignEye(isLeft: false)
        player.addChild(leftEye)
        player.addChild(rightEye)
        
        // Add vector smile (permanent)
        let expression = SKShapeNode()
        let expressionPath = CGMutablePath()
        let mouthWidth: CGFloat = headWidth/2
        let mouthY = -headHeight/6
        
        // Create smile curve - FIXED to be an actual smile
        expressionPath.move(to: CGPoint(x: -mouthWidth/2, y: mouthY))
        expressionPath.addQuadCurve(
            to: CGPoint(x: mouthWidth/2, y: mouthY),
            control: CGPoint(x: 0, y: mouthY - 5)  // Control point BELOW for smile
        )
        
        expression.path = expressionPath
        expression.strokeColor = .white
        expression.lineWidth = 2
        player.addChild(expression)
        
        // Physics setup
        let physicsSize = CGSize(width: headWidth, height: headHeight)
        player.physicsBody = SKPhysicsBody(rectangleOf: physicsSize, center: CGPoint(x: 0, y: 0))
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0.0
        player.physicsBody?.friction = 0.2
        player.physicsBody?.mass = 1.0
        player.physicsBody?.linearDamping = 1.0
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.baseline | PhysicsCategory.ground
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.ground | 
                                            PhysicsCategory.platform | PhysicsCategory.baseline
        
        // Position player higher above baseline
        player.position = CGPoint(x: size.width * 0.05, 
                                y: BASELINE_HEIGHT + physicsSize.height)  // Added full height instead of half
        addChild(player)
    }
    
    private func createLShapedLeg(pixelSize: CGFloat, isLeft: Bool) -> SKShapeNode {
        let leg = SKShapeNode()
        leg.name = isLeft ? "leftLeg" : "rightLeg"
        
        // Create thigh outline - longer for better frog proportions
        let thigh = SKShapeNode()
        let thighPath = CGMutablePath()
        let thighLength: CGFloat = 20  // Increased length
        
        // Thigh outline points
        thighPath.move(to: CGPoint(x: 0, y: 0))
        thighPath.addLine(to: CGPoint(x: 0, y: -thighLength))
        
        thigh.path = thighPath
        thigh.strokeColor = .green  // Changed to green
        thigh.lineWidth = 2
        thigh.name = "thigh"
        leg.addChild(thigh)
        
        // Create knee joint - slightly larger for better visibility
        let knee = SKShapeNode(circleOfRadius: 4)
        knee.strokeColor = .green  // Changed to green
        knee.lineWidth = 2
        knee.fillColor = .clear
        knee.position = CGPoint(x: 0, y: -thighLength)
        knee.name = "knee"
        leg.addChild(knee)
        
        // Create calf outline - longer and more angled for frog-like appearance
        let calf = SKShapeNode()
        let calfPath = CGMutablePath()
        let calfLength: CGFloat = 25  // Increased length
        let calfOffset: CGFloat = isLeft ? -12 : 12  // Increased angle
        
        // Calf outline points
        calfPath.move(to: CGPoint(x: 0, y: 0))
        calfPath.addLine(to: CGPoint(x: calfOffset, y: -calfLength))
        
        calf.path = calfPath
        calf.strokeColor = .green  // Changed to green
        calf.lineWidth = 2
        calf.position = CGPoint(x: 0, y: -thighLength)
        calf.name = "calf"
        leg.addChild(calf)
        
        // Create foot outline - wider for better traction
        let foot = SKShapeNode()
        let footPath = CGMutablePath()
        let footLength: CGFloat = 15  // Increased length
        
        // Foot outline points with slight curve for better traction
        footPath.move(to: CGPoint(x: 0, y: 0))
        let footCurve = isLeft ? -footLength : footLength
        footPath.addCurve(to: CGPoint(x: footCurve, y: 0),
                         control1: CGPoint(x: footCurve/2, y: -2),
                         control2: CGPoint(x: footCurve/2, y: -2))
        
        foot.path = footPath
        foot.strokeColor = .green  // Changed to green
        foot.lineWidth = 2
        foot.position = CGPoint(x: calfOffset, y: -thighLength - calfLength)
        foot.name = "foot"
        leg.addChild(foot)
        
        // Position the entire leg - adjusted for better placement
        leg.position = CGPoint(x: isLeft ? -pixelSize * 2.5 : pixelSize * 2.5, y: -pixelSize * 2)
        
        return leg
    }
    
    // Helper function to show score popup
    private func showScorePopup(amount: Int, at position: CGPoint, color: NSColor) {
        // Create vector number for the score popup
        let scorePopup = drawVectorNumber(amount, at: position)
        scorePopup.position = CGPoint(x: position.x, y: position.y + 20)
        addChild(scorePopup)
        
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        scorePopup.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
    }
    
    private func drawVectorNumber(_ number: Int, at position: CGPoint) -> SKNode {
        let numberNode = SKNode()
        let digitWidth: CGFloat = 10
        let digitHeight: CGFloat = 20
        
        let digitPoints: [[CGPoint]] = [
            // 0
            [CGPoint(x: 0, y: 0), CGPoint(x: digitWidth, y: 0),
             CGPoint(x: digitWidth, y: 0), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: 0, y: digitHeight),
             CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: 0)],
            // 1
            [CGPoint(x: digitWidth, y: 0), CGPoint(x: digitWidth, y: digitHeight)],
            // 2
            [CGPoint(x: 0, y: digitHeight), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: digitWidth, y: digitHeight/2),
             CGPoint(x: digitWidth, y: digitHeight/2), CGPoint(x: 0, y: digitHeight/2),
             CGPoint(x: 0, y: digitHeight/2), CGPoint(x: 0, y: 0),
             CGPoint(x: 0, y: 0), CGPoint(x: digitWidth, y: 0)],
            // 3 - Fixed pattern
            [CGPoint(x: 0, y: digitHeight), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: digitWidth, y: 0),
             CGPoint(x: digitWidth, y: 0), CGPoint(x: 0, y: 0),
             CGPoint(x: 0, y: digitHeight/2), CGPoint(x: digitWidth, y: digitHeight/2)],
            // 4
            [CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: digitHeight / 2),
             CGPoint(x: 0, y: digitHeight / 2), CGPoint(x: digitWidth, y: digitHeight / 2),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: digitWidth, y: 0)],
            // 5
            [CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: 0, y: digitHeight),
             CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: digitHeight / 2),
             CGPoint(x: 0, y: digitHeight / 2), CGPoint(x: digitWidth, y: digitHeight / 2),
             CGPoint(x: digitWidth, y: digitHeight / 2), CGPoint(x: digitWidth, y: 0),
             CGPoint(x: digitWidth, y: 0), CGPoint(x: 0, y: 0)],
            // 6
            [CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: 0, y: digitHeight),
             CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: 0),
             CGPoint(x: 0, y: 0), CGPoint(x: digitWidth, y: 0),
             CGPoint(x: digitWidth, y: 0), CGPoint(x: digitWidth, y: digitHeight / 2),
             CGPoint(x: digitWidth, y: digitHeight / 2), CGPoint(x: 0, y: digitHeight / 2)],
            // 7
            [CGPoint(x: 0, y: digitHeight), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: digitWidth, y: 0)],
            // 8
            [CGPoint(x: 0, y: 0), CGPoint(x: digitWidth, y: 0),
             CGPoint(x: digitWidth, y: 0), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: 0, y: digitHeight),
             CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: 0),
             CGPoint(x: 0, y: digitHeight / 2), CGPoint(x: digitWidth, y: digitHeight / 2)],
            // 9
            [CGPoint(x: digitWidth, y: 0), CGPoint(x: digitWidth, y: digitHeight),
             CGPoint(x: digitWidth, y: digitHeight), CGPoint(x: 0, y: digitHeight),
             CGPoint(x: 0, y: digitHeight), CGPoint(x: 0, y: digitHeight / 2),
             CGPoint(x: 0, y: digitHeight / 2), CGPoint(x: digitWidth, y: digitHeight / 2)]
        ]
        
        // Convert number to string to process each digit
        let digits = String(number).compactMap { Int(String($0)) }
        
        for (index, digit) in digits.enumerated() {
            let digitNode = SKNode()
            let offsetX = CGFloat(index) * (digitWidth + 5)
            
            for i in stride(from: 0, to: digitPoints[digit].count, by: 2) {
                let line = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: digitPoints[digit][i])
                path.addLine(to: digitPoints[digit][i + 1])
                line.path = path
                line.strokeColor = .green
                line.lineWidth = 2
                digitNode.addChild(line)
            }
            
            numberNode.addChild(digitNode)
        }
        
        numberNode.position = position
        return numberNode
    }
    
    // Add this new function for the vector explosion effect
    private func createVectorExplosion(at position: CGPoint) {
        let numLines = 12
        let explosionRadius: CGFloat = 50
        
        for i in 0..<numLines {
            let angle = (CGFloat(i) / CGFloat(numLines)) * CGFloat.pi * 2
            
            // Create line
            let line = SKShapeNode()
            let path = CGMutablePath()
            
            // Start at explosion center
            path.move(to: .zero)
            
            // End point based on angle
            let endPoint = CGPoint(
                x: cos(angle) * explosionRadius,
                y: sin(angle) * explosionRadius
            )
            path.addLine(to: endPoint)
            
            line.path = path
            line.strokeColor = .white
            line.lineWidth = 2
            line.position = position
            
            // Add to scene
            addChild(line)
            
            // Animate
            let moveAction = SKAction.scale(by: 1.5, duration: 0.3)
            let fadeAction = SKAction.fadeOut(withDuration: 0.3)
            let group = SKAction.group([moveAction, fadeAction])
            let remove = SKAction.removeFromParent()
            
            line.run(SKAction.sequence([group, remove]))
        }
    }
    
    // Add this new function for the implosion effect
    private func createVectorImplosion(at position: CGPoint) {
        let numLines = 12
        let startRadius: CGFloat = 50
        
        for i in 0..<numLines {
            let angle = (CGFloat(i) / CGFloat(numLines)) * CGFloat.pi * 2
            
            // Create line
            let line = SKShapeNode()
            let path = CGMutablePath()
            
            // Start at outer position
            let startPoint = CGPoint(
                x: cos(angle) * startRadius,
                y: sin(angle) * startRadius
            )
            path.move(to: startPoint)
            
            // End at center
            path.addLine(to: .zero)
            
            line.path = path
            line.strokeColor = .orange
            line.lineWidth = 2
            line.position = position
            
            // Add to scene
            addChild(line)
            
            // Animate
            let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
            let fadeAction = SKAction.fadeOut(withDuration: 0.3)
            let group = SKAction.group([scaleAction, fadeAction])
            let remove = SKAction.removeFromParent()
            
            line.run(SKAction.sequence([group, remove]))
        }
    }
    
    // Add this function to check for level completion
    private func checkLevelCompletion() {
        // Get all platforms in the scene
        let platforms = children.filter { node in
            node.physicsBody?.categoryBitMask == PhysicsCategory.platform
        }
        
        // Check if all platforms are green
        let allGreen = platforms.allSatisfy { platform in
            if let platform = platform as? SKShapeNode {
                return platform.strokeColor == .green
            }
            return false
        }
        
        // If all platforms are green, complete the level
        if allGreen {
            currentLevel += 1
            startNextLevel()
            setupLevel()  // Setup next level
        }
    }
    
    private func createDeathAnimation() {
        // Store all the lines that make up the frog's head
        var headLines: [SKShapeNode] = []
        
        // Get head outline points
        let headWidth: CGFloat = 25
        let headHeight: CGFloat = 35
        
        // Create octagonal head points
        let points: [CGPoint] = [
            CGPoint(x: -headWidth/2, y: -headHeight/4),      // Left middle
            CGPoint(x: -headWidth/2, y: headHeight/4),       // Left upper middle
            CGPoint(x: -headWidth/4, y: headHeight/2),       // Left upper corner
            CGPoint(x: headWidth/4, y: headHeight/2),        // Right upper corner
            CGPoint(x: headWidth/2, y: headHeight/4),        // Right upper middle
            CGPoint(x: headWidth/2, y: -headHeight/4),       // Right middle
            CGPoint(x: headWidth/4, y: -headHeight/2),       // Right lower corner
            CGPoint(x: -headWidth/4, y: -headHeight/2)       // Left lower corner
        ]
        
        // Create individual lines for each segment
        for i in 0..<points.count {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: points[i])
            path.addLine(to: points[(i + 1) % points.count])
            line.path = path
            line.strokeColor = .green
            line.lineWidth = 2
            line.position = player.position
            addChild(line)
            headLines.append(line)
        }
        
        // Create lines for eyes and smile
        let eyeSize: CGFloat = 8
        let eyeY = headHeight/6
        
        // Left eye
        let leftEye = SKShapeNode(circleOfRadius: eyeSize/2)
        leftEye.strokeColor = .white
        leftEye.lineWidth = 2
        leftEye.position = CGPoint(x: player.position.x - headWidth/4, y: player.position.y + eyeY)
        addChild(leftEye)
        headLines.append(leftEye)
        
        // Right eye
        let rightEye = SKShapeNode(circleOfRadius: eyeSize/2)
        rightEye.strokeColor = .white
        rightEye.lineWidth = 2
        rightEye.position = CGPoint(x: player.position.x + headWidth/4, y: player.position.y + eyeY)
        addChild(rightEye)
        headLines.append(rightEye)
        
        // Smile
        let smile = SKShapeNode()
        let smilePath = CGMutablePath()
        let mouthWidth: CGFloat = headWidth/2
        let mouthY = -headHeight/6
        smilePath.move(to: CGPoint(x: -mouthWidth/2, y: mouthY))
        smilePath.addQuadCurve(
            to: CGPoint(x: mouthWidth/2, y: mouthY),
            control: CGPoint(x: 0, y: mouthY - 5)
        )
        smile.path = smilePath
        smile.strokeColor = .white
        smile.lineWidth = 2
        smile.position = player.position
        addChild(smile)
        headLines.append(smile)
        
        // Animate each line separately
        for (index, line) in headLines.enumerated() {
            let randomAngle = CGFloat.random(in: -CGFloat.pi...CGFloat.pi)
            let randomDistance = CGFloat.random(in: 20...50)
            let movePoint = CGPoint(
                x: line.position.x + cos(randomAngle) * randomDistance,
                y: line.position.y + sin(randomAngle) * randomDistance
            )
            
            let moveAction = SKAction.move(to: movePoint, duration: 0.5)
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let rotateAction = SKAction.rotate(byAngle: randomAngle, duration: 0.5)
            let group = SKAction.group([moveAction, fadeAction, rotateAction])
            let remove = SKAction.removeFromParent()
            
            // Add slight delay based on index for cascade effect
            let delay = SKAction.wait(forDuration: Double(index) * 0.05)
            line.run(SKAction.sequence([delay, group, remove]))
        }
        
        // Remove the original player node
        player.removeFromParent()
    }
    
    // Add function to create vector text
    private func createVectorText(_ text: String, position: CGPoint, color: NSColor, scale: CGFloat = 1.0) -> SKNode {
        let textNode = SKNode()
        var offsetX: CGFloat = 0
        
        for char in text.uppercased() {
            if let letterPoints = VECTOR_LETTERS[String(char)] {
                let letterNode = SKNode()
                
                for segment in letterPoints {
                    for i in stride(from: 0, to: segment.count, by: 2) {
                        let line = SKShapeNode()
                        let path = CGMutablePath()
                        
                        let startPoint = CGPoint(
                            x: segment[i].x * scale,
                            y: segment[i].y * scale
                        )
                        let endPoint = CGPoint(
                            x: segment[i + 1].x * scale,
                            y: segment[i + 1].y * scale
                        )
                        
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                        
                        line.path = path
                        line.strokeColor = color
                        line.lineWidth = 2
                        letterNode.addChild(line)
                    }
                }
                
                letterNode.position = CGPoint(x: offsetX, y: 0)
                textNode.addChild(letterNode)
                
                offsetX += 50 * scale  // Space between letters (matches original O width)
            }
        }
        
        textNode.position = position
        return textNode
    }
    
    // Add this function to create baseline and death zones
    private func createBaselineWithDeathZones() {
        // Create green baseline 1px up from bottom
        let baseline = SKShapeNode()
        let baselinePath = CGMutablePath()
        baselinePath.move(to: CGPoint(x: 0, y: 1))  // 1px up from bottom
        baselinePath.addLine(to: CGPoint(x: size.width, y: 1))  // 1px up from bottom
        
        baseline.path = baselinePath
        baseline.strokeColor = .green
        baseline.lineWidth = BASELINE_LINE_WIDTH
        addChild(baseline)
        
        // Create 3 evenly spaced red death zones
        let totalWidth = size.width
        let usableWidth = totalWidth - (DEATH_ZONE_WIDTH * 3)
        let spacing = usableWidth / 4
        
        for i in 0..<3 {
            let deathZone = SKShapeNode()
            let deathZonePath = CGMutablePath()
            
            let xPosition = spacing + (CGFloat(i) * (DEATH_ZONE_WIDTH + spacing))
            deathZonePath.move(to: CGPoint(x: xPosition, y: 1))  // 1px up from bottom
            deathZonePath.addLine(to: CGPoint(x: xPosition + DEATH_ZONE_WIDTH, y: 1))  // 1px up from bottom
            
            deathZone.path = deathZonePath
            deathZone.strokeColor = .red
            deathZone.lineWidth = BASELINE_LINE_WIDTH
            
            // Add physics body for death zone
            deathZone.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: xPosition, y: 1),
                                                 to: CGPoint(x: xPosition + DEATH_ZONE_WIDTH, y: 1))
            deathZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            deathZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
            deathZone.physicsBody?.collisionBitMask = 0
            
            addChild(deathZone)
        }
    }
}

