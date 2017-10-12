//
//  Bitmap.swift
//  Interpherometr
//
//  Created by Hena Sofronov on 5/15/16.
//  Copyright © 2016 Hena Sofronov. All rights reserved.
//

import UIKit

class Bitmap {
    private var data: UnsafeMutablePointer<UInt32>
    var width: Int
    var height: Int
    
    private let bytesPerPixel = 4
    private let bitsPerComponent = 8
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        self.data = UnsafeMutablePointer<UInt32>.alloc(width * height)
        let context = CGBitmapContextCreate(self.data, self.width, self.height, bitsPerComponent, self.bytesPerPixel * self.width, self.colorSpace, self.info.rawValue)
        CGContextDrawImage(context, CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.width, height: self.height)), nil)
    }
    
    init(image: CGImage) {
        self.width = CGImageGetWidth(image)
        self.height = CGImageGetHeight(image)
        
        self.data = UnsafeMutablePointer<UInt32>.alloc(width * height)
        let context = CGBitmapContextCreate(self.data, self.width, self.height, bitsPerComponent, self.bytesPerPixel * self.width, self.colorSpace, self.info.rawValue)
        CGContextDrawImage(context, CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.width, height: self.height)), image)
    }
    
    var image: CGImage {
        let context = CGBitmapContextCreate(self.data, self.width, self.height, self.bitsPerComponent, self.bytesPerPixel * self.width, self.colorSpace, self.info.rawValue)
        return CGBitmapContextCreateImage(context)!
    }

    private func bitmapOffsetFromPoint(point: CGPoint) -> Int {
        return Int(point.y) * self.width + Int(point.x)
    }
    
    func colorForPoint(point: CGPoint) -> UIColor{
        func colorFromNumber(colorNumber: UInt32) -> UIColor {
            let alpha = (colorNumber >> 24) & 0xFF
            let blue = (colorNumber >> 16) & 0xFF
            let green = (colorNumber >> 8) & 0xFF
            let red = (colorNumber) & 0xFF
            return UIColor(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: CGFloat(alpha)/255)
        }
        let selectedPoint = self.data[self.bitmapOffsetFromPoint(point)]
        return colorFromNumber(selectedPoint)
    }
    
    func setColorForPoint(point: CGPoint, color: UIColor) {
        func numberFromColor(color: UIColor) -> UInt32 {
            let red = UnsafeMutablePointer<CGFloat>.alloc(1)
            let green = UnsafeMutablePointer<CGFloat>.alloc(1)
            let blue = UnsafeMutablePointer<CGFloat>.alloc(1)
            let alpha = UnsafeMutablePointer<CGFloat>.alloc(1)
            color.getRed(red, green: green, blue: blue, alpha: alpha)
            let redInt = UInt32(red.memory * 255)
            let greenInt = UInt32(green.memory * 255)
            let blueInt = UInt32(blue.memory * 255)
            let alphaInt = UInt32(alpha.memory * 255)
            return UInt32((alphaInt << 24) + (blueInt << 16) + (greenInt << 8) + redInt)
        }
        self.data[self.bitmapOffsetFromPoint(point)] = numberFromColor(color)
    }
    
    func drawLineFromPoint(fromPoint: CGPoint, toPoint: CGPoint, color: UIColor) {
        let startPoint = toPoint.x > fromPoint.x ? fromPoint : toPoint
        let endPoint = toPoint.x > fromPoint.x ? toPoint : fromPoint
        let startX = Int(startPoint.x)
        let endX = Int(endPoint.x)
        guard endX != startX else {
            let startY = Int(min(startPoint.y, endPoint.y))
            let endY = Int(max(startPoint.y, endPoint.y))
            for y in startY...endY {
                self.setColorForPoint(CGPoint(x: startX, y: y), color: color)
            }
            return
        }
        for x in startX...endX {
            let k = Double(x - startX) / Double(endX - startX)
            let y = Int((1 - k) * Double(startPoint.y) + k * Double(endPoint.y))
            self.setColorForPoint(CGPoint(x: x, y: y), color: color)
        }
//        self.setColorForPoint(fromPoint, color: UIColor.redColor())
//        self.setColorForPoint(toPoint, color: UIColor.redColor())
    }
    
    func avgColorInAmbit(point: CGPoint, ambit: CGSize) -> (r: UInt8, g: UInt8, b: UInt8) {
        func colorComponents(color: UIColor) -> (r: UInt8, g: UInt8, b: UInt8) {
            let red = UnsafeMutablePointer<CGFloat>.alloc(1)
            let green = UnsafeMutablePointer<CGFloat>.alloc(1)
            let blue = UnsafeMutablePointer<CGFloat>.alloc(1)
            let alpha = UnsafeMutablePointer<CGFloat>.alloc(1)
            color.getRed(red, green: green, blue: blue, alpha: alpha)
            return (UInt8(red.memory * CGFloat(UInt8.max)),
                    UInt8(green.memory * CGFloat(UInt8.max)),
                    UInt8(blue.memory * CGFloat(UInt8.max)))
        }
        let startX = Int(point.x - ambit.width / 2)
        let endX = Int(point.x + ambit.width / 2)
        let startY = Int(point.y - ambit.height / 2)
        let endY = Int(point.y + ambit.height / 2)
        let pointsCount = ((endX - startX + 1) * (endY - startY + 1))
        var avgr: CGFloat = 0
        var avgg: CGFloat = 0
        var avgb: CGFloat = 0
        for x in startX...endX {
            for y in startY...endY {
                let (r, g, b) = colorComponents(self.colorForPoint(CGPoint(x: x, y: y)))
                avgr += CGFloat(r)/CGFloat(pointsCount)
                avgg += CGFloat(g)/CGFloat(pointsCount)
                avgb += CGFloat(b)/CGFloat(pointsCount)
            }
        }
        return (UInt8(avgr), UInt8(avgg), UInt8(avgb))
    }
    func avgBrightnessInAmbit(point: CGPoint, ambit: CGSize) -> CGFloat {
        func brightness(color: UIColor) -> CGFloat {
            let red = UnsafeMutablePointer<CGFloat>.alloc(1)
            let green = UnsafeMutablePointer<CGFloat>.alloc(1)
            let blue = UnsafeMutablePointer<CGFloat>.alloc(1)
            let alpha = UnsafeMutablePointer<CGFloat>.alloc(1)
            color.getRed(red, green: green, blue: blue, alpha: alpha)
            return (red.memory + green.memory + blue.memory) / 3
        }
        var avgBrightness: CGFloat = 0
        let startX = Int(point.x - ambit.width / 2)
        let endX = Int(point.x + ambit.width / 2)
        let startY = Int(point.y - ambit.height / 2)
        let endY = Int(point.y + ambit.height / 2)
        let pointsCount = ((endX - startX + 1) * (endY - startY + 1))
        for x in startX...endX {
            for y in startY...endY {
                avgBrightness += brightness(self.colorForPoint(CGPoint(x: x, y: y))) / CGFloat(pointsCount)
            }
        }
        return avgBrightness
    }
}
