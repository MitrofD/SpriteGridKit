# SpriteGridKit

A powerful and flexible grid system for SpriteKit that supports both standard rectangular grids and isometric grids with smooth scrolling, dynamic cell management, and infinite scrolling capabilities.

## Features

- **Flexible Grid Types**: Supports standard rectangular and isometric grid layouts
- **Infinite Scrolling**: Efficient cell recycling system for unlimited grid sizes
- **Smooth Movement**: Time-based or step-based grid scrolling with customizable speed
- **Dynamic Cell Management**: Automatic cell addition/removal as the grid scrolls
- **Neighbor Cell Queries**: Easy access to adjacent cells in 8 directions
- **Customizable Insets**: Control grid boundaries and overflow
- **Lifecycle Hooks**: Override methods to respond to grid events
- **Memory Efficient**: Only renders visible cells plus buffer zones

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MitrofD/SpriteGridKit.git", from: "1.0.0")
]
```

### Manual Installation

Copy `SpriteGridKit.swift` into your project.

## Quick Start

### Basic Rectangular Grid

```swift
import SpriteKit
import SpriteGridKit

class GameScene: SKScene {
    var grid: SpriteGridKit!
    
    override func didMove(to view: SKView) {
        // Create a grid
        grid = SpriteGridKit(
            size: CGSize(width: 800, height: 600),
            cellSize: CGSize(width: 50, height: 50),
            insets: Insets(top: 1, right: 0, bottom: 0, left: 0)
        )
        
        addChild(grid)
        grid.build()
        
        // Start infinite scrolling
        grid.moveByStep(duration: 0.5) // Move one step every 0.5 seconds
    }
    
    override func update(_ currentTime: TimeInterval) {
        grid.update(currentTime)
    }
}
```

### Isometric Grid

```swift
class IsometricGrid: SpriteGridKit {
    override func cellPosition(for row: Int, column: Int) -> CGPoint {
        var x = CGFloat(column) * cellSize.width
        
        if row.isMultiple(of: 2) {
            x += cellSize.width / 2
        }
        
        return CGPoint(
            x: x,
            y: CGFloat(row) * (cellSize.height / 2)
        )
    }
    
    override func columnsCount(at row: Int) -> Int {
        let columns = super.columnsCount(at: row)
        return row.isMultiple(of: 2) ? columns - 1 : columns
    }
}

// Usage
let isoGrid = IsometricGrid(
    size: CGSize(width: 800, height: 600),
    cellSize: CGSize(width: 64, height: 32)
)
```

## Core Concepts

### Grid Initialization

```swift
let grid = SpriteGridKit(
    size: CGSize(width: 800, height: 600),    // Viewport size
    cellSize: CGSize(width: 50, height: 50),  // Individual cell size
    insets: Insets(top: 1, right: 0, bottom: 0, left: 0)  // Buffer zones
)
```

### Insets

Insets define buffer zones around the visible area:

```swift
// Uniform insets
let insets = Insets(-1)  // 1 cell buffer on all sides

// Custom per-side insets
let insets = Insets(top: 1, right: 0, bottom: 0, left: 0)

// Symmetric insets
let insets = Insets(x: 1, y: 2)  // 1 cell horizontal, 2 cells vertical
```

### Movement API

#### Step-based Movement

```swift
// Infinite scrolling - move one step every 0.5 seconds
grid.moveByStep(duration: 0.5)

// Move specific number of steps
grid.moveByStep(duration: 0.5, count: 10)  // Move 10 steps downward
grid.moveByStep(duration: 0.5, count: -5)  // Move 5 steps upward

// Adjust speed multiplier (affects all movements)
grid.moveSpeed = 2.0  // Double speed
grid.moveSpeed = 0.5  // Half speed
```

#### Distance-based Movement

```swift
// Move 100 pixels over 2 seconds
grid.move(distance: 100, duration: 2.0)

// Move upward
grid.move(distance: -100, duration: 2.0)

// Instant movement (no animation)
grid.move(distance: 200, duration: 0)
```

#### Control Movement

```swift
// Check if grid is moving
if grid.isMoving {
    print("Grid is currently scrolling")
}

// Stop movement
grid.stop()

// Get current speed
let speed = grid.moveSpeed
```

## Accessing Cells

### Direct Cell Access

```swift
// Get cell at specific row/column
if let cell = grid.cell(at: 5, column: 3) {
    print("Cell position: \(cell.position)")
    print("Cell point: \(cell.point)")
}

// Using Point struct
let point = SpriteGridKit.Point(row: 5, column: 3)
if let cell = grid.cell(at: point) {
    // Use cell
}
```

### Neighbor Cells

```swift
let point = SpriteGridKit.Point(row: 5, column: 3)

// Get specific neighbor
if let northCell = grid.northCell(at: point) { }
if let southCell = grid.southCell(at: point) { }
if let eastCell = grid.eastCell(at: point) { }
if let westCell = grid.westCell(at: point) { }

// Diagonal neighbors
if let nwCell = grid.northWestCell(at: point) { }
if let neCell = grid.northEastCell(at: point) { }
if let swCell = grid.southWestCell(at: point) { }
if let seCell = grid.southEastCell(at: point) { }

// Using Direction enum
if let neighbor = grid.cell(at: point, for: .north) { }
```

### Direction Helpers

```swift
// Get all directions
let allDirections = SpriteGridKit.Direction.allCases

// Get side-specific directions
let westSide = SpriteGridKit.Direction.westSide    // [.west, .northWest, .southWest]
let northSide = SpriteGridKit.Direction.northSide  // [.north, .northWest, .northEast]
let eastSide = SpriteGridKit.Direction.eastSide    // [.east, .northEast, .southEast]
let southSide = SpriteGridKit.Direction.southSide  // [.south, .southEast, .southWest]
```

## Lifecycle Hooks

Override these methods to respond to grid events:

```swift
class CustomGrid: SpriteGridKit {
    // Grid lifecycle
    override func willBuild() {
        print("Grid is about to be built")
    }
    
    override func didBuild() {
        print("Grid has been built")
    }
    
    override func willReset() {
        print("Grid is about to reset")
    }
    
    override func didReset() {
        print("Grid has been reset")
    }
    
    override func willDestroy() {
        print("Grid is about to be destroyed")
    }
    
    override func didDestroy() {
        print("Grid has been destroyed")
    }
    
    // Cell events
    override func didAddCell(_ cell: Cell) {
        // Add visual sprite for this cell
        let sprite = SKSpriteNode(color: .blue, size: cellSize)
        sprite.position = cell.position
        gridNode.addChild(sprite)
    }
    
    override func didRemoveCell(_ cell: Cell) {
        // Remove sprite or clean up resources
    }
    
    // Row events
    override func didAddRow(_ row: Int, cellsOfRow: [Cell]) {
        print("Added row \(row) with \(cellsOfRow.count) cells")
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Cell]) {
        print("Removed row \(row)")
    }
    
    // Movement events
    override func didStop() {
        print("Grid movement stopped")
    }
}
```

## Advanced Example: MapGrid

Here's an example of a complex grid implementation for a game map with procedural path generation:

```swift
class MapGrid: IsometricGrid {
    private var steps: [Step] = []
    private var squares: [Square] = []
    
    override func didAddRow(_ row: Int, cellsOfRow: [Cell]) {
        super.didAddRow(row, cellsOfRow: cellsOfRow)
        
        // Generate game path
        let step = generateNextStep(for: row)
        steps.append(step)
        
        // Add visual representation
        addStepSprite(for: step)
        
        // Generate square areas
        generateSquares(for: row, cellsOfRow: cellsOfRow)
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        // Clean up old steps
        if !steps.isEmpty {
            let step = steps.removeFirst()
            removeStepSprite(for: step)
        }
    }
}
```

## Properties

### Grid Properties

```swift
grid.size           // CGSize - viewport dimensions
grid.cellSize       // CGSize - individual cell dimensions
grid.insets         // Insets - buffer zones
grid.moveSpeed      // CGFloat - speed multiplier (default: 1.0)
grid.isFilled       // Bool - whether grid is built
grid.isMoving       // Bool - whether grid is currently scrolling
grid.columns        // Int - number of columns
grid.rows           // Int - number of rows
```

### Grid Node

```swift
// The SKNode containing all grid cells
grid.gridNode

// Position sprites relative to grid
let sprite = SKSpriteNode()
sprite.position = cell.position
grid.gridNode.addChild(sprite)
```

## Data Structures

### Cell

```swift
struct Cell {
    let point: Point      // Grid coordinates (row, column)
    let position: CGPoint // Scene position (x, y)
}

// Access cell data
let row = cell.point.row
let column = cell.point.column
let sceneX = cell.position.x
let sceneY = cell.position.y
```

### Point

```swift
struct Point {
    var row: Int
    var column: Int
}

let point = Point(row: 5, column: 3)
let zero = Point.zero  // (0, 0)
```

## Performance Tips

1. **Use Insets Wisely**: Buffer zones prevent visible pop-in but use more memory
2. **Implement didAddCell/didRemoveCell**: Add/remove sprites only when needed
3. **Batch Operations**: Group multiple grid changes together
4. **Object Pooling**: Reuse sprites in didRemoveCell/didAddCell
5. **Limit Update Calls**: Only call `update()` when grid is moving

## Common Patterns

### Adding Sprites to Cells

```swift
class VisualGrid: SpriteGridKit {
    private var sprites: [Point: SKSpriteNode] = [:]
    
    override func didAddCell(_ cell: Cell) {
        let sprite = SKSpriteNode(color: .blue, size: cellSize)
        sprite.position = cell.position
        gridNode.addChild(sprite)
        sprites[cell.point] = sprite
    }
    
    override func didRemoveCell(_ cell: Cell) {
        sprites[cell.point]?.removeFromParent()
        sprites.removeValue(forKey: cell.point)
    }
}
```

### Responding to Grid Reset

```swift
class ResettableGrid: SpriteGridKit {
    override func willReset() {
        // Clean up before reset
        gridNode.removeAllChildren()
    }
    
    override func didReset() {
        // Rebuild visual elements
        setupGridVisuals()
    }
}
```

## Requirements

- iOS 12.0+ / macOS 10.14+
- Swift 5.0+
- SpriteKit

## License

MIT License

Copyright (c) 2024 Dmitriy Mitrofansky

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Dmitriy Mitrofansky

## Credits

Built with SpriteKit for high-performance 2D graphics.
