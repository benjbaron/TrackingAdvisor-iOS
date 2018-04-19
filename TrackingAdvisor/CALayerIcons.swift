//
//  CALayerIcons.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/17/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class IconLayerView : UIView {
    var lineWidth: CGFloat = 2.0 { didSet {
        setNeedsDisplay()
    }}
    var unselectedColor: UIColor = .lightGray { didSet {
        setNeedsDisplay()
    }}
    var selectedColor: UIColor = .black { didSet {
        setNeedsDisplay()
    }}
    var isSelected: Bool = false { didSet {
        if isSelected {
            color = selectedColor
        } else {
            color = unselectedColor
        }
    }}
    internal var color: UIColor = .lightGray { didSet {
        setNeedsDisplay()
    }}

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CircleCheckView: IconLayerView {
    
    override func draw(_ rect: CGRect) {
        
        let diameter = min(bounds.width, bounds.height) - 2 * lineWidth
        let scale = diameter / 100.0
        let minX = bounds.minX + ((bounds.width - diameter) * 0.5).rounded(.down)
        let minY = bounds.minY + ((bounds.height - diameter) * 0.5).rounded(.down)
        
        let newRect = CGRect(
            x: minX,
            y: minY,
            width: diameter,
            height: diameter)
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: newRect)
        color.setStroke()
        ovalPath.lineWidth = lineWidth
        ovalPath.stroke()
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 40.08, y: 73.04))
        bezierPath.addLine(to: CGPoint(x: 18.95, y: 51.68))
        bezierPath.addCurve(to: CGPoint(x: 18.95, y: 47.04), controlPoint1: CGPoint(x: 17.68, y: 50.4), controlPoint2: CGPoint(x: 17.68, y: 48.32))
        bezierPath.addLine(to: CGPoint(x: 23.55, y: 42.39))
        bezierPath.addCurve(to: CGPoint(x: 28.14, y: 42.39), controlPoint1: CGPoint(x: 24.82, y: 41.11), controlPoint2: CGPoint(x: 26.88, y: 41.11))
        bezierPath.addLine(to: CGPoint(x: 42.38, y: 56.78))
        bezierPath.addLine(to: CGPoint(x: 72.86, y: 25.96))
        bezierPath.addCurve(to: CGPoint(x: 77.45, y: 25.96), controlPoint1: CGPoint(x: 74.12, y: 24.68), controlPoint2: CGPoint(x: 76.18, y: 24.68))
        bezierPath.addLine(to: CGPoint(x: 82.05, y: 30.61))
        bezierPath.addCurve(to: CGPoint(x: 82.05, y: 35.25), controlPoint1: CGPoint(x: 83.32, y: 31.89), controlPoint2: CGPoint(x: 83.32, y: 33.97))
        bezierPath.addLine(to: CGPoint(x: 44.67, y: 73.04))
        bezierPath.addCurve(to: CGPoint(x: 40.08, y: 73.04), controlPoint1: CGPoint(x: 43.4, y: 74.32), controlPoint2: CGPoint(x: 41.35, y: 74.32))
        bezierPath.addLine(to: CGPoint(x: 40.08, y: 73.04))
        bezierPath.close()
        
        bezierPath.apply(CGAffineTransform(translationX: minX / scale, y: minY / scale))
        bezierPath.apply(CGAffineTransform(scaleX: scale, y: scale))
        
        color.setFill()
        bezierPath.fill()
    }
}


class MehView: IconLayerView {
    
    override func draw(_ rect: CGRect) {
        
        let diameter = min(bounds.width, bounds.height) - 2 * lineWidth
        let scale = diameter / 100.0
        let minX = bounds.minX + ((bounds.width - diameter) * 0.5).rounded(.down)
        let minY = bounds.minY + ((bounds.height - diameter) * 0.5).rounded(.down)
        
        let newRect = CGRect(
            x: minX,
            y: minY,
            width: diameter,
            height: diameter)
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: newRect)
        color.setStroke()
        ovalPath.lineWidth = lineWidth
        ovalPath.stroke()
        
        /// Bezier path
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 66.19, y: 67.37))
        bezierPath.addLine(to: CGPoint(x: 33.63, y: 67.37))
        bezierPath.addCurve(to: CGPoint(x: 33.63, y: 59.45), controlPoint1: CGPoint(x: 28.39, y: 67.37), controlPoint2: CGPoint(x: 28.39, y: 59.45))
        bezierPath.addLine(to: CGPoint(x: 66.19, y: 59.45))
        bezierPath.addCurve(to: CGPoint(x: 66.19, y: 67.37), controlPoint1: CGPoint(x: 71.43, y: 59.45), controlPoint2: CGPoint(x: 71.43, y: 67.37))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 35.67, y: 36.34))
        bezierPath.addCurve(to: CGPoint(x: 41.51, y: 42.18), controlPoint1: CGPoint(x: 38.9, y: 36.34), controlPoint2: CGPoint(x: 41.51, y: 38.96))
        bezierPath.addCurve(to: CGPoint(x: 35.67, y: 48.03), controlPoint1: CGPoint(x: 41.51, y: 45.41), controlPoint2: CGPoint(x: 38.9, y: 48.03))
        bezierPath.addCurve(to: CGPoint(x: 29.82, y: 42.18), controlPoint1: CGPoint(x: 32.44, y: 48.03), controlPoint2: CGPoint(x: 29.82, y: 45.41))
        bezierPath.addCurve(to: CGPoint(x: 35.67, y: 36.34), controlPoint1: CGPoint(x: 29.82, y: 38.96), controlPoint2: CGPoint(x: 32.44, y: 36.34))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 64.15, y: 36.34))
        bezierPath.addCurve(to: CGPoint(x: 70, y: 42.18), controlPoint1: CGPoint(x: 67.38, y: 36.34), controlPoint2: CGPoint(x: 70, y: 38.96))
        bezierPath.addCurve(to: CGPoint(x: 64.15, y: 48.03), controlPoint1: CGPoint(x: 70, y: 45.41), controlPoint2: CGPoint(x: 67.38, y: 48.03))
        bezierPath.addCurve(to: CGPoint(x: 58.31, y: 42.18), controlPoint1: CGPoint(x: 60.93, y: 48.03), controlPoint2: CGPoint(x: 58.31, y: 45.41))
        bezierPath.addCurve(to: CGPoint(x: 64.15, y: 36.34), controlPoint1: CGPoint(x: 58.31, y: 38.96), controlPoint2: CGPoint(x: 60.93, y: 36.34))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 50, y: 17))
        bezierPath.addCurve(to: CGPoint(x: 17, y: 50), controlPoint1: CGPoint(x: 31.76, y: 17), controlPoint2: CGPoint(x: 17, y: 31.76))
        bezierPath.addCurve(to: CGPoint(x: 50, y: 83), controlPoint1: CGPoint(x: 17, y: 68.24), controlPoint2: CGPoint(x: 31.76, y: 83))
        bezierPath.addCurve(to: CGPoint(x: 83, y: 50), controlPoint1: CGPoint(x: 68.24, y: 83), controlPoint2: CGPoint(x: 83, y: 68.24))
        bezierPath.addCurve(to: CGPoint(x: 50, y: 17), controlPoint1: CGPoint(x: 83, y: 31.76), controlPoint2: CGPoint(x: 68.24, y: 17))
        bezierPath.close()
        
        bezierPath.apply(CGAffineTransform(translationX: minX / scale, y: minY / scale))
        bezierPath.apply(CGAffineTransform(scaleX: scale, y: scale))
        
        color.setFill()
        bezierPath.fill()
    }
}

class TimesView : IconLayerView {
    override func draw(_ rect: CGRect) {
        let diameter = min(bounds.width, bounds.height) - 2 * lineWidth
        let scale = diameter / 100.0
        let minX = bounds.minX + ((bounds.width - diameter) * 0.5).rounded(.down)
        let minY = bounds.minY + ((bounds.height - diameter) * 0.5).rounded(.down)
        
        let newRect = CGRect(
            x: minX,
            y: minY,
            width: diameter,
            height: diameter)
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: newRect)
        color.setStroke()
        ovalPath.lineWidth = lineWidth
        ovalPath.stroke()
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 72, y: 80.84))
        bezierPath.addLine(to: CGPoint(x: 80.84, y: 72))
        bezierPath.addCurve(to: CGPoint(x: 80.84, y: 66.43), controlPoint1: CGPoint(x: 82.39, y: 70.45), controlPoint2: CGPoint(x: 82.39, y: 67.98))
        bezierPath.addLine(to: CGPoint(x: 64.89, y: 50.48))
        bezierPath.addLine(to: CGPoint(x: 80.84, y: 34.53))
        bezierPath.addCurve(to: CGPoint(x: 80.84, y: 28.97), controlPoint1: CGPoint(x: 82.39, y: 32.99), controlPoint2: CGPoint(x: 82.39, y: 30.51))
        bezierPath.addLine(to: CGPoint(x: 72, y: 20.12))
        bezierPath.addCurve(to: CGPoint(x: 66.43, y: 20.12), controlPoint1: CGPoint(x: 70.45, y: 18.58), controlPoint2: CGPoint(x: 67.98, y: 18.58))
        bezierPath.addLine(to: CGPoint(x: 50.48, y: 36.07))
        bezierPath.addLine(to: CGPoint(x: 34.53, y: 20.12))
        bezierPath.addCurve(to: CGPoint(x: 28.97, y: 20.12), controlPoint1: CGPoint(x: 32.99, y: 18.58), controlPoint2: CGPoint(x: 30.51, y: 18.58))
        bezierPath.addLine(to: CGPoint(x: 20.12, y: 28.97))
        bezierPath.addCurve(to: CGPoint(x: 20.12, y: 34.53), controlPoint1: CGPoint(x: 18.58, y: 30.51), controlPoint2: CGPoint(x: 18.58, y: 32.99))
        bezierPath.addLine(to: CGPoint(x: 36.07, y: 50.48))
        bezierPath.addLine(to: CGPoint(x: 20.12, y: 66.43))
        bezierPath.addCurve(to: CGPoint(x: 20.12, y: 72), controlPoint1: CGPoint(x: 18.58, y: 67.98), controlPoint2: CGPoint(x: 18.58, y: 70.45))
        bezierPath.addLine(to: CGPoint(x: 28.97, y: 80.84))
        bezierPath.addCurve(to: CGPoint(x: 34.53, y: 80.84), controlPoint1: CGPoint(x: 30.51, y: 82.39), controlPoint2: CGPoint(x: 32.99, y: 82.39))
        bezierPath.addLine(to: CGPoint(x: 50.48, y: 64.89))
        bezierPath.addLine(to: CGPoint(x: 66.43, y: 80.84))
        bezierPath.addCurve(to: CGPoint(x: 72, y: 80.84), controlPoint1: CGPoint(x: 67.96, y: 82.37), controlPoint2: CGPoint(x: 70.45, y: 82.37))
        bezierPath.close()
        
        bezierPath.apply(CGAffineTransform(translationX: minX / scale, y: minY / scale))
        bezierPath.apply(CGAffineTransform(scaleX: scale, y: scale))
        
        color.setFill()
        bezierPath.fill()
    }
}

