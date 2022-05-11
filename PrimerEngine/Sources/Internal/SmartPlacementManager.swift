//
//  SmartPlacement.swift
//  PrimerEngine
//
//  Created by Eric Florenzano on 1/14/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation
import ARKit

final class SmartPlacementManager {
    // State management and propagation
    public var state: EngineState.SmartPlacementState = .walkToWall
    public var onStateChange: ((_ nextState: EngineState.SmartPlacementState) -> Void)? = nil

    // Walk to wall state constants
    private let walkDistance: Float = 0.5

    // Tilt phone state constants
    private let tiltThreshhold: Float = 0.025

    // Internal state variables
    private var prevState: EngineState.SmartPlacementState = .walkToWall
    private var startCameraPos: simd_float3 = simd_float3(0, 0, 0)

    public func reset() {
        state = .walkToWall
    }

    public func didUpdate(session: ARSession, frame: ARFrame) {
        prevState = state
        switch state {
        case .walkToWall:
            didUpdateWalkToWall(session: session, frame: frame)
        case .tiltPhone:
            didUpdateTiltPhone(session: session, frame: frame)
        case .tapToPlace: break // Nothing to do if we're ready
        }
    }

    // Check to see if the user is moving towards a wall
    // (distance moved was over `walkDistance` meters)
    private func didUpdateWalkToWall(session: ARSession, frame: ARFrame) {
        if prevState != .walkToWall {
            startCameraPos = frame.camera.transform.position
        }
        if distance(startCameraPos, frame.camera.transform.position) > walkDistance {
            print("[Smart Placement] State 1: Moved towards wall, waiting for phone tilt...")
            setNextState(.tiltPhone)
            return
        }
    }

    // Check to see if the user has pointed their phone perpendicular to wall
    // (unit direction vector Y-axis has passed a threshhold)
    private func didUpdateTiltPhone(session: ARSession, frame: ARFrame) {
        let cameraForward = frame.raycastQuery(from: CGPoint(x: 0.5, y: 0.5), allowing: .existingPlaneGeometry, alignment: .vertical).direction
        if abs(-1.0 - cameraForward.y) < tiltThreshhold {
            print("[Smart Placement] State 2: Phone tilted, waiting for swatch placement...")
            setNextState(.tapToPlace)
            return
        }
    }

    // MARK: - Utilities
    // Set the next smart placement state and call onChange function to propagate state elsewhere
    private func setNextState(_ nextState: EngineState.SmartPlacementState) {
        state = nextState
        if let onChange = onStateChange {
            onChange(nextState)
        }
    }
}
