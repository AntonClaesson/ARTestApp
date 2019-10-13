//
//  ViewController.swift
//  TestingApp
//
//  Created by Anton Claesson on 2019-07-03.
//  Copyright © 2019 Anton Claesson. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBAction func resetBtnPressed(_ sender: Any) {
        resetSession()
    }
    
    
    //MARK: - Instance variables
    var coachingOverlay = ARCoachingOverlayView()
    var screenCenter: CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height)
    }
    
    
    
    //MARK: - AR object collections
    
    var verticalPlanes = [SCNNode]()
    
    var horizontalPlanes = [SCNNode]()
    
    var boxes = [SCNNode]()
    
    var spheres = [SCNNode]()
    
    
    
    //MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a configuration and start the AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [])
        
        // Setup gesture recognizers
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tapped(recognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Add and start the coaching overlay view
        setupCoachingOverlay()
    }
    
    
    // MARK: - Gestures
    
    @objc func tapped(recognizer: UITapGestureRecognizer){
        
        let touch = recognizer.location(in: sceneView)
        
        // Make a raycast for existing planes.
        // Successful raycast to this target will create a random colored box.
        // If no existing plane is found make a raycast for estimated planes as backup.
        
        // Estimated planes means that the ray is allowed to intersect with planes ARKit is less confident about.
        // This means that the ray is allowed to intersect with feature points around the ray that ARKit estimates may be planes.
        // Successful raycast to this target will create a random colored sphere
        
        var existingPlaneIntersected = true
        
        if let query = sceneView.raycastQuery(from: touch, allowing: .existingPlaneGeometry, alignment: .any) {
            if let raycastResult = sceneView.session.raycast(query).first{
                
                let box = self.generateRandomBoxNode(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.0)
                box.name = "box"
                let worldPosition = simd_float3(raycastResult.worldTransform.columns.3.x, raycastResult.worldTransform.columns.3.y, raycastResult.worldTransform.columns.3.z)
                box.simdWorldPosition = worldPosition
                
                self.sceneView.scene.rootNode.addChildNode(box)
                self.boxes.append(box)
                
            } else {
                existingPlaneIntersected = false
            }
        }
        
        if !existingPlaneIntersected {
            if let query = sceneView.raycastQuery(from: touch, allowing: .estimatedPlane, alignment: .any) {
                if let raycastResult = sceneView.session.raycast(query).first{
                    
                    let sphere = self.generateRandomSphereNode(radius: 0.2)
                    sphere.name = "sphere"
                    let worldPosition = simd_float3(raycastResult.worldTransform.columns.3.x, raycastResult.worldTransform.columns.3.y, raycastResult.worldTransform.columns.3.z)
                    sphere.simdWorldPosition = worldPosition
                    
                    self.sceneView.scene.rootNode.addChildNode(sphere)
                    self.spheres.append(sphere)
                    
                }
            }
        }
    
       
    // How to perform a tracked raycast.
    
//        // Perform the raycast and keep tracking the result.
//        _ = sceneView.session.trackedRaycast(query, updateHandler: { raycastResults in
//
//            guard let raycastResult = raycastResults.first else {
//                print("No target found.")
//                return
//            }
//
//        })
                
    }
    
    // MARK: - Helper methods
    
    func setupCoachingOverlay(){
        
        // Add the coaching overlay view
        view.addSubview(coachingOverlay)
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            coachingOverlay.leftAnchor.constraint(equalTo: view.leftAnchor),
            coachingOverlay.rightAnchor.constraint(equalTo: view.rightAnchor),
            coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        coachingOverlay.delegate = self
        
        
        // Start the coaching overlay
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.session = sceneView.session
        
    }
    
    func resetSession(){
        
        // Removes the vertical planes
        verticalPlanes.forEach { (node) in
            node.runAction(.removeFromParentNode())
        }
        verticalPlanes = []
        
        // Removes the horizontal planes
        horizontalPlanes.forEach { (node) in
            node.runAction(.removeFromParentNode())
        }
        horizontalPlanes = []
        

        // Remove the boxes
        boxes.forEach { (box) in
            box.runAction(.removeFromParentNode())
        }
        boxes = []
        
        // Remove the spheres
        spheres.forEach { (sphere) in
            sphere.runAction(.removeFromParentNode())
        }
        spheres = []
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking, .stopTrackedRaycasts])
        
    }
    
    
    
    // MARK: - Virtual object creation
    
    /// Creates a box node with a random color
    func generateRandomBoxNode(width: CGFloat, height: CGFloat, length: CGFloat, chamferRadius: CGFloat) -> SCNNode {
        
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        box.firstMaterial?.diffuse.contents = UIColor.init(
            red: CGFloat.random(in: 0.0 ... 1.0),
            green: CGFloat.random(in: 0.0 ... 1.0),
            blue: CGFloat.random(in: 0.0 ... 1.0),
            alpha: 1.0
        )
        
        let node = SCNNode(geometry: box)
        
        return node
    }
    
    
    /// Creates a sphere node with a random color
    func generateRandomSphereNode(radius: CGFloat) -> SCNNode {
        
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = UIColor.init(
            red: CGFloat.random(in: 0.0 ... 1.0),
            green: CGFloat.random(in: 0.0 ... 1.0),
            blue: CGFloat.random(in: 0.0 ... 1.0),
            alpha: 1.0
        )
        
        let node = SCNNode(geometry: sphere)

        return node
    
    }
    
    /// Creates a  plane node with a mesh which will continually be updated as its estimated size changes.
    func createPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        // Create a ARSCNPlaneGeometry instance and update it from the planeAnchor's ARPlaneGeometry property.
        let scenePlaneGeometry = ARSCNPlaneGeometry(device: MTLCreateSystemDefaultDevice()!)
        scenePlaneGeometry?.update(from: planeAnchor.geometry)
        
        let planeNode = SCNNode(geometry: scenePlaneGeometry)
        
        switch planeAnchor.alignment {
        case .horizontal:
            planeNode.name =  "horizontalPlane\(horizontalPlanes.count)"
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)
        case .vertical:
            planeNode.name = "verticalPlane\(verticalPlanes.count)"
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.9)
        @unknown default: break
        }
        
        return planeNode
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
        
        if planeAnchor.alignment == .horizontal {
            horizontalPlanes.append(planeNode)
        }
        
        if planeAnchor.alignment == .vertical {
            verticalPlanes.append(planeNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard
            let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let scenePlaneGeometry = planeNode.geometry as? ARSCNPlaneGeometry
        else { return }
                
        scenePlaneGeometry.update(from: planeAnchor.geometry)
        planeNode.geometry = scenePlaneGeometry
    
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }

    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
