//
//  GameViewController.swift
//  Waveform
//
//  Created by Eryn Wells on 9/16/18.
//  Copyright © 2018 Eryn Wells. All rights reserved.
//

import SceneKit
import QuartzCore

protocol SlidersDelegate: AnyObject {
    func delayXScaleAdjusted(newValue: Double)
    func delayYScaleAdjusted(newValue: Double)
    func inputXScaleAdjusted(newValue: Double)
    func inputYScaleAdjusted(newValue: Double)
}

class GameViewController: NSViewController, SCNSceneRendererDelegate, SlidersDelegate {
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

                    ijSphere.name = "sphere\(i),\(j)"
                    ijSphere.worldPosition = SCNVector3(x: CGFloat(-GameViewController.numberOfBallsPerSide / 2) + CGFloat(i),
                                                        y: 0.0,
                                                        z: CGFloat(-GameViewController.numberOfBallsPerSide / 2) + CGFloat(j))

                    let ijMaterial = ijSphere.geometry!.firstMaterial!.copy() as! SCNMaterial
                    ijSphere.geometry!.replaceMaterial(at: 0, with: ijMaterial)

                    sphereContainer.addChildNode(ijSphere)
                }
            }
        }

        sphereContainer.runAction(SCNAction.repeatForever(SCNAction.rotate(by: CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 40.0)))
        
        // set the scene to the view
        sceneView.scene = scene
        
        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // configure the view
        sceneView.backgroundColor = NSColor.black
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("showSliders"), sender: self)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == NSStoryboardSegue.Identifier("showSliders") {
            let windowController = segue.destinationController as? NSWindowController
            let slidersViewController = windowController?.contentViewController as? SlidersViewController
            slidersViewController?.delegate = self
        }
    }

    func delayForSphereAt(x: Int, y: Int) -> Double {
        return 0.05 * Double(x) + 0.05 * Double(y)
    }

    // MARK: - SCNRendererDelegate

    var delayXScale = 0.05
    var delayYScale = 0.05
    var inputXScale = 2.0
    var inputYScale = 2.0

    var maxY = 0.0
    var minY = 0.0

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for z in 0..<GameViewController.numberOfBallsPerSide {
            for x in 0..<GameViewController.numberOfBallsPerSide {
                let idx = z * GameViewController.numberOfBallsPerSide + x
                let node = balls[idx]

                //let delay = delayForSphereAt(x: x, y: z)
                let delayX = delayXScale * Double(x)
                let delayY = delayYScale * Double(z)
                let inputX = inputXScale * (time + delayX)
                let inputY = inputYScale * (time + delayY)
                let y = sin(inputX) + sin(2.0 * inputX) + sin(inputY) + sin(2.0 * inputY)

                node.worldPosition.y = CGFloat(y)

                maxY = max(y, maxY)
                minY = min(y, minY)
                let scale = CGFloat(map(y, inMin: minY, inMax: maxY, outMin: 0.0, outMax: 1.0))
                node.scale = SCNVector3(x: scale, y: scale, z: scale)
            }
        }
    }

    // MARK: - SlidersDelegate

    func delayXScaleAdjusted(newValue: Double) {
        delayXScale = newValue
    }

    func delayYScaleAdjusted(newValue: Double) {
        delayYScale = newValue
    }

    func inputXScaleAdjusted(newValue: Double) {
        inputXScale = newValue
    }

    func inputYScaleAdjusted(newValue: Double) {
        inputYScale = newValue
    }

    // MARK: - Private

    func map(_ x: Double, inMin: Double, inMax: Double, outMin: Double, outMax: Double) -> Double {
        return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
}

class SlidersViewController: NSViewController {
    weak var delegate: SlidersDelegate?

    @IBOutlet weak var delayXSlider: NSSlider!
    @IBOutlet weak var delayYSlider: NSSlider!
    @IBOutlet weak var inputXSlider: NSSlider!
    @IBOutlet weak var inputYSlider: NSSlider!

    @IBOutlet weak var delayXLabel: NSTextField!
    @IBOutlet weak var delayYLabel: NSTextField!
    @IBOutlet weak var inputXLabel: NSTextField!
    @IBOutlet weak var inputYLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        delayXLabel.stringValue = formatValueForLabel(delayXSlider.doubleValue)
        delayYLabel.stringValue = formatValueForLabel(delayYSlider.doubleValue)
        inputXLabel.stringValue = formatValueForLabel(inputXSlider.doubleValue)
        inputYLabel.stringValue = formatValueForLabel(inputYSlider.doubleValue)
    }

    @IBAction func sliderValueDidChange(_ sender: Any) {
        if let slider = sender as? NSSlider {
            if slider == delayXSlider {
                delegate?.delayXScaleAdjusted(newValue: slider.doubleValue)
                delayXLabel.stringValue = formatValueForLabel(slider.doubleValue)
            } else if slider == delayYSlider {
                delegate?.delayYScaleAdjusted(newValue: slider.doubleValue)
                delayYLabel.stringValue = formatValueForLabel(slider.doubleValue)
            } else if slider == inputXSlider {
                delegate?.inputXScaleAdjusted(newValue: slider.doubleValue)
                inputXLabel.stringValue = formatValueForLabel(slider.doubleValue)
            } else if slider == inputYSlider {
                delegate?.inputYScaleAdjusted(newValue: slider.doubleValue)
                inputYLabel.stringValue = formatValueForLabel(slider.doubleValue)
            }
        }
    }

    func formatValueForLabel(_ value: Double) -> String {
        return String(format: "%.3f", value)
    }
}
