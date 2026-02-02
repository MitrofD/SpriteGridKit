# SpriteGridKit

SpriteGridKit is a lightweight and flexible grid system for SpriteKit. It allows you to easily create grids with customizable cell sizes, insets, and movement. You can move the grid by steps or by a specific distance, query cells in any direction, and handle rows and cells dynamically with callbacks.

## Features

* Fully dynamic grid creation
* Smooth or instant movement
* Access neighboring cells in 8 directions
* Customizable cell size and insets
* Callback hooks for adding/removing cells or rows
* Compatible with iOS, macOS, tvOS, and watchOS

## Installation

Add the following to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/MitrofD/SpriteGridKit.git", from: "1.0.0")
```

and add `SpriteGridKit` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["SpriteGridKit"]
)
```

## Usage

```swift
import SpriteKit
import SpriteGridKit

class GameScene: SKScene {
    var grid: Grid!

    override func didMove(to view: SKView) {
        grid = Grid(size: CGSize(width: 300, height: 400), cellSize: CGSize(width: 50, height: 50))
        addChild(grid)
        grid.build()

        // Move grid down by 3 steps over 1 second
        grid.moveByStep(duration: 1.0, count: 3)

        // Access a cell
        if let cell = grid.cell(at: Grid.Point(row: 0, column: 0)) {
            print("Cell position: \(cell.position)")
        }
    }

    override func update(_ currentTime: TimeInterval) {
        grid.update(currentTime)
    }
}
```

## License

This project is licensed under the MIT License.

