//
//  ViewController.swift
//  FrogMan
//
//  Created by SuperBox64m on 1/2/25.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.skView {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            //view.showsPhysics = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
}

