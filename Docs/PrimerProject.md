## The Primer Project (Front-end, UI Side of the Primer App)
The primer project contains all of the SwiftUI components we are using for our application's UI. 

### Current Status (As of: 07-23-2020)
Below is a representation of the current layout of the project, with the important files highlighted for getting started with the project.

```
Primer
│   *.entitlements
└───Preview Content
└───Sources
│   └───Analytics
|       └───*Analytics.swift: Main source file for analytics
│   └───API
|       └───*.swift: Classes/Structs used for aysnchronously retrieving assets.
│   └───Extensions
│   └───Models 
│   └───UI Classes
│   └───APP
│     └───State
│     └─────AppState.swift - Main state file for the SwiftUI interface
│     └───Library
│     └───AR
│     └─────SwiftUI
│     └───────MainView.swift - You can think of this file as the Base View of the app.
│     └───Intro
│     └─────SceneDelegate.swift - Entry point for the app
└───Supporting Files
    └───*.xcconfig: Configuration files that dictate which API to use.
```

##### Analtics/Analytics.swift
This struct contains all the functions that our app calls to send information to our analytics provider (currently mixpanel).  When Adding any analytics, we should create the analytics call here, and make sure the app then calls the Analytics instance to fire off the event.

##### API
These files contact either the API or our Image server to load content. Allny file in this folder are generic enough to be used anywhere in the app. 
-- For consideration (07-23-2020, James Hall): should we rename this folder to something else?

#### Extensions
If we need to create any Swift extensions, let's put them here. Extensions to custom structs/classes should be put in the file of said struct/class.

#### Models 
This folder is currently empty. Should we move the Object models way from the PrimerEngine project and put them in here? If we were to do that, all the API work would need to come in here as well, but at least then the PrimerEngine is just that.

#### UI Classes
This folder contains components that make up the "atoms" of the app. The idea is to start to create a component library that we can use throughout the app. We can have designers update padding/looks in this area, and it will change the entire app accordingly. As of today (07-23-2020), there's a lot of work to move in this direction.

#### App/State
This is where we store our state files, which contain all of our state variables. With our SwiftUI implementation, we're using these files to hold most, if not all of our data (There are some Views that pull information from an API and hold the data themselves, as of 07-23-2020, I'd like to clean that up)

#### App/Library
This is a folder that is due for cleanup and refactoring. In our V1/Early-V2 app, we had a library controller that could be viewed by the browse products button that was on the app. We've since then moved to a tab nav controller, so we need to clean this whole area up and out.

#### App/AR

#### App/AR/SwiftUI
This contains the meat of the visible part of the app that we see. It houses all of the AR engine view as well as the components placed atop of it.

`MainView.swift` is the start of the view hierarchy and contains all of the view components seen when the app begins. 
