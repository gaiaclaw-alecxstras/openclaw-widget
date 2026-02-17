import WidgetKit
import SwiftUI
import SpriteKit

// MARK: - SpriteKit Scene for Animations
class FaceScene: SKScene {
    var state: SessionStatus.SessionState = .idle
    var tokenPercentage: Double = 0
    
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var backgroundNode: SKSpriteNode!
    private var blinkCoverLeft: SKSpriteNode!
    private var blinkCoverRight: SKSpriteNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupScene()
    }
    
    func setupScene() {
        // Background
        backgroundNode = SKSpriteNode(color: stateColor(.idle), size: CGSize(width: 400, height: 400))
        backgroundNode.position = CGPoint(x: size.width/2, y: size.height/2)
        backgroundNode.zPosition = 0
        addChild(backgroundNode)
        
        // Left Eye
        leftEye = createEye()
        leftEye.position = CGPoint(x: size.width/2 - 60, y: size.height/2)
        addChild(leftEye)
        
        // Right Eye
        rightEye = createEye()
        rightEye.position = CGPoint(x: size.width/2 + 60, y: size.height/2)
        addChild(rightEye)
        
        // Blink covers (same color as background)
        blinkCoverLeft = SKSpriteNode(color: stateColor(.idle), size: CGSize(width: 50, height: 50))
        blinkCoverLeft.position = leftEye.position
        blinkCoverLeft.zPosition = 10
        blinkCoverLeft.isHidden = true
        addChild(blinkCoverLeft)
        
        blinkCoverRight = SKSpriteNode(color: stateColor(.idle), size: CGSize(width: 50, height: 50))
        blinkCoverRight.position = rightEye.position
        blinkCoverRight.zPosition = 10
        blinkCoverRight.isHidden = true
        addChild(blinkCoverRight)
        
        // Start animations
        startIdleAnimation()
        startBlinkAnimation()
    }
    
    func createEye() -> SKShapeNode {
        let eye = SKShapeNode(rectOf: CGSize(width: 40, height: 40))
        eye.fillColor = .black
        eye.strokeColor = .clear
        eye.zPosition = 5
        return eye
    }
    
    func stateColor(_ state: SessionStatus.SessionState) -> UIColor {
        switch state {
        case .idle:
            return UIColor(red: 0.85, green: 0.89, blue: 0.93, alpha: 1.0)
        case .thinking:
            return UIColor(red: 0.96, green: 0.64, blue: 0.64, alpha: 1.0)
        case .talking:
            return UIColor(red: 0.64, green: 0.96, blue: 0.64, alpha: 1.0)
        case .error:
            return UIColor(red: 0.96, green: 0.26, blue: 0.26, alpha: 1.0)
        case .offline:
            return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        }
    }
    
    func updateState(_ newState: SessionStatus.SessionState, percentage: Double) {
        guard state != newState else { return }
        
        let oldState = state
        state = newState
        tokenPercentage = percentage
        
        // Smooth color transition
        let newColor = stateColor(newState)
        let colorAction = SKAction.colorize(with: newColor, colorBlendFactor: 1.0, duration: 0.5)
        backgroundNode.run(colorAction)
        blinkCoverLeft.color = newColor
        blinkCoverRight.color = newColor
        
        // State-specific transitions
        switch newState {
        case .thinking:
            transitionToThinking()
        case .talking:
            transitionToTalking()
        case .idle:
            transitionToIdle()
        case .error:
            transitionToError()
        case .offline:
            transitionToOffline()
        }
    }
    
    // MARK: - State Transitions
    
    func transitionToThinking() {
        removeAllActions()
        
        // Narrow eyes
        let scaleY = SKAction.scaleY(to: 0.3, duration: 0.3)
        leftEye.run(scaleY)
        rightEye.run(scaleY)
        
        // Pulsing background
        let pulseDown = SKAction.scale(to: 0.95, duration: 0.75)
        let pulseUp = SKAction.scale(to: 1.0, duration: 0.75)
        let pulse = SKAction.sequence([pulseDown, pulseUp])
        backgroundNode.run(SKAction.repeatForever(pulse))
    }
    
    func transitionToTalking() {
        removeAllActions()
        
        // Wide eyes
        let scaleY = SKAction.scaleY(to: 1.2, duration: 0.2)
        leftEye.run(scaleY)
        rightEye.run(scaleY)
        
        // Alert wiggle
        let left = SKAction.moveBy(x: -5, y: 0, duration: 0.1)
        let right = SKAction.moveBy(x: 5, y: 0, duration: 0.1)
        let wiggle = SKAction.sequence([left, right, left, right])
        leftEye.run(wiggle)
        rightEye.run(wiggle)
    }
    
    func transitionToIdle() {
        removeAllActions()
        
        // Normal eyes
        let scaleY = SKAction.scaleY(to: 1.0, duration: 0.5)
        leftEye.run(scaleY)
        rightEye.run(scaleY)
        
        startIdleAnimation()
    }
    
    func transitionToError() {
        removeAllActions()
        
        // Concerned - smaller and tilted
        let scale = SKAction.scale(to: 0.8, duration: 0.2)
        let rotateLeft = SKAction.rotate(byAngle: 0.1, duration: 0.2)
        let rotateRight = SKAction.rotate(byAngle: -0.1, duration: 0.2)
        
        leftEye.run(SKAction.group([scale, rotateLeft]))
        rightEye.run(SKAction.group([scale, rotateRight]))
        
        // Red alert flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.colorize(with: stateColor(.error), colorBlendFactor: 1.0, duration: 0.2)
        ])
        backgroundNode.run(SKAction.repeatForever(flash))
    }
    
    func transitionToOffline() {
        removeAllActions()
        
        // Close eyes
        let scaleY = SKAction.scaleY(to: 0.1, duration: 0.5)
        leftEye.run(scaleY)
        rightEye.run(scaleY)
    }
    
    // MARK: - Continuous Animations
    
    func startIdleAnimation() {
        // Slow drift
        let drift = SKAction.moveBy(x: 3, y: 0, duration: 2.0)
        let driftBack = SKAction.moveBy(x: -3, y: 0, duration: 2.0)
        let sequence = SKAction.sequence([drift, driftBack])
        leftEye.run(SKAction.repeatForever(sequence))
        rightEye.run(SKAction.repeatForever(sequence))
    }
    
    func startBlinkAnimation() {
        let blinkDuration = 0.1
        let waitDuration = Double.random(in: 2.0...5.0)
        
        let blink = SKAction.run { [weak self] in
            self?.blinkCoverLeft.isHidden = false
            self?.blinkCoverRight.isHidden = false
        }
        let unblink = SKAction.run { [weak self] in
            self?.blinkCoverLeft.isHidden = true
            self?.blinkCoverRight.isHidden = true
        }
        let wait = SKAction.wait(forDuration: blinkDuration)
        let waitBetween = SKAction.wait(forDuration: waitDuration)
        
        let blinkSequence = SKAction.sequence([blink, wait, unblink, waitBetween])
        run(SKAction.repeatForever(blinkSequence))
    }
}

// MARK: - SwiftUI Wrapper
struct AnimatedFaceView: View {
    let state: SessionStatus.SessionState
    let tokenPercentage: Double
    
    var scene: FaceScene {
        let scene = FaceScene(size: CGSize(width: 300, height: 300))
        scene.scaleMode = .aspectFill
        scene.state = state
        scene.tokenPercentage = tokenPercentage
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: state) { newState in
                scene.updateState(newState, percentage: tokenPercentage)
            }
            .onChange(of: tokenPercentage) { newPercentage in
                scene.tokenPercentage = newPercentage
            }
    }
}
