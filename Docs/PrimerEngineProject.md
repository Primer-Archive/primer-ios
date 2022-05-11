## The PrimerEngine Project (Back-End, ARKit/SceneKit side of the Primer App)
The PrimerEngine contains all of the ARKit and SceneKit code that powers our app.

### Current Status (As of: 07-23-2020)
Below is a representation of the current layout of the project, with the important files highlighted for getting started with the project.

```
PrimerEngine
└───Sources
│   └───Resources
|       └───*.json - These are the SCNTechnique files that execute our shaders
|       └───*.xcassets - Various asset files for our SceneKit instance
│   └───Sources
│   └─────Headers - Bridging Header for Swift/Obj-C code.
│   └─────Internal
│   └───────Legacy
│   └───────Sccene
│   └─────Material Previews - (This looks like a candidate for removal, not used.)
│   └─────Models
│   └─────Shaders
└───Supporting Files 
```

##### Sources/Internal/Legacy
A majority of the code in this folder is from the initial Primer Version,but is still mostly used in this version. It contains our Resizer and the grid that we display while placing a moving a swatch. 

- `PlatformSwatchView.swift` could be a candidate for refactoring/removal.
- `BlendingTechnique.swift` is a candidate for moving into a different location.

##### Sources/Internal/Scene
The files contained in this folder are different subclasses of Nodes or tools to help display our scene in AR. 

`SceneController.swift` - houses the main scene of the AR experience. Here we setup the lighting, `SwatchNode` and `WorldGeometryNode`

`SwatchNode.swift` - This is class that creates and handles the actual swatch we seein the AR experience. Here is where we apply transforms and material changes to the node.

`WorldGeometryNode.swift` - This is the class that displays the mesh supplied to us from ARKit.

#### Sources/Internal

`APIClient.swift` This class handles commnunicating with thre Ruby on Rails server to get all of the assets and information about all of our products. This should probably be moved over to the `Primer` project and push it's info to this project.

`EngineState.swift` - Much like the `AppState` file in the `Primer` project, this handles all of the engines information. `AppState` actually holds a copy of this information to inform it's dependants.

`EngineView.swift` - This is the SwiftUI component that gets added to our SwiftUI stack in the main `Primer` project. It displays a `EngineViewController`.

`EngineViewController.swift` This controller handles sending all of the gestures, LIDAR (if available), and tap information into the App.
