# Runner's Delight 🏃‍♂️

⚠️ Work in Progress - This project is currently under active development.

A native iOS running tracker app built with SwiftUI, featuring real-time GPS tracking, live run metrics, and persistent data storage.

## Features

- **Real-time GPS Tracking**: Live location updates with CoreLocation integration
- **Interactive Map**: Visual run path display with MapKit
- **Live Run Metrics**: Speed, distance, time, altitude tracking during runs
- **Run History**: Persistent storage of completed runs using SwiftData
- **Clean UI**: Modern interface with custom color theming

## Tech Stack

- **SwiftUI** - Native iOS user interface framework
- **CoreLocation** - GPS location services and tracking
- **MapKit** - Interactive maps and route visualization  
- **SwiftData** - Local data persistence for run history
- **Combine** - Reactive programming for real-time updates

## Architecture

- **MVVM Pattern** - Clean separation of concerns
- **LocationDataManager** - Centralized location service management
- **RunService** - Business logic for active run tracking
- **LiveRunData** - Real-time metrics model
- **RunLog** - Persistent data model for completed runs

## Key Components

```swift
LocationDataManager    // Handles GPS permissions and live location updates
RunService            // Manages active run state and calculations  
LiveRunData           // Real-time metrics (speed, distance, time)
RunLog               // SwiftData model for persistent storage
```

## Demo

<img width="372" height="782" alt="Screenshot 2025-09-24 at 1 47 14 PM" src="https://github.com/user-attachments/assets/457cc3c0-e9d4-47ce-bcce-6656b030c15c" />

https://github.com/user-attachments/assets/d15331dc-278c-4d11-a2be-9e2340fde6fd

> **Note:** Demo video is sped up for demonstration purposes and was recorded on iPhone 16 Pro simulator.

## Getting Started

1. Clone the repository
2. Open `rortiz_RunnersDelight.xcodeproj` in Xcode
3. Ensure location permissions are granted
4. Build and run on iOS device (location services required)

---

*Built as a portfolio project showcasing iOS development skills with modern Swift frameworks.*
