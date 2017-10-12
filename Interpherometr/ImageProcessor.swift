//
//  ImageProcessor.swift
//  Interpherometr
//
//  Created by Hena Sofronov on 5/14/16.
//  Copyright © 2016 Hena Sofronov. All rights reserved.
//

import UIKit
import CoreGraphics
import DominantColor

class ImageProcessor {
    private var bitmap: Bitmap?
    private var bitmapWithLines: Bitmap?
    private let defaultAmbit = CGSize(width: 20, height: 20)
    private let defaultStep: Double = 5
    private let defaultDirectionsCount: UInt = 25
    
    private var path: [[CGPoint]] = []
    private var angle: CGFloat {
        guard let firstPath = self.path.first else {
            return 0
        }
        guard let firstPoint = firstPath.first else {
            return 0
        }
        let lastPoint = firstPath[10]
        let dy = firstPoint.y - lastPoint.y
        let dx = firstPoint.x - lastPoint.x
        return atan(dy/dx)
    }
    var pathImage: UIImage? {
        guard let bitmap = self.bitmap else {
            return nil
        }
        func rotatePoint(point point: CGPoint, around: CGPoint, angle: CGFloat) -> CGPoint {
            let normalized = CGPoint(x: point.x - around.x, y: point.y - around.y)
            let result = CGPoint(x: normalized.x * cos(angle) - normalized.y * sin(angle) + around.x,
                                 y: normalized.x * sin(angle) + normalized.y * cos(angle) + around.y)
            return result
        }
        func averagePoint(points: [CGPoint]) -> CGPoint {
            var avgX: CGFloat = 0
            var avgY: CGFloat = 0
            for point in points {
                avgX += point.x
                avgY += point.y
            }
            return CGPoint(x: avgX / CGFloat(points.count), y: avgY / CGFloat(points.count))
        }
        
        func pointsDforIndex(index: Int) -> [CGPoint] {
            var pointsD: [CGPoint] = []
            for indexPath in 0...self.path.count - 1 {
                pointsD += [self.path[indexPath][index]]
            }
            return pointsD
        }
        
        let pathBitmap = Bitmap(width: bitmap.width, height: bitmap.height)
        
        let firstPoint = averagePoint(pointsDforIndex(0))
        var pathPoints: [CGPoint] = []
        var lastPoint = firstPoint
        pathPoints += [lastPoint]
        for index in 1...self.path.first!.count - 1 {
            let nextPoint = rotatePoint(point: averagePoint(pointsDforIndex(index)), around: firstPoint, angle: -self.angle)
            pathPoints += [nextPoint]
            pathBitmap.drawLineFromPoint(lastPoint,
                                         toPoint: nextPoint,
                                         color: UIColor.redColor())
            lastPoint = nextPoint
        }
        for point in pathPoints {
            print("\(point.x) \(pathPoints.first!.y - point.y)")
        }
        return UIImage(CGImage: pathBitmap.image)
    }
    
    var image: UIImage? {
        set {
            guard let inputCGImage = newValue?.CGImage else {
                return
            }
            self.bitmap = Bitmap(image: inputCGImage)
        }
        get {
            guard let bitmap = self.bitmap else {
                return nil
            }
            return UIImage(CGImage: bitmap.image)
        }
    }
    
    var imageWithLines: UIImage? {
        guard let bitmapWithLines = self.bitmapWithLines else {
            return nil
        }
        return UIImage(CGImage: bitmapWithLines.image)
    }
        
    func startFindingFromPoint(point: CGPoint) {
        guard let bitmap = self.bitmap else {
            return
        }
        self.bitmapWithLines = nil
        let bitmapWithLines = Bitmap(image: bitmap.image)
        var points: [CGPoint] = []
        
        let ambit = CGSize(width: 2, height: 2)
        let startX = Int(point.x - ambit.width / 2)
        let endX = Int(point.x + ambit.width / 2)
        let startY = Int(point.y - ambit.height / 2)
        let endY = Int(point.y + ambit.height / 2)
        for x in startX...endX {
            for y in startY...endY {
                points += [CGPoint(x: x, y: y)]
            }
        }
        
        self.path = []
        for point in points {
            var currentPoint = point
            var previousPoint = point
            var newPath = [point]
            for _ in 0...200 {
                print("x: \(currentPoint.x) y: \(currentPoint.y)")
                guard let nextPoint = self.goNextPoint(currentPoint) else {
                    return
                }
                newPath += [nextPoint]
                previousPoint = currentPoint
                currentPoint = nextPoint
                bitmapWithLines.drawLineFromPoint(previousPoint, toPoint: currentPoint, color: UIColor.redColor())
            }
            self.path += [newPath]
        }
        self.bitmapWithLines = bitmapWithLines
    }
    
    
    
    private func goNextPoint(point: CGPoint) -> CGPoint? {
        guard let bitmap = self.bitmap else {
            return nil
        }
        func nextLeftPointsForPoint(point: CGPoint, count: UInt) -> [CGPoint] {
            var nextPoints = [CGPoint]()
            let startAngle = M_PI / 2
            let endAngle = 3 * M_PI / 2
            for pointNumber in 1...count {
                let k = Double(pointNumber) / Double(count)
                let angle = startAngle * (1 - k) + endAngle * k
                nextPoints += [CGPoint(x: Double(point.x) + cos(angle) * self.defaultStep, y: Double(point.y) + sin(angle) * self.defaultStep * 5)]
            }
            return nextPoints
        }
        enum Criteria {
            case Brightness
            case Diff
        }
        func criteriaForPoint(point: CGPoint, criteria: Criteria) -> CGFloat {
            if (criteria == .Brightness) {
                return bitmap.avgBrightnessInAmbit(point, ambit: self.defaultAmbit)
            }
            if (criteria == .Diff) {
                func toRGBVector(r r: UInt8, g: UInt8, b: UInt8) -> INVector3 {
                    return INVector3(
                        x: Float(r) / Float(UInt8.max),
                        y: Float(g) / Float(UInt8.max),
                        z: Float(b) / Float(UInt8.max)
                    )
                }
                let color = bitmap.avgColorInAmbit(point, ambit: self.defaultAmbit)
                let comparsion = CIE2000SquaredColorDifference()
                let blackInLab = IN_RGBToLAB(toRGBVector(r: 0, g: 0, b: 0))
                return CGFloat(comparsion(lab1: blackInLab,
                                          lab2: IN_RGBToLAB(toRGBVector(r: color.r, g: color.g, b: color.b))))
            }
            return 0
        }
        
        let criteria = Criteria.Diff
        let nextPoints = nextLeftPointsForPoint(point, count: self.defaultDirectionsCount)
        var bestPoint = nextPoints[0]
        var bestCriteria = criteriaForPoint(bestPoint, criteria: criteria)
        for nextPoint in nextPoints {
            let currentCriteria = criteriaForPoint(nextPoint, criteria: criteria)
            if currentCriteria < bestCriteria {
                bestPoint = nextPoint
                bestCriteria = currentCriteria
            }
        }
        return bestPoint
    }
}
