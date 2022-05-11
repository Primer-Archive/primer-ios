//
//  SceneLights.swift
//  PrimerEngine
//
//  Created by Eric Florenzano on 3/8/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

public final class SceneLights {
    private let probeOffset: Float = 0.4

    public var ambientLightIntensityMultiplier: CGFloat = 0
    public var omniLightIntensityMultiplier: CGFloat = 0
    public var userLightIntensityMultiplier: CGFloat = 0
    public var radianceLightMultiplier: CGFloat = 0
    public var irradianceLightMultiplier: CGFloat = 0
    public var omniLightDistance: Float = 0
    public var showDebug: Bool = true

    private let sceneView: ARSCNView

    private let ambientLight = SCNLight()

    private let userLight = SCNLight()
    private let userLightNode = SCNNode()

    private var omniLights: [SCNLight] = []
    private var omniLightNodes: [SCNNode] = []
    private var omniLightDirs: [SIMD3<Float>] = []
    private var omniLightIntensities: [Float] = []
    private var omniLightDistances: [Float] = []

    private var probeAnchor: AREnvironmentProbeAnchor? = nil

    private var radianceIntensities: [SCNLight: CGFloat] = [:]

    private var rootNode: SCNNode {
        get { return sceneView.scene.rootNode }
    }

    public init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setup(generateNum: Int = 0) {
        ambientLightIntensityMultiplier = 0.462
        omniLightIntensityMultiplier = 0.012
        userLightIntensityMultiplier = 0.00001
        radianceLightMultiplier = 0.304
        omniLightDistance = 25

        ambientLight.type = .ambient
        rootNode.light = ambientLight
        ambientLight.intensity = 0.0

        userLight.type = .spot
        userLight.intensity = 0.0
        userLight.spotOuterAngle = 80.0
        userLightNode.light = userLight
        if let pov = sceneView.pointOfView {
            userLightNode.removeFromParentNode()
            pov.addChildNode(userLightNode)
        }

        clearOmnis()

        if generateNum > 0 {
            generate(generateNum: generateNum)
            return
        }

        omniLights = [SCNLight(), SCNLight(), SCNLight()]
        omniLightNodes = [SCNNode(), SCNNode(), SCNNode()]
        omniLightDirs =  [SIMD3<Float>(-0.65, 0.2, 0.0), SIMD3<Float>(0.65, 0.05, 0.0), SIMD3<Float>(0.0, 0.2, 0.0)]
        omniLightIntensities =  [1, 1, 1]
        omniLightDistances =  [1, 1, 1]

        for (index, light) in omniLights.enumerated() {
            light.type = .omni
            light.intensity = 0.0
            let node = omniLightNodes[index]
            node.light = light
            node.removeFromParentNode()
            rootNode.addChildNode(node)
        }
    }

    private func clearOmnis() {
        omniLights = []
        omniLightNodes.forEach { (node: SCNNode) in
            node.removeFromParentNode()
        }
        omniLightNodes = []
        omniLightDirs = []
        omniLightIntensities = []
        omniLightDistances = []
    }

    private func generate(generateNum: Int) {
        for _ in 0..<generateNum {
            let light = SCNLight()
            light.type = .omni
            light.intensity = 0.0
            let node = SCNNode()
            node.light = light
            rootNode.addChildNode(node)

            omniLights.append(light)
            omniLightNodes.append(node)
            omniLightDirs.append(simd_float3(.random(in: -1...1), .random(in: -1...1), 0))
            omniLightIntensities.append(.random(in: 0.5...1))
            omniLightDistances.append(.random(in: 0.5...1))
        }

        print("omniLightDirs = ", omniLightDirs)
        print("omniLightIntensities = ", omniLightIntensities)
        print("omniLightDistances = ", omniLightDistances)
    }

    public func update(intensity: CGFloat, temperature: CGFloat, forward: SIMD3<Float>, position: SIMD3<Float>, swatch: Swatch? = nil) {
        ambientLight.intensity = intensity * ambientLightIntensityMultiplier
        ambientLight.temperature = temperature

        userLight.intensity = intensity * userLightIntensityMultiplier
        userLight.temperature = temperature

        //sceneView.scene.lightingEnvironment.contents = sceneView.scene.background.contents
        //sceneView.scene.lightingEnvironment.intensity = sceneView.scene.background.intensity

        for (i, dist) in omniLightDistances.enumerated() {
            let light = omniLights[i]
            let node = omniLightNodes[i]
            let dir = omniLightDirs[i]
            let brightness = omniLightIntensities[i]
            light.intensity = intensity * omniLightIntensityMultiplier * CGFloat(brightness)
            light.temperature = temperature
            let offset = normalize(forward + dir)
            node.simdWorldPosition = position + (offset * omniLightDistance * dist)
            if let child = node.childNodes.first {
                child.isHidden = !showDebug
            }
        }

        updateLightProbes(intensity: intensity, swatch: swatch, position: position + (forward * probeOffset))
    }

    private func updateLightProbes(intensity: CGFloat, swatch: Swatch? = nil, position: SIMD3<Float>) {
        guard let swatchSize = swatch?.size else {
            if let probe = probeAnchor {
                probeAnchor = nil
                sceneView.session.remove(anchor: probe)
            }
            return
        }

        rootNode.enumerateHierarchy { (node: SCNNode, _) in
            if let light = node.light, light.type == .probe, light.probeType == .radiance {
                if let pastIntensity = radianceIntensities[light], abs(light.intensity - pastIntensity) <= .ulpOfOne {
                    return
                }
                let nextIntensity = light.intensity * self.radianceLightMultiplier
                light.intensity = nextIntensity
                radianceIntensities[light] = nextIntensity
            }
        }

        let extentSide = max(swatchSize.width, swatchSize.height) * 30
        if let probe = probeAnchor {
            let maintainedPosition = simd_distance_squared(probe.transform.position, position) <= .ulpOfOne
            let maintainedSize = abs(probe.extent.x - extentSide) <= .ulpOfOne
            if maintainedPosition && maintainedSize {
                return
            }
            sceneView.session.remove(anchor: probe)
        }

        var transform = matrix_identity_float4x4
        transform.translation = position
        let extent = simd_float3(extentSide, extentSide, extentSide)
        let probe = AREnvironmentProbeAnchor(transform: transform, extent: extent)
        probeAnchor = probe
        sceneView.session.add(anchor: probe)
    }
}

public final class SceneLightsDebugPanel : UIView {
    private var currentFrame: ARFrame? = nil

    public var ambientTemperatureOffset: CGFloat = 0

    private let sceneLights: SceneLights

    private let temperatureOffsetLabel = UILabel()
    private let temperatureOffsetSlider = UISlider()
    private let radianceIntensityLabel = UILabel()
    private let radianceIntensitySlider = UISlider()
    private let ambientLightIntensityLabel = UILabel()
    private let ambientLightIntensitySlider = UISlider()
    private let omniLightIntensityLabel = UILabel()
    private let omniLightIntensitySlider = UISlider()
    private let omniLightDistanceLabel = UILabel()
    private let omniLightDistanceSlider = UISlider()
    private let userLightIntensityLabel = UILabel()
    private let userLightIntensitySlider = UISlider()

    public init(sceneLights: SceneLights, view: UIView) {
        self.sceneLights = sceneLights
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
        view.addSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            widthAnchor.constraint(equalTo: view.widthAnchor),
            heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setLimits() {
        temperatureOffsetSlider.minimumValue = -3600
        temperatureOffsetSlider.maximumValue = 3600

        radianceIntensitySlider.maximumValue = 2

        ambientLightIntensitySlider.maximumValue = 1.2

        omniLightIntensitySlider.maximumValue = 0.075

        omniLightDistanceSlider.maximumValue = 50

        userLightIntensitySlider.maximumValue = 0.005
    }

    public func resetValues() {
        temperatureOffsetSlider.value = 0
        radianceIntensitySlider.value = Float(sceneLights.radianceLightMultiplier)
        ambientLightIntensitySlider.value = Float(sceneLights.ambientLightIntensityMultiplier)
        omniLightIntensitySlider.value = Float(sceneLights.omniLightIntensityMultiplier)
        omniLightDistanceSlider.value = sceneLights.omniLightDistance
        userLightIntensitySlider.value = Float(sceneLights.userLightIntensityMultiplier)
    }

    private func setupSubviews(labels: [UILabel], sliders: [UISlider]) -> [UIView] {
        return zip(labels, sliders).flatMap { (_ label: UILabel, _ slider: UISlider) -> [UIView] in
            label.font = .monospacedSystemFont(ofSize: 14, weight: .bold)

            slider.addTarget(self, action: #selector(onChanged), for: .valueChanged)
            slider.isContinuous = true

            return [label, slider]
        }
    }

    private func setup() {
        let labels = [
            temperatureOffsetLabel,
            radianceIntensityLabel,
            ambientLightIntensityLabel,
            omniLightIntensityLabel,
            omniLightDistanceLabel,
            omniLightDistanceLabel,
            userLightIntensityLabel,
        ]
        let sliders = [
            temperatureOffsetSlider,
            radianceIntensitySlider,
            ambientLightIntensitySlider,
            omniLightIntensitySlider,
            omniLightDistanceSlider,
            omniLightDistanceSlider,
            userLightIntensitySlider,
        ]
        let subviews = setupSubviews(labels: labels, sliders: sliders)

        setLimits()
        resetValues()
        update()

        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.isHidden = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = -2
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -255),
            stackView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    @objc
    private func onChanged(view: UIView) {
        switch (view) {
        case temperatureOffsetSlider:
            ambientTemperatureOffset = CGFloat(temperatureOffsetSlider.value)
            break
        case radianceIntensitySlider:
            sceneLights.radianceLightMultiplier = CGFloat(radianceIntensitySlider.value)
        case ambientLightIntensitySlider:
            sceneLights.ambientLightIntensityMultiplier = CGFloat(ambientLightIntensitySlider.value)
        case omniLightIntensitySlider:
            sceneLights.omniLightIntensityMultiplier = CGFloat(omniLightIntensitySlider.value)
        case omniLightDistanceSlider:
            sceneLights.omniLightDistance = omniLightDistanceSlider.value
        case userLightIntensitySlider:
            sceneLights.userLightIntensityMultiplier = CGFloat(userLightIntensitySlider.value)
        default:
            return
        }
        update()
    }

    public func update(frame: ARFrame? = nil) {
        if frame  != nil {
            currentFrame = frame
        }

        let tempOffsetFmt = String(format:"%.2f", temperatureOffsetSlider.value)
        temperatureOffsetLabel.text = "Temperature Offset: \(tempOffsetFmt)"

        let omniDistFmt = String(format:"%.2f", sceneLights.omniLightDistance)
        omniLightDistanceLabel.text = "Omni Distance: \(omniDistFmt)"

        let radianceFmt = String(format:"%.3f", sceneLights.radianceLightMultiplier)
        let ambientFmt = String(format:"%.3f", sceneLights.ambientLightIntensityMultiplier)
        let omniFmt = String(format:"%.3f", sceneLights.omniLightIntensityMultiplier)
        let userFmt = String(format:"%.5f", sceneLights.userLightIntensityMultiplier)
        guard let estimate = currentFrame?.lightEstimate else {
            radianceIntensityLabel.text = "Env Radiance: x\(radianceFmt)"
            ambientLightIntensityLabel.text = "Ambient Light: x \(ambientFmt)"
            omniLightIntensityLabel.text = "Omni Light: x \(omniFmt)"
            userLightIntensityLabel.text = "User Light: x \(userFmt)"
            return
        }

        let estimateFmt = String(format: "%.2f", estimate.ambientIntensity)

        let radianceValueFmt = String(format: "%.2f", estimate.ambientIntensity * sceneLights.radianceLightMultiplier)
        radianceIntensityLabel.text = "Env Radiance: \(estimateFmt) x \(radianceFmt) = \(radianceValueFmt)"

        let ambientValueFmt = String(format: "%.2f", estimate.ambientIntensity * sceneLights.ambientLightIntensityMultiplier)
        ambientLightIntensityLabel.text = "Ambient Light: \(estimateFmt) x \(ambientFmt) = \(ambientValueFmt)"

        let omniValueFmt = String(format: "%.2f", estimate.ambientIntensity * sceneLights.omniLightIntensityMultiplier)
        omniLightIntensityLabel.text = "Omni Light: \(estimateFmt) x \(omniFmt) = \(omniValueFmt)"

        let userValueFmt = String(format: "%.5f", estimate.ambientIntensity * sceneLights.userLightIntensityMultiplier)
        userLightIntensityLabel.text = "User Light: \(estimateFmt) x \(userFmt) = \(userValueFmt)"
    }
}
