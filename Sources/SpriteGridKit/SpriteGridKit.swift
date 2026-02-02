//
//  SpriteGridKit.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 28.09.24.
//

import SpriteKit

open class SpriteGridKit: SKNode {
    open func willBuild() {}
    open func didBuild() {}
    open func willDestroy() {}
    open func didDestroy() {}
    open func didStop() {}
    open func willReset() {}
    open func didReset() {}

    open func didAddCell(_ cell: Cell) {}
    open func didAddRow(_ row: Int, cellsOfRow: [Cell]) {}
    open func didRemoveCell(_ cell: Cell) {}
    open func didRemoveRow(_ row: Int, cellsOfRow: [Cell]) {}
    
    public var cellSize: CGSize {
        didSet {
            resetIfChanges(old: oldValue, current: cellSize)
        }
    }
    
    public var insets: Insets {
        didSet {
            resetIfChanges(old: oldValue, current: insets)
        }
    }
    
    public var size: CGSize {
        didSet {
            resetIfChanges(old: oldValue, current: size)
        }
    }

    private var _moveSpeed = CGFloat(1) // Скорость движения
    
    public var moveSpeed: CGFloat {
        get {
            _moveSpeed
        }

        set {
            _moveSpeed = max(.zero, newValue)
        }
    }
    
    public let gridNode = SKNode()
    
    private var lastUpdateTime = TimeInterval.zero
    private var totalMovedDistance = CGFloat.zero
    private var lastProcessedSteps = Int.zero
    
    /// Если вызвано мгновенное смещение
    private var isInstantMove = false

    /// Скорость (px/s)
    private(set) var velocity = CGFloat.zero

    /// Сколько ещё нужно проехать (px). Если nil → бесконечное движение.
    private var remainingDistance: CGFloat?
    
    /// Направление движения: 1 (вниз), -1 (вверх)
    private var direction = CGFloat(1)
    
    private var grid = [Int: [Cell]]()
    private(set) var isFilled = false
    private var appendToTop: () -> Void = {}
    private var topCounter = Int.zero
    private var appendToBottom: () -> Void = {}
    private var bottomCounter = Int.zero
    private(set) var yStep = CGFloat.zero
    private var cachedColumnsCount: Int?

    public init(size: CGSize, cellSize: CGSize, insets: Insets = Insets(-1)) {
        self.cellSize = cellSize
        self.size = size
        self.insets = insets
        super.init()
        addChild(gridNode)
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func build() {
        guard !isFilled else { return }
        reset()
    }
    
    public func destroy() {
        guard isFilled else { return }
        willDestroy()
        stopAndReset()
        isFilled = false
        didDestroy()
    }
    
    open func cellPosition(for row: Int, column: Int) -> CGPoint {
        CGPoint(x: CGFloat(column) * cellSize.width, y: CGFloat(row) * cellSize.height)
    }
    
    private var maxColumnsCount: Int {
        var columns = Int.zero
        var xPosPrev = CGFloat.zero
        var xPos = CGFloat.zero
        
        while xPos < size.width {
            let step = cellPosition(for: .zero, column: columns)
            xPos += step.x - xPosPrev
            xPosPrev = xPos
            columns += 1
        }

        return max(.zero, columns - 1)
    }
    
    open func columnsCount(at row: Int) -> Int {
        cachedColumnsCount ?? maxColumnsCount
    }

    public func reset() {
        stopAndReset()

        if isFilled {
            willReset()
        } else {
            willBuild()
        }
    
        var rowsCount = Int.zero
        var yPosPrev = CGFloat.zero
        var yPos = CGFloat.zero
        
        while yPos < size.height {
            let step = cellPosition(for: rowsCount, column: .zero)
            yPos += step.y - yPosPrev
            yPosPrev = yPos
            rowsCount += 1
        }
        
        rowsCount -= 1
        
        yStep = yPos / CGFloat(rowsCount)
        cachedColumnsCount = maxColumnsCount
        topCounter = insets.bottom
    
        appendToTop = {
            var row = [Cell]()
            let toColumn = self.columnsCount(at: self.topCounter) + (self.insets.right * -1)
            
            for column in self.insets.left...toColumn {
                let position = self.cellPosition(for: self.topCounter, column: column)
                let cell = Cell(row: self.topCounter, column: column, position: position)
                row.append(cell)
                self.didAddCell(cell)
            }

            self.grid[self.topCounter] = row
            self.didAddRow(self.topCounter, cellsOfRow: row)
            self.topCounter += 1
        }
        
        bottomCounter = topCounter - 1
        
        appendToBottom = {
            var row = [Cell]()
            let toColumn = self.columnsCount(at: self.bottomCounter) + (self.insets.right * -1)
            
            for column in self.insets.left...toColumn {
                let position = self.cellPosition(for: self.bottomCounter, column: column)
                let cell = Cell(row: self.bottomCounter, column: column, position: position)
                row.append(cell)
                self.didAddCell(cell)
            }

            self.grid[self.bottomCounter] = row
            self.didAddRow(self.bottomCounter, cellsOfRow: row)
            self.bottomCounter -= 1
        }

        for _ in insets.bottom...rowsCount + (insets.top * -1) {
            appendToTop()
        }
        
        if isFilled {
            didReset()
        } else {
            isFilled = true
            didBuild()
        }
    }
    
    private func stopAndBuild() {
        stop()
        build()
    }
    
    public func update(_ time: TimeInterval) {
        guard isFilled, isMoving else { return }

        if lastUpdateTime == .zero {
            lastUpdateTime = time
            return
        }

        let deltaTime = time - lastUpdateTime
        lastUpdateTime = time

        // абсолютный шаг с учетом self._moveSpeed
        let step = velocity * CGFloat(deltaTime) * _moveSpeed

        // шаг с направлением
        var moveDistance = step * direction

        if let remainingDistance {
            if step >= remainingDistance {
                moveDistance = direction * remainingDistance
                self.remainingDistance = nil
                velocity = .zero
                
                if !isInstantMove {
                    didStop()
                }
            } else {
                self.remainingDistance = remainingDistance - step
            }
        }
        
        totalMovedDistance += moveDistance
        gridNode.position.y = -totalMovedDistance
        
        // Вычисляем сколько полных шагов пройдено (с учётом знака)
        let currentSteps = Int(floor(totalMovedDistance / yStep))
        
        // Сколько новых шагов нужно обработать
        let stepsDiff = currentSteps - lastProcessedSteps
        
        if stepsDiff > .zero {
            // Движение вниз
            for _ in .zero..<stepsDiff {
                shiftBottom()
            }
        } else if stepsDiff < .zero {
            // Движение вверх
            for _ in .zero..<abs(stepsDiff) {
                shiftTop()
            }
        }
        
        lastProcessedSteps = currentSteps
    }
    
    public func moveByStep(duration: TimeInterval, count: CGFloat? = nil) {
        stopAndBuild()
        guard duration > .zero else { return }

        let stepDistance = yStep

        if let count {
            let distance = stepDistance * count // движение на заданное количество шагов (может быть отрицательным)
            let totalDuration = duration * TimeInterval(abs(count)) // длительность всегда положительная
            let absDistance = abs(distance)
            direction = distance >= .zero ? 1 : -1
            velocity = absDistance / CGFloat(totalDuration)
            remainingDistance = absDistance
        } else {
            // бесконечное движение (вниз по умолчанию)
            direction = 1
            velocity = stepDistance / CGFloat(duration)
            remainingDistance = nil
        }
    }
    
    public func move(distance: CGFloat, duration: TimeInterval = .zero) {
        stopAndBuild()
        let absDistance = abs(distance)
        direction = distance >= .zero ? 1 : -1
        remainingDistance = absDistance
        
        if duration > .zero {
            velocity = absDistance / CGFloat(duration)
        } else {
            moveInstantly(distance: absDistance)
        }
    }
    
    private func moveInstantly(distance: CGFloat) {
        stopAndBuild()

        guard isFilled else { return }
        
        // Блокируем вызов didStop()
        isInstantMove = true
        remainingDistance = distance
        // любое ненулевое, чтобы update() сработал
        velocity = distance

        // Моделируем обновления, пока remainingDistance не станет nil (движение закончено)
        
        while isMoving {
            // симулируем один «большой кадр», например, 100 секунд
            update(lastUpdateTime + 100)
        }

        // гарантируем, что всё сброшено
        stop()
        
        // Снова разрешаем didStop()
        isInstantMove = false
    }

    public var isMoving: Bool {
        velocity > .zero
    }
    
    public var columns: Int {
        Int(ceil(size.width / cellSize.width))
    }
    
    public var rows: Int {
        Int(ceil(size.height / cellSize.height))
    }
    
    private func resetIfChanges<T: Equatable>(old: T, current: T) {
        guard old != current else { return }

        if isFilled {
            reset()
        }
    }
    
    func stop() {
        if isMoving, !isInstantMove {
            didStop() // триггер остановки
        }
        
        // Сбрасываем текущую скорость и оставшуюся дистанцию, накопленное движение
        velocity = .zero
        remainingDistance = nil
        direction = 1

        // Сбрасываем время для корректного расчёта deltaTime
        lastUpdateTime = .zero
    }

    // MARK: - Cell methods

    public func cell(at row: Int, column: Int) -> Cell? {
        // если такого ряда нет
        guard let rowCells = grid[row] else { return nil }

        let colIndex = column - insets.left
        
        // проверяем границы
        guard colIndex >= .zero, colIndex < rowCells.count else { return nil }

        return rowCells[colIndex]
    }
    
    public final func cell(at point: Point) -> Cell? {
        cell(at: point.row, column: point.column)
    }
    
    public final func cell(at point: Point, for direction: Direction) -> Cell? {
        switch direction {
            case .west: return westCell(at: point)
            case .east: return eastCell(at: point)
            case .north: return northCell(at: point)
            case .south: return southCell(at: point)
            case .northWest: return northWestCell(at: point)
            case .northEast: return northEastCell(at: point)
            case .southWest: return southWestCell(at: point)
            case .southEast: return southEastCell(at: point)
        }
    }
    
    open func westCell(at point: Point) -> Cell? {
        cell(at: point.row, column: point.column - 1)
    }
    
    open func eastCell(at point: Point) -> Cell? {
        cell(at: point.row, column: point.column + 1)
    }
    
    open func southCell(at point: Point) -> Cell? {
        cell(at: point.row - 1, column: point.column)
    }
    
    open func northCell(at point: Point) -> Cell? {
        cell(at: point.row + 1, column: point.column)
    }
    
    open func northWestCell(at point: Point) -> Cell? {
        cell(at: point.row + 1, column: point.column - 1)
    }
    
    open func northEastCell(at point: Point) -> Cell? {
        cell(at: point.row + 1, column: point.column + 1)
    }
    
    open func southWestCell(at point: Point) -> Cell? {
        cell(at: point.row - 1, column: point.column - 1)
    }
    
    open func southEastCell(at point: Point) -> Cell? {
        cell(at: point.row - 1, column: point.column + 1)
    }

    // MARK: - Private methods
    
    private func shiftTop() {
        let cellsOfRow: [Cell]
        topCounter -= 1
        
        if let row = grid[topCounter] {
            cellsOfRow = row
            row.forEach(didRemoveCell)
            grid.removeValue(forKey: topCounter)
        } else {
            cellsOfRow = []
        }
        
        appendToBottom()
        didRemoveRow(topCounter, cellsOfRow: cellsOfRow)
    }

    private func shiftBottom() {
        let cellsOfRow: [Cell]
        bottomCounter += 1
        
        if let row = grid[bottomCounter] {
            cellsOfRow = row
            row.forEach(didRemoveCell)
            grid.removeValue(forKey: bottomCounter)
        } else {
            cellsOfRow = []
        }

        appendToTop()
        didRemoveRow(bottomCounter, cellsOfRow: cellsOfRow)
    }
    
    private func stopAndReset() {
        stop()
        gridNode.position = .zero
        bottomCounter = .zero
        topCounter = .zero
        totalMovedDistance = .zero
        lastProcessedSteps = .zero
        appendToBottom = {}
        appendToTop = {}
        yStep = .zero
        cachedColumnsCount = nil
        
        for (row, cellsOfRow) in grid {
            cellsOfRow.forEach(didRemoveCell)
            didRemoveRow(row, cellsOfRow: cellsOfRow)
        }
        
        grid.removeAll()
    }
}

public extension SpriteGridKit {
    struct Insets: Equatable {
        public let top: Int
        public let right: Int
        public let bottom: Int
        public let left: Int
        
        public init(top: Int, right: Int, bottom: Int, left: Int) {
            self.top = top
            self.right = right
            self.bottom = bottom
            self.left = left
        }
        
        public init(x: Int, y: Int) {
            self.init(top: y, right: x, bottom: y, left: x)
        }
        
        public init(_ value: Int) {
            self.init(top: value, right: value, bottom: value, left: value)
        }
    }

    enum Direction: String, CaseIterable {
        case west
        case east
        case north
        case south
        case northWest
        case northEast
        case southWest
        case southEast
        
        public static var westSide: [Self] { [.west, .northWest, .southWest] }
        public static var northSide: [Self] { [.north, .northWest, .northEast] }
        public static var eastSide: [Self] { [.east, .northEast, .southEast] }
        public static var southSide: [Self] { [.south, .southEast, .southWest] }
    }
    
    struct Point: CustomStringConvertible, Hashable {
        public var row: Int
        public var column: Int
        
        public static var zero: Point {
            .init(row: .zero, column: .zero)
        }
        
        public init(row: Int, column: Int) {
            self.row = row
            self.column = column
        }
        
        public var description: String {
            "Point: (\(row), \(column))"
        }
    }
    
    struct Cell: CustomStringConvertible, Hashable {
        public let point: Point
        public let position: CGPoint
        
        public init(row: Int, column: Int, position: CGPoint) {
            self.position = position
            self.point = Point(row: row, column: column)
        }
        
        public init(point: Point, position: CGPoint) {
            self.position = position
            self.point = point
        }
        
        public var description: String {
            "Cell (point: \(point), position: \(position))"
        }
        
        public static var zero: Cell {
            .init(point: .zero, position: .zero)
        }
    }
}
