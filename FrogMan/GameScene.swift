//
//  GameScene.swift
//  FrogMan
//
//  Created by SuperBox64m on 1/2/25.
//

import SpriteKit
import GameplayKit
import AVFoundation

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
    private let platformSpacing: CGFloat = 0.125
    
    // Jump forces
    struct JumpForce {
        // Standing jump - increase significantly
        static let standingVertical: CGFloat = 600    // Increased from 500
        static let standingHorizontal: CGFloat = 0
        
        // Running jump - adjust proportionally
        static let runningVertical: CGFloat = 450     // Increased from 350
        static let runningHorizontal: CGFloat = 100   // Keep horizontal momentum
    }
    
    // Add this property at the top with other properties
    private let moveSpeed: CGFloat = 200.0
    private let maxGapsPerPlatform = 3 // Maximum number of gaps per platform
    private var isMovingLeft = false
    private var isMovingRight = false
    private let platformHeight: CGFloat = 15.0
    private let minPlatformWidth: CGFloat = 80.0 // Smaller minimum platform width
    private let platformSlope: CGFloat = 0.05 // Consistent slope for rolling
    private var lastUpdateTime: TimeInterval = 0
    private var isUpPressed = false
    
    // Add color constants at the top
    private let uniformBrown = NSColor.brown
    
    // At the top of the class with other constants
    private let platformHeights: [CGFloat] = [0.2, 0.35, 0.5, 0.65, 0.8]
    
    // Add to class properties
    private var lives = 5
    private var livesLabel: SKLabelNode!
    private var lastPlatformY: CGFloat = 0  // Track last platform player touched
    private var lastPlatformX: CGFloat = 0  // Track last platform section player touched
    private var scoredBalls: Set<SKShapeNode> = []  // Track balls we've scored points for
    private let ballDetectionRadius: CGFloat = 100
    private var scoredPlatforms: Set<SKNode> = []  // Track platforms we've scored points for
    private var currentLevel = 1
    private var levelLabel: SKLabelNode!
    
    // Add property to track if we're currently spawning
    private var isSpawningBall = false
    
    // Constants for positioning
    private let baselineHeight: CGFloat = 20  // Increased from 5 to 20
    private let playerStartHeight: CGFloat = 40  // Height above baseline
    
    // Add property to store spawn points
    private var spawnPoints: [(x: CGFloat, y: CGFloat)] = []
    
    // Constants for player movement
    private let jumpForce: CGFloat = -400  // Increase jump force (negative because y-axis is inverted)
    private let groundHeight: CGFloat = 30  // Increase height above baseline
    
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
    private let spawnCooldown: TimeInterval = 4.0  // 4 seconds cooldown
    
    // Add property at top of class
    private var gameStarted = false
    
    // At top of class with other properties
    private let vectorLetters: [String: [CGPoint]] = [
        "F": [CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 0, y: 0),
              CGPoint(x: 0, y: 50), CGPoint(x: 30, y: 50)],
        
        "R": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 30, y: 100),
              CGPoint(x: 30, y: 100), CGPoint(x: 40, y: 80),
              CGPoint(x: 40, y: 80), CGPoint(x: 40, y: 60),
              CGPoint(x: 40, y: 60), CGPoint(x: 30, y: 50),
              CGPoint(x: 30, y: 50), CGPoint(x: 0, y: 50),
              CGPoint(x: 15, y: 50), CGPoint(x: 40, y: 0)],
        
        "O": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
              CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 0),
              CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0)],
        
        "G": [CGPoint(x: 0, y: 0), CGPoint(x: 40, y: 0),
              CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
              CGPoint(x: 40, y: 60), CGPoint(x: 20, y: 60),
              CGPoint(x: 40, y: 60), CGPoint(x: 40, y: 0)],
        
        "M": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 20, y: 50),
              CGPoint(x: 20, y: 50), CGPoint(x: 40, y: 100),
              CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 0)],
        
        "A": [CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 100),
              CGPoint(x: 20, y: 100), CGPoint(x: 40, y: 0),
              CGPoint(x: 10, y: 50), CGPoint(x: 30, y: 50)],
        
        "N": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 0),
              CGPoint(x: 40, y: 0), CGPoint(x: 40, y: 100)],
        
        "P": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
              CGPoint(x: 40, y: 100), CGPoint(x: 40, y: 50),
              CGPoint(x: 40, y: 50), CGPoint(x: 0, y: 50)],
        
        "S": [CGPoint(x: 40, y: 100), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 0, y: 50),
              CGPoint(x: 0, y: 50), CGPoint(x: 40, y: 50),
              CGPoint(x: 40, y: 50), CGPoint(x: 40, y: 0),
              CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0)],
        
        "C": [CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0),
              CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100)],
        
        "E": [CGPoint(x: 40, y: 0), CGPoint(x: 0, y: 0),
              CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100),
              CGPoint(x: 0, y: 50), CGPoint(x: 30, y: 50)],
        
        "T": [CGPoint(x: 20, y: 0), CGPoint(x: 20, y: 100),
              CGPoint(x: 0, y: 100), CGPoint(x: 40, y: 100)],
        
        "V": [CGPoint(x: 0, y: 100), CGPoint(x: 20, y: 0),
              CGPoint(x: 20, y: 0), CGPoint(x: 40, y: 100)],
        
        " ": [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)]  // Empty space
    ]
    
    // Add these properties at the top of the class
    private let baselineLineWidth: CGFloat = 2.0
    private let deathZoneWidth: CGFloat = 50.0
    private let deathZoneSpacing: CGFloat = 25.0  // 25 pixels between red zones
    
    // Add at top of class
    private let spawnCooldownTime: TimeInterval = 2.0  // Time before location can be reused
    private var recentSpawnLocations: [(point: CGPoint, timestamp: TimeInterval)] = []
    
    // Add at top of class with other properties
    private let maxBalls = 6
    private var currentBallCount = 0
    
    // Add at top of file
    private let soundFiles: [String: String] = [
        "jump": "jump_07.wav",
        "land":
            "sfx_movement_jump16_landing.wav",
        "platformGreen": "platform_green.mp3",
        "platformYellow": "platform_yellow.mp3",
        "ballSpawn": "ball_spawn.mp3",
        "ballCollect": "ball_collect.mp3",
        "ballImplosion": "ball_implosion.mp3",
        "death": "death.wav",
        "levelComplete": "level_complete.mp3",
        "gameOver": "game_over.wav",
        "score": "score.mp3",
        "bgMusic": "bgMusic.wav"
    ]
    
    // Audio properties
    private lazy var gameAudioEngine: AVAudioEngine = {
        let engine = AVAudioEngine()
        return engine
    }()
    private var audioPlayers: [String: AVAudioPlayerNode] = [:]
    private var audioFiles: [String: AVAudioFile] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    private var mainMixer: AVAudioMixerNode!
    
    // Replace setupSounds with new implementation
    private func setupSounds() {
        // Initialize audio engine
        mainMixer = gameAudioEngine.mainMixerNode
        
        // Load all sounds
        for (key, filename) in soundFiles {
            if let url = Bundle.main.url(forResource: filename.components(separatedBy: ".")[0],
                                       withExtension: filename.components(separatedBy: ".")[1]) {
                do {
                    // Create audio file
                    let audioFile = try AVAudioFile(forReading: url)
                    audioFiles[key] = audioFile
                    
                    // Create buffer
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                      frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                        continue
                    }
                    try audioFile.read(into: buffer)
                    audioBuffers[key] = buffer
                    
                    // Create player node
                    let player = AVAudioPlayerNode()
                    gameAudioEngine.attach(player)
                    
                    // Connect player to main mixer
                    gameAudioEngine.connect(player, to: mainMixer, format: buffer.format)
                    
                    audioPlayers[key] = player
                } catch {
                    print("Error loading sound \(key): \(error)")
                }
            }
        }
        
        // Start audio engine
        do {
            try gameAudioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    // Replace playSound with new implementation
    private func playSound(_ key: String) {
        guard let player = audioPlayers[key],
              let buffer = audioBuffers[key] else {
            return
        }
        
        // Special handling for background music and game over
        if key == "bgMusic" {
            player.pan = 0  // Center the background music
            player.volume = 0.3  // 30% volume
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
            return
        }
        
        if key == "gameOver" {
            player.pan = 0  // Center the game over sound
            player.volume = 0.5  // 50% volume
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
            return
        }
        
        // Calculate pan based on player position for other sounds
        if let playerNode = self.player {
            let screenWidth = size.width
            let playerX = playerNode.position.x
            
            // Calculate pan value between -1 (left) and 1 (right)
            let pan = (2 * playerX / screenWidth) - 1
            
            // Set pan value
            player.pan = Float(pan)
            player.volume = 1.0  // Full volume for gameplay sounds
        }
        
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
    
    // Replace stopSound with new implementation
    private func stopSound(_ key: String) {
        audioPlayers[key]?.stop()
    }
    
    // Add cleanup method
    deinit {
        gameAudioEngine.stop()
    }
    
    private func startBackgroundMusic() {
        playSound("bgMusic")
    }
    
    private func stopBackgroundMusic() {
        stopSound("bgMusic")
    }
    
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
        setupSounds()
        startBackgroundMusic()
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
                    height: platformHeight
                )
                
                // Only create platform if it doesn't intersect with safe zone
                if !platformSection.intersects(avoidingZone) {
                    createPlatformSection(from: currentX,
                                       to: currentX + sectionWidth,
                                       at: platformY,
                                       slope: CGFloat.random(in: -platformSlope...platformSlope))
                }
                
                currentX += sectionWidth + (size.width * CGFloat.random(in: 0.05...0.1))
            }
        }
    }

    // New function to handle ball replacement with delay
    private func spawnReplacementBall() {
        // When red indicator appears
        playSound("ballSpawn")
        if isSpawningBall { return }  // Only prevent multiple spawn sequences
        if currentBallCount >= maxBalls { return }  // Don't spawn if at max
        
        isSpawningBall = true
        
        // Random delay between 1-3 seconds for next spawn sequence
        let randomDelay = TimeInterval.random(in: 1...3)
        
        // Create and run delayed spawn action
        let waitAction = SKAction.wait(forDuration: randomDelay)
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // Double check we still need a ball
            if self.currentBallCount >= self.maxBalls {
                self.isSpawningBall = false
                return
            }
            
            let randomX = CGFloat.random(in: size.width * 0.1...size.width * 0.9)
            
            // Create spawn indicator line first
            let spawnLine = SKShapeNode(rectOf: CGSize(width: 20, height: 10))
            spawnLine.position = CGPoint(x: randomX, y: self.size.height * 0.9)
            spawnLine.fillColor = .clear
            spawnLine.strokeColor = .red
            spawnLine.lineWidth = 2
            spawnLine.name = "spawnLine"
            self.addChild(spawnLine)
            
            // Changed from 3 seconds to 1 second wait time
            let spawnBallAction = SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run {
                    // Final check before spawning
                    if self.currentBallCount < self.maxBalls {
                        // Create new ball at the EXACT indicator position
                        let newBasketball = self.createBasketball()
                        newBasketball.position = spawnLine.position
                        self.addChild(newBasketball)
                        self.basketballs.append(newBasketball)
                        self.currentBallCount += 1
                        
                        // Record spawn location
                        self.recentSpawnLocations.append((
                            point: spawnLine.position,
                            timestamp: Date().timeIntervalSince1970
                        ))
                    }
                    spawnLine.removeFromParent()
                }
            ])
            spawnLine.run(spawnBallAction)
            
            isSpawningBall = false
        }
        
        self.run(SKAction.sequence([waitAction, spawnAction]))
    }
    
    // Helper function to get spawn point
    private func getAvailableSpawnPoint() -> CGPoint? {
        // Clean up old spawn locations
        let currentTime = Date().timeIntervalSince1970
        recentSpawnLocations = recentSpawnLocations.filter { 
            currentTime - $0.timestamp < spawnCooldownTime 
        }
        
        // Try to find an available spawn point
        let randomX = CGFloat.random(in: size.width * 0.2...size.width * 0.8)
        let spawnY = size.height * 0.9
        let potentialPoint = CGPoint(x: randomX, y: spawnY)
        
        // Check if this location was recently used
        let isRecentlyUsed = recentSpawnLocations.contains { 
            let distance = hypot($0.point.x - potentialPoint.x, 
                               $0.point.y - potentialPoint.y)
            return distance < 100  // Increased to 100 pixels minimum distance
        }
        
        // Also check for existing spawn indicators
        let hasNearbyIndicator = children.contains { node in
            guard node.name == "spawnLine" else { return false }
            let distance = hypot(node.position.x - potentialPoint.x,
                               node.position.y - potentialPoint.y)
            return distance < 100  // 100 pixels from other indicators
        }
        
        return (isRecentlyUsed || hasNearbyIndicator) ? nil : potentialPoint
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
        
        // Create array of required hole counts for each level
        var holeCounts = [2, 2, 3]  // First three levels
        // Top level (index 3) always has 3-4 holes
        let topLevelHoles = Int.random(in: 3...4)
        holeCounts.append(topLevelHoles)
        
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
        let thickness: CGFloat = platformHeight
        
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
        platform.strokeColor = uniformBrown
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
                playerBody.velocity.dx = moveSpeed
            }
            
        case 0x7C:  // Right arrow
            isMovingRight = false
            if !isMovingLeft {
                playerBody.velocity.dx = 0
                playerBody.linearDamping = 1.0  // Restore damping when stopping
            } else {
                // If left is still pressed, immediately switch to left movement
                playerBody.velocity.dx = -moveSpeed
            }
            
        default:
            break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateScoreLevelLives()
        
        // Count current balls and check for off-screen balls
        currentBallCount = basketballs.count
        
        // Create array to store balls that need to be removed
        var ballsToRemove: [SKShapeNode] = []
        
        // Check each ball's position
        for ball in basketballs {
            // Add some buffer to the screen bounds
            let buffer: CGFloat = 100  // Allow balls to go slightly off screen before removing
            
            // Check if ball is out of bounds
            if ball.position.y < -buffer ||  // Below screen
               ball.position.y > size.height + buffer ||  // Above screen
               ball.position.x < -buffer ||  // Left of screen
               ball.position.x > size.width + buffer {  // Right of screen
                ballsToRemove.append(ball)
            }
        }
        
        // Remove any off-screen balls
        for ball in ballsToRemove {
            removeBall(ball)
        }
        
        // If we have less than max balls, try to spawn a new one
        if currentBallCount < maxBalls {
            spawnReplacementBall()
        }
        
        // Remove any delay/pause in movement
        if isMovingLeft {
            let newX = player.position.x - moveSpeed * CGFloat(1.0/60.0)
            player.position.x = max(playerSize.width/2, newX)
        }
        
        if isMovingRight {
            let newX = player.position.x + moveSpeed * CGFloat(1.0/60.0)
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
                            removeBall(ball)
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
        
        let playerNode = [contact.bodyA.node, contact.bodyB.node].first { node in
            node?.physicsBody?.categoryBitMask == PhysicsCategory.player
        }
        
        // Handle platform color changes
        if let platform = platform, let player = playerNode as? SKNode {
            // Get contact normal and positions
            let normal = contact.contactNormal
            let playerPos = player.position
            let platformPos = platform.position
            
            // Calculate if player is above the platform - use a more generous threshold
            let isAbovePlatform = playerPos.y > platformPos.y + platformHeight/2
            
            // Initialize platform metadata if it doesn't exist
            if platform.userData == nil {
                platform.userData = NSMutableDictionary()
                platform.userData?["state"] = "brown"  // Initial state
                platform.userData?["scored"] = false
            }
            
            // Check if contact is from above - ALWAYS turn green if from above
            if isAbovePlatform {  // Simplified check, removed normal.dy threshold
                // Top collision - always turn green regardless of current state
                platform.strokeColor = .green
                platform.fillColor = .clear
                platform.lineWidth = 2
                platform.userData?["state"] = "green"
                
                // Only award points if not previously scored
                if platform.userData?["scored"] as? Bool != true {
                    platform.userData?["scored"] = true
                    score += 10
                    showScorePopup(amount: 10, at: contact.contactPoint, color: .green)
                    
                    // Check if level is complete
                    checkLevelCompletion()
                }
                playSound("platformGreen")
            } else if platform.userData?["state"] as? String == "brown" {
                // Side collision with brown platform - turn yellow
                platform.strokeColor = .yellow
                platform.fillColor = .clear
                platform.lineWidth = 2
                platform.userData?["state"] = "yellow"
                
                // Award 5 points for turning platform yellow
                score += 5
                showScorePopup(amount: 5, at: contact.contactPoint, color: .yellow)
                playSound("platformYellow")
                
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
                    removeBall(ball)
                }
            }
        }
        
        // Check for player and ball collision
        if collision == (PhysicsCategory.player | PhysicsCategory.obstacle) {
            // Play death sound immediately
            playSound("death")
            
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
        stopBackgroundMusic()
        playSound("gameOver")
        // Remove all existing balls and their spawn indicators
        children.forEach { node in
            if node.name == "ball" || node.name == "spawnLine" {
                node.removeFromParent()
            }
        }
        basketballs.removeAll()
        
        // Create GAME OVER text
        let gameOverText = createVectorText("GAME OVER", 
                                          position: CGPoint(x: frame.midX, y: frame.midY + 50),
                                          color: .red,
                                          scale: 1.0)
        
        // Calculate actual width and center it
        let gameOverX = frame.midX - (gameOverText.calculateAccumulatedFrame().width / 2)
        gameOverText.position = CGPoint(x: gameOverX, y: frame.midY + 50)
        gameOverText.name = "gameOverScreen"
        addChild(gameOverText)
        
        // Create SPACE TO START text
        let startText = createVectorText("SPACE TO START",
                                       position: CGPoint(x: frame.midX, y: frame.midY - 50),
                                       color: .white,
                                       scale: 0.5)
        
        // Calculate actual width and center it
        let startX = frame.midX - (startText.calculateAccumulatedFrame().width / 2)
        startText.position = CGPoint(x: startX, y: frame.midY - 50)
        startText.name = "gameOverScreen"
        addChild(startText)
        
        // Reset game state but keep scene
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
    private func createBasketball() -> SKShapeNode {
        // Don't create balls if game is over
        guard gameStarted else { return SKShapeNode() }  // Return empty node if game over
        
        // Create the ball first
        let ball = SKShapeNode(circleOfRadius: 12)
        ball.fillColor = .clear  // No fill
        ball.strokeColor = .orange  // Orange outline
        ball.lineWidth = 2  // 1-pixel outline
        ball.name = "ball"
        
        // Physics for ball - Updated collision settings
        let physicsBody = SKPhysicsBody(circleOfRadius: 12)
        physicsBody.categoryBitMask = PhysicsCategory.obstacle
        physicsBody.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.baseline | PhysicsCategory.obstacle  // Added obstacle to allow ball-ball collisions
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
    
    // Add new function to create a single basketball
    private func createNewBasketball(platformHeights: [CGFloat]) {
        // Clean up old spawn locations first
        let currentTime = Date().timeIntervalSince1970
        recentSpawnLocations = recentSpawnLocations.filter { 
            currentTime - $0.timestamp < spawnCooldownTime 
        }
        
        // Get all possible spawn points
        var availableSpawnPoints: [(x: CGFloat, y: CGFloat)] = []
        
        for height in platformHeights {
            let spawnY = size.height * height + 50  // Above platform
            let spawnX = CGFloat.random(in: size.width * 0.2...size.width * 0.8)
            let potentialPoint = CGPoint(x: spawnX, y: spawnY)
            
            // Check if this location was recently used
            let isRecentlyUsed = recentSpawnLocations.contains { 
                let distance = hypot($0.point.x - potentialPoint.x, 
                                   $0.point.y - potentialPoint.y)
                return distance < 50  // Minimum distance between spawn points
            }
            
            if !isRecentlyUsed {
                availableSpawnPoints.append((spawnX, spawnY))
            }
        }
        
        // If we have available points, spawn a ball
        if let spawnPoint = availableSpawnPoints.randomElement() {
            let ball = createBasketball()
            ball.position = CGPoint(x: spawnPoint.x, y: spawnPoint.y)
            addChild(ball)
            basketballs.append(ball)
            
            // Record this spawn location
            recentSpawnLocations.append((
                point: CGPoint(x: spawnPoint.x, y: spawnPoint.y),
                timestamp: currentTime
            ))
        }
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
        playSound("levelComplete")
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
        playSound("death")  // Play death sound first
        // Remove the player completely
        player.removeFromParent()
        
        // Recreate the player from scratch
        setupPlayer()
        
        // Reset jump state
        canJump = true
    }
    
    private func handleJump() {
        if canJump {
            playSound("jump")
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
                    dx: isMovingLeft ? -JumpForce.runningHorizontal : JumpForce.runningHorizontal,
                    dy: JumpForce.runningVertical
                ))
            } else {
                // Standing jump
                player.physicsBody?.applyImpulse(CGVector(
                    dx: JumpForce.standingHorizontal,
                    dy: JumpForce.standingVertical
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
        
        // Vector-style bullfrog head outline
        let headOutline = SKShapeNode()
        let headPath = CGMutablePath()
        let headWidth: CGFloat = 25
        let headHeight: CGFloat = 35  // Keeping original height
        
        // Create bullfrog head shape with rounded top and bottom
        let points: [CGPoint] = [
            CGPoint(x: -headWidth/2, y: -headHeight/3),      // Left bottom curve start
            CGPoint(x: -headWidth/1.8, y: 0),                // Left middle bulge
            CGPoint(x: -headWidth/2, y: headHeight/4),       // Left upper indent
            CGPoint(x: -headWidth/3, y: headHeight/2),       // Left upper curve
            CGPoint(x: 0, y: headHeight/1.8),                // Top middle
            CGPoint(x: headWidth/3, y: headHeight/2),        // Right upper curve
            CGPoint(x: headWidth/2, y: headHeight/4),        // Right upper indent
            CGPoint(x: headWidth/1.8, y: 0),                 // Right middle bulge
            CGPoint(x: headWidth/2, y: -headHeight/3)        // Right bottom curve start
        ]
        
        // Draw head outline with curved bottom and top
        headPath.move(to: points[0])
        
        // Draw left side up to the start of top curve
        for i in 1...3 {
            headPath.addLine(to: points[i])
        }
        
        // Draw curved top
        let topControlPoint = CGPoint(x: 0, y: headHeight/1.7 + 2)
        headPath.addQuadCurve(to: points[5], control: topControlPoint)
        
        // Draw right side down
        for i in 6..<points.count {
            headPath.addLine(to: points[i])
        }
        
        // Add curved bottom
        let bottomControlPoint = CGPoint(x: 0, y: -headHeight/2 - 2)
        headPath.addQuadCurve(to: points[0], control: bottomControlPoint)
        
        headOutline.path = headPath
        headOutline.strokeColor = .green
        headOutline.lineWidth = 2
        headOutline.fillColor = .clear
        player.addChild(headOutline)
        
        // Vector-style eyes (larger stop sign shaped)
        let eyeSize: CGFloat = 10  // Increased from 8 to 10
        let eyeY = headHeight/5    // Adjusted position for bullfrog face
        
        // Function to create stop sign shaped eye
        func createStopSignEye(isLeft: Bool) -> SKShapeNode {
            let eye = SKShapeNode()
            let eyePath = CGMutablePath()
            let center = CGPoint(x: isLeft ? -headWidth/3 : headWidth/3, y: eyeY)
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
        
        // Keep existing smile but adjust position higher
        let expression = SKShapeNode()
        let expressionPath = CGMutablePath()
        let mouthWidth: CGFloat = headWidth/2
        let mouthY = -headHeight/4 + 3  // Moved up 3 pixels
        
        expressionPath.move(to: CGPoint(x: -mouthWidth/2, y: mouthY))
        expressionPath.addQuadCurve(
            to: CGPoint(x: mouthWidth/2, y: mouthY),
            control: CGPoint(x: 0, y: mouthY - 5)
        )
        
        expression.path = expressionPath
        expression.strokeColor = .white
        expression.lineWidth = 2
        player.addChild(expression)
        
        // Physics setup - use the same path as the head outline for physics
        player.physicsBody = SKPhysicsBody(polygonFrom: headPath)  // Use the same path we drew
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
                                y: baselineHeight + playerSize.height)  // Added full height instead of half
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
        playSound("score")
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
        let digitSpacing: CGFloat = 5  // Add spacing between digits
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
        var totalWidth: CGFloat = 0  // Track total width for centering
        
        // First calculate total width
        totalWidth = CGFloat(digits.count) * (digitWidth + digitSpacing) - digitSpacing
        
        // Start drawing from the left, accounting for total width
        var currentX: CGFloat = -totalWidth / 2  // Center the entire number
        
        for (_, digit) in digits.enumerated() {
            let digitNode = SKNode()
            
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
            
            // Position each digit with proper spacing
            digitNode.position = CGPoint(x: currentX, y: 0)
            numberNode.addChild(digitNode)
            
            // Move to next digit position
            currentX += digitWidth + digitSpacing
        }
        
        numberNode.position = position
        return numberNode
    }
    
    // Add this new function for the vector explosion effect
    private func createVectorExplosion(at position: CGPoint) {
        playSound("ballCollect")
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
        playSound("ballImplosion")
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
        
        // Create bullfrog head points (same as setup)
        let points: [CGPoint] = [
            CGPoint(x: -headWidth/2, y: -headHeight/3),      // Left bottom curve start
            CGPoint(x: -headWidth/1.8, y: 0),                // Left middle bulge
            CGPoint(x: -headWidth/2, y: headHeight/4),       // Left upper indent
            CGPoint(x: -headWidth/3, y: headHeight/2),       // Left upper curve
            CGPoint(x: 0, y: headHeight/1.8),                // Top middle
            CGPoint(x: headWidth/3, y: headHeight/2),        // Right upper curve
            CGPoint(x: headWidth/2, y: headHeight/4),        // Right upper indent
            CGPoint(x: headWidth/1.8, y: 0),                 // Right middle bulge
            CGPoint(x: headWidth/2, y: -headHeight/3)        // Right bottom curve start
        ]
        
        // Create individual lines for each segment
        for i in 0..<points.count-1 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: points[i])
            path.addLine(to: points[i + 1])
            line.path = path
            line.strokeColor = .green
            line.lineWidth = 2
            line.position = player.position
            addChild(line)
            headLines.append(line)
        }
        
        // Add curved bottom as a single line
        let bottomLine = SKShapeNode()
        let bottomPath = CGMutablePath()
        bottomPath.move(to: points.last!)
        let bottomControlPoint = CGPoint(x: 0, y: -headHeight/2 - 2)
        bottomPath.addQuadCurve(to: points[0], control: bottomControlPoint)
        bottomLine.path = bottomPath
        bottomLine.strokeColor = .green
        bottomLine.lineWidth = 2
        bottomLine.position = player.position
        addChild(bottomLine)
        headLines.append(bottomLine)
        
        // Add curved top as a single line
        let topLine = SKShapeNode()
        let topPath = CGMutablePath()
        topPath.move(to: points[3])  // Left upper curve
        let topControlPoint = CGPoint(x: 0, y: headHeight/1.7 + 2)
        topPath.addQuadCurve(to: points[5], control: topControlPoint)  // To right upper curve
        topLine.path = topPath
        topLine.strokeColor = .green
        topLine.lineWidth = 2
        topLine.position = player.position
        addChild(topLine)
        headLines.append(topLine)
        
        // Create lines for larger eyes
        let eyeSize: CGFloat = 10
        let eyeY = headHeight/5
        
        // Left eye
        let leftEye = SKShapeNode(circleOfRadius: eyeSize/2)
        leftEye.strokeColor = .white
        leftEye.lineWidth = 2
        leftEye.position = CGPoint(x: player.position.x - headWidth/3, y: player.position.y + eyeY)
        addChild(leftEye)
        headLines.append(leftEye)
        
        // Right eye
        let rightEye = SKShapeNode(circleOfRadius: eyeSize/2)
        rightEye.strokeColor = .white
        rightEye.lineWidth = 2
        rightEye.position = CGPoint(x: player.position.x + headWidth/3, y: player.position.y + eyeY)
        addChild(rightEye)
        headLines.append(rightEye)
        
        // Smile (moved up 3 pixels)
        let smile = SKShapeNode()
        let smilePath = CGMutablePath()
        let mouthWidth: CGFloat = headWidth/2
        let mouthY = -headHeight/4 + 3  // Moved up 3 pixels
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
    
    // Fix the createVectorText function
    private func createVectorText(_ text: String, position: CGPoint, color: NSColor, scale: CGFloat = 1.0) -> SKNode {
        let textNode = SKNode()
        var offsetX: CGFloat = 0
        
        for char in text.uppercased() {
            if let points = vectorLetters[String(char)] {
                let letterNode = SKNode()
                
                // Draw lines for each pair of points
                for i in stride(from: 0, to: points.count, by: 2) {
                    let line = SKShapeNode()
                    let path = CGMutablePath()
                    
                    let startPoint = CGPoint(
                        x: points[i].x * scale,
                        y: points[i].y * scale
                    )
                    let endPoint = CGPoint(
                        x: points[i + 1].x * scale,
                        y: points[i + 1].y * scale
                    )
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                    
                    line.path = path
                    line.strokeColor = color
                    line.lineWidth = 2
                    letterNode.addChild(line)
                }
                
                letterNode.position = CGPoint(x: offsetX, y: 0)
                textNode.addChild(letterNode)
                
                offsetX += 50 * scale  // Space between letters
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
        baseline.lineWidth = baselineLineWidth
        addChild(baseline)
        
        // Create 3 evenly spaced red death zones
        let totalWidth = size.width
        let usableWidth = totalWidth - (deathZoneWidth * 3)
        let spacing = usableWidth / 4
        
        for i in 0..<3 {
            let deathZone = SKShapeNode()
            let deathZonePath = CGMutablePath()
            
            let xPosition = spacing + (CGFloat(i) * (deathZoneWidth + spacing))
            deathZonePath.move(to: CGPoint(x: xPosition, y: 1))  // 1px up from bottom
            deathZonePath.addLine(to: CGPoint(x: xPosition + deathZoneWidth, y: 1))  // 1px up from bottom
            
            deathZone.path = deathZonePath
            deathZone.strokeColor = .red
            deathZone.lineWidth = baselineLineWidth
            
            // Add physics body for death zone
            deathZone.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: xPosition, y: 1),
                                                 to: CGPoint(x: xPosition + deathZoneWidth, y: 1))
            deathZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            deathZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
            deathZone.physicsBody?.collisionBitMask = 0
            
            addChild(deathZone)
        }
    }
    
    // Update ball removal to maintain accurate count
    private func removeBall(_ ball: SKShapeNode) {
        ball.removeFromParent()
        if let index = basketballs.firstIndex(of: ball) {
            basketballs.remove(at: index)
            currentBallCount -= 1
        }
    }
}

