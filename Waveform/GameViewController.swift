//
//  GameViewController.swift
//  Waveform
//
//  Created by Eryn Wells on 9/16/18.
//  Copyright © 2018 Eryn Wells. All rights reserved.
//

import SceneKit
import QuartzCore

class GameViewController: NSViewController, SCNSceneRendererDelegate {
    static let numberOfBallsPerSide = 41

    private var balls = [SCNNode]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sceneView = view as? SCNView else {
            fatalError("My view isn't a SCNView!")
        }
        sceneView.delegate = self
        sceneView.rendersContinuously = true
        sceneView.preferredFramesPerSecond = 30

        // create a new scene
        let scene = SCNScene(named: "art.scnassets/blank.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: CGFloat(GameViewController.numberOfBallsPerSide / 7),
                                         y: 1.5,
                                         z: CGFloat(GameViewController.numberOfBallsPerSide / 3))
        cameraNode.look(at: SCNVector3())
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        let sphereContainer = SCNNode()
        scene.rootNode.addChildNode(sphereContainer)

        if let sphere = scene.rootNode.childNode(withName: "sphere", recursively: false) {
            // Remove it. We're going to copy it all over the place.
            sphere.removeFromParentNode()
            for i in 0..<GameViewController.numberOfBallsPerSide {
                for j in 0..<GameViewController.numberOfBallsPerSide {
                    let ijSphere = sphere.clone()
                    balls.append(ijSphere)
                    ijSphere.worldPosition = SCNVector3(x: CGFloat(-GameViewController.numberOfBallsPerSide / 2) + CGFloat(i),
                                                        y: 0.0,
                                                        z: CGFloat(-GameViewController.numberOfBallsPerSide / 2) + CGFloat(j))
                    sphereContainer.addChildNode(ijSphere)
                }
            }
        }

        sphereContainer.runAction(SCNAction.repeatForever(SCNAction.rotate(by: CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 40.0)))
        
        // set the scene to the view
        sceneView.scene = scene
        
        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // configure the view
        sceneView.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = sceneView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        sceneView.gestureRecognizers = gestureRecognizers
    }
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }

    func delayForSphereAt(x: Int, y: Int) -> Double {
        return 0.05 * Double(x) + 0.03 * Double(y)
    }

    // MARK: - SCNRendererDelegate

    var maxY = 0.0
    var minY = 0.0

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for z in 0..<GameViewController.numberOfBallsPerSide {
            for x in 0..<GameViewController.numberOfBallsPerSide {
                let idx = z * GameViewController.numberOfBallsPerSide + x
                let node = balls[idx]

                let delay = delayForSphereAt(x: x, y: z)
                let inputX = 0.5 * time + delay
                let y = sin(inputX) + sin(2.0 * inputX) + sin(4.0 * inputX) + sin(8.0 * inputX)

                node.worldPosition.y = CGFloat(y)

                maxY = max(y, maxY)
                minY = min(y, minY)
                let scale = CGFloat(map(y, inMin: minY, inMax: maxY, outMin: 0.0, outMax: 1.0))
                node.scale = SCNVector3(x: scale, y: scale, z: scale)
            }
        }
    }

    func map(_ x: Double, inMin: Double, inMax: Double, outMin: Double, outMax: Double) -> Double {
        return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
    }
}
