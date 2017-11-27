//
//  ISTimeline.swift
//  ISTimeline
//
//  Created by Max Holzleitner on 07.05.16.
//  Copyright © 2016 instant:solutions. All rights reserved.
//

import UIKit

protocol Moveable {
    func hide()
    func show()
    func move(to: CGPoint, with delay: CFTimeInterval)
    func moveDown(by value: CGFloat, with delay:CFTimeInterval)
}

class MoveableLayer : Moveable {
    var layer: CALayer?
    var position = -1
    var maxPosition = -1
    
    init(layer:CALayer? = nil, position:Int = -1, maxPosition: Int = -1) {
        self.layer = layer
        self.position = position
        self.maxPosition = maxPosition
    }
    
    func hide() {
        guard let layer = layer else { return }
        layer.opacity = 0
    }
    
    func show() {
        guard let layer = layer else { return }
        layer.opacity = 1
    }
    
    func move(to: CGPoint, with delay: CFTimeInterval) {
        guard let layer = layer else { return }
        if position > 0 {
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = layer.position
            animation.toValue = to
            animation.duration = delay
            layer.position = to
            layer.add(animation, forKey: nil)
        }
    }
    
    func moveDown(by value: CGFloat, with delay: CFTimeInterval) {
        guard let layer = layer else { return }
        var position = CGPoint()
        position.x = layer.position.x
        position.y = layer.position.y + value
        move(to: position, with: delay)
    }
}

class MovableLineLayer: MoveableLayer {
    var line: CAShapeLayer? { didSet {
            self.layer = line
        }
    }
    var topCap: CAShapeLayer?
    var bottomCap: CAShapeLayer?
    var intermediateOffset: CGFloat = 0.0
    var lineOffset: CGFloat = 0.0
    
    init(line:CAShapeLayer? = nil, position:Int = -1, maxPosition: Int = -1, intermediateOffset: CGFloat = 0.0) {
        self.line = line
        self.intermediateOffset = intermediateOffset
        super.init(layer: line, position: position, maxPosition: maxPosition)
    }
    
    override func moveDown(by value: CGFloat, with delay: CFTimeInterval) {
        guard let line = line else { return }
        var position = CGPoint()
        position.x = line.position.x
        position.y = line.position.y + value
        
        if self.position == self.maxPosition {
            position.y += value / CGFloat(self.position)
            line.strokeStart = value < 0 ? lineOffset : 0.0
            if let topCap = topCap {
                topCap.position.y += value < 0 ? intermediateOffset : -1*intermediateOffset
            }
        }
        
        print("MovableLineLayer -- moveDown \(position)")
        move(to: position, with: delay)
    }
}

class MoveableLabel : Moveable {
    let label:UILabel?
    var position = -1
    var maxPosition = -1
    
    init(label:UILabel? = nil, position:Int = -1, maxPosition: Int = -1) {
        self.label = label
        self.position = position
        self.maxPosition = maxPosition
    }
   
    func hide() {
        guard let label = label else { return }
        label.alpha = 0
    }
    
    func show() {
        guard let label = label else { return }
        label.alpha = 1
    }
    
    func move(to: CGPoint, with delay: CFTimeInterval) {
        guard let label = label else { return }
        if self.position > 0 {
            UIView.animate(withDuration: delay) {
                label.center = to
            }
        }
    }
    
    func moveDown(by value: CGFloat, with delay:CFTimeInterval) {
        guard let label = label else { return }
        var position = CGPoint()
        position.x = label.center.x
        position.y = label.center.y + value
        move(to: position, with: delay)
    }
}


open class ISTimeline: UIScrollView {
    
    fileprivate static let gap:CGFloat = 15.0
    
    open var pointDiameter:CGFloat = 12.0 {
        didSet {
            if (pointDiameter < 0.0) {
                pointDiameter = 0.0
            } else if (pointDiameter > 100.0) {
                pointDiameter = 100.0
            }
        }
    }
    
    open var lineWidth:CGFloat = 16.0 {
        didSet {
            if (lineWidth < 0.0) {
                lineWidth = 0.0
            } else if(lineWidth > 20.0) {
                lineWidth = 20.0
            }
        }
    }
    
    open var bubbleRadius:CGFloat = 2.0 {
        didSet {
            if (bubbleRadius < 0.0) {
                bubbleRadius = 0.0
            } else if (bubbleRadius > 6.0) {
                bubbleRadius = 6.0
            }
        }
    }
    
    open var iconDiameter: CGFloat = 30.0 {
        didSet {
            if iconDiameter < 0.0 { iconDiameter = 0.0 }
            else if iconDiameter > 100.0 { iconDiameter = 100.0 }
        }
    }
    
    var layers:[Int:[Moveable]] = [:]
    var addButtons:[Moveable] = []
    
    open var points:[ISPoint] = [] {
        didSet {
            self.layer.sublayers?.forEach({ (layer:CALayer) in
                if layer.isKind(of: CAShapeLayer.self) {
                    layer.removeFromSuperlayer()
                }
            })
            self.subviews.forEach { (view:UIView) in
                view.removeFromSuperview()
            }
            
            self.contentSize = CGSize.zero
            
            sections.removeAll()
            buildSections()
            
            layer.setNeedsDisplay()
            layer.displayIfNeeded()
        }
    }
    
    open var bubbleArrows:Bool = false
    open var timelineTitle:String! { didSet {
            timelineTitleLabel.text = timelineTitle
        }
    }
    
    fileprivate let timelineTitleOffset:CGFloat = 90.0
    fileprivate var timelineTitleLabel: UILabel!
    fileprivate var timelineEditButton: UIButton!
    fileprivate let screenSize:CGRect = UIScreen.main.bounds
    fileprivate var isEditing = false { didSet {
            if isEditing {
                timelineEditButton.setTitle("Done", for: .normal)
                timelineEditButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            } else {
                timelineEditButton.setTitle("Edit", for: .normal)
                timelineEditButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)

            }
        }
    }
    
    fileprivate var isAnimating = false
    
    fileprivate var sections:[(point:CGPoint, bubbleRect:CGRect, descriptionRect:CGRect?, titleLabel:UILabel, descriptionLabel:UILabel?, pointColor:CGColor, lineColor:CGColor, fill:Bool, icon:UIImage, iconBg:CGColor, iconCenter:CGPoint)] = []
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        self.clipsToBounds = true
        self.showsVerticalScrollIndicator = false
        buildTimelineTitleLabel()
    }
    
    @objc fileprivate func editTimeline() {
        if isAnimating { return }
        
        isAnimating = true
        if isEditing {
            let duration = 0.5
            
            for i in 0..<self.addButtons.count {
                let layer = self.addButtons[i]
                layer.hide()
            }

            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            CATransaction.setCompletionBlock { [weak self] in
                print("end animation")
                
                self?.isAnimating = false
                self?.isEditing = false
            }
            
            for i in 1..<self.layers.count {
                for j in 0..<self.layers[i]!.count {
                    let layer = self.layers[i]![j]
                    layer.moveDown(by: -1.0 * CGFloat(i) * 50, with: duration)
                }
            }
            
            CATransaction.commit()
            
            self.contentSize = CGSize(width: self.contentSize.width, height: self.contentSize.height - CGFloat((self.layers.count-1))*50)
            
        } else {
            let duration = 0.5
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            CATransaction.setCompletionBlock { [weak self] in
                print("end animation")
                guard let strongSelf = self else { return  }
                for i in 0..<strongSelf.addButtons.count {
                    let layer = strongSelf.addButtons[i]
                    layer.show()
                }
                
                strongSelf.isAnimating = false
                strongSelf.isEditing = true
            }
            
            for i in 1..<self.layers.count {
                for j in 0..<self.layers[i]!.count {
                    print("call moveDown \(i), \(j)")
                    let layer = self.layers[i]![j]
                    layer.moveDown(by: CGFloat(i) * 50, with: duration)
                }
            }
            
            CATransaction.commit()
            
            self.contentSize = CGSize(width: self.contentSize.width, height: self.contentSize.height + CGFloat((self.layers.count-1))*50)
        }
    }
    
    
    override open func draw(_ rect: CGRect) {
        let ctx:CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        // Place the timeline title label
        timelineTitleLabel.frame = CGRect(x: 1.0, y: 29.0, width: rect.width-1.0, height: 40)
        self.addSubview(timelineTitleLabel)
        
        // Place the timeline edit button
        timelineEditButton = UIButton(type: UIButtonType.system)
        timelineEditButton.frame.size = CGSize(width: 50, height: 25)
        timelineEditButton.contentHorizontalAlignment = .right
        timelineEditButton.frame.origin = CGPoint(x: screenSize.width - (timelineEditButton.frame.width + 40), y: -10)
        timelineEditButton.setTitle("Edit", for: .normal)
        timelineEditButton.addTarget(self, action: #selector(ISTimeline.editTimeline), for: .touchUpInside)
        self.addSubview(timelineEditButton)
        
        for i in 0 ..< sections.count {
            layers[i] = []
            if (i < sections.count - 1) {
                var start = sections[i].point
                start.x += pointDiameter / 2
                start.y += pointDiameter / 2
                
                var end = sections[i + 1].point
                end.x = start.x
                end.y = sections[sections.count-1].point.y + pointDiameter / 2
                
                let cap = (i == sections.count - 2) ? 2 : 1
                let offset: CGFloat = (i == sections.count - 2) ? 50.0 : 0.0

                let moveableLineLayer = MovableLineLayer(line: nil, position: i, maxPosition: sections.count - 2, intermediateOffset: offset)
                let lineLayer = drawLine(start, end: end, color: sections[i].lineColor,
                                         cap: cap, offset: offset, layer: moveableLineLayer)
                
                self.layer.addSublayer(lineLayer)
                layers[i]!.append(moveableLineLayer)
                
                // Add button (with opacity = 0)
                let addIconPosition = CGPoint(x: sections[i].point.x - lineWidth/2,
                                              y: sections[i+1].point.y + CGFloat(i) * 50 - 10)
                let addIconLayer = drawIcon(addIconPosition, fill: Constants.primaryLight.cgColor, image: UIImage(named: "add")!)
                addIconLayer.opacity = 0
                addButtons.append(MoveableLayer(layer: addIconLayer, position: i, maxPosition: sections.count - 2))
                self.layer.addSublayer(addIconLayer)
                
                // Add text (button)
                let addTextRect = CGRect(
                    x: addIconPosition.x + 35,
                    y: addIconPosition.y + 2,
                    width: 100,
                    height: 25)
                let addTextLabel = buildAddLabel(text: "Add an event")
                
                let addTextLayer = drawDescription(addTextRect, textColor: Constants.black, descriptionLabel: addTextLabel!)
                addTextLayer.alpha = 0
                addButtons.append(MoveableLabel(label: addTextLayer, position: i, maxPosition: sections.count - 2))
                self.addSubview(addTextLayer)
            }
            
            let iconLayer = drawIcon(sections[i].iconCenter, fill: sections[i].iconBg, image: sections[i].icon)
            self.layer.addSublayer(iconLayer)
            layers[i]!.append(MoveableLayer(layer: iconLayer, position: i, maxPosition: sections.count - 1))
            
            let pointLayer = drawPoint(sections[i].point, color: sections[i].pointColor, fill: sections[i].fill)
            self.layer.addSublayer(pointLayer)
            layers[i]!.append(MoveableLayer(layer: pointLayer, position: i, maxPosition: sections.count - 1))
            
            let bubbleLayer = drawBubble(sections[i].bubbleRect, backgroundColor: Constants.primaryLight, textColor: Constants.titleColor, titleLabel: sections[i].titleLabel)
            self.addSubview(bubbleLayer)
            layers[i]!.append(MoveableLabel(label: bubbleLayer, position: i, maxPosition: sections.count - 1))
            
            let descriptionLabel = sections[i].descriptionLabel
            if (descriptionLabel != nil) {
                let descriptionLayer = drawDescription(sections[i].descriptionRect!, textColor: Constants.descriptionColor, descriptionLabel: sections[i].descriptionLabel!)
                self.addSubview(descriptionLayer)
                layers[i]!.append(MoveableLabel(label: descriptionLayer, position: i, maxPosition: sections.count - 1))
            }
        }
        
        ctx.restoreGState()
    }
    
    fileprivate func buildSections() {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        var y:CGFloat = self.bounds.origin.y + self.contentInset.top + timelineTitleOffset
        for i in 0 ..< points.count {
            let titleLabel = buildTitleLabel(i)
            let descriptionLabel = buildDescriptionLabel(i)
            
            let titleHeight = titleLabel.intrinsicContentSize.height
            var height:CGFloat = titleHeight
            if descriptionLabel != nil {
                height += descriptionLabel!.intrinsicContentSize.height
            }
            
            let iconCenter = CGPoint(
                x: self.bounds.origin.x + self.contentInset.left,
                y: y + (titleHeight + ISTimeline.gap) / 2 + (pointDiameter - iconDiameter) / 2)
            
            let point = CGPoint(
                x: self.bounds.origin.x + self.contentInset.left + iconDiameter + lineWidth,
                y: y + (titleHeight + ISTimeline.gap) / 2)
            
            let maxTitleWidth = calcWidth()
            var titleWidth = titleLabel.intrinsicContentSize.width + 20
            if (titleWidth > maxTitleWidth) {
                titleWidth = maxTitleWidth
            }
            
            let offset:CGFloat = bubbleArrows ? 13 : 5
            let bubbleRect = CGRect(
                x: point.x + pointDiameter + lineWidth / 2 + offset,
                y: y + pointDiameter / 2,
                width: titleWidth,
                height: titleHeight + ISTimeline.gap / 2)
            
            var descriptionRect:CGRect?
            if descriptionLabel != nil {
                descriptionRect = CGRect(
                    x: bubbleRect.origin.x,
                    y: bubbleRect.origin.y + bubbleRect.height,
                    width: calcWidth(),
                    height: descriptionLabel!.intrinsicContentSize.height)
            }
            
            sections.append((point, bubbleRect, descriptionRect, titleLabel, descriptionLabel, points[i].pointColor.cgColor, points[i].lineColor.cgColor, points[i].fill, points[i].icon, points[i].iconBg.cgColor, iconCenter))
            
            y += height
            y += ISTimeline.gap * 2.2 // section gap
        }
        y += pointDiameter / 2
        self.contentSize = CGSize(width: self.bounds.width - (self.contentInset.left + self.contentInset.right), height: y)
    }
    
    fileprivate func buildTimelineTitleLabel() {
        timelineTitleLabel = UILabel()
        timelineTitleLabel.text = timelineTitle
        if #available(iOS 11.0, *) {
            timelineTitleLabel.font =  UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize, weight: .bold)
            
        } else {
            timelineTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
            
        }
        timelineTitleLabel.preferredMaxLayoutWidth = calcWidth()
    }
    
    fileprivate func buildTitleLabel(_ index:Int) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.text = points[index].title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.preferredMaxLayoutWidth = calcWidth()
        return titleLabel
    }
    
    fileprivate func buildDescriptionLabel(_ index:Int) -> UILabel? {
        let text = points[index].description
        return buildDescriptionLabel(text: text)
    }
    
    fileprivate func buildDescriptionLabel(text: String?) -> UILabel? {
        if (text != nil) {
            let descriptionLabel = UILabel()
            descriptionLabel.text = text
            descriptionLabel.font = UIFont.systemFont(ofSize: 14.0)
            descriptionLabel.lineBreakMode = .byWordWrapping
            descriptionLabel.numberOfLines = 0
            descriptionLabel.preferredMaxLayoutWidth = calcWidth()
            return descriptionLabel
        }
        return nil
    }
    
    fileprivate func buildAddLabel(text: String?) -> UILabel? {
        if (text != nil) {
            let addLabel = UILabel()
            addLabel.text = text
            addLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            addLabel.lineBreakMode = .byWordWrapping
            addLabel.numberOfLines = 0
            addLabel.preferredMaxLayoutWidth = calcWidth()
            return addLabel
        }
        return nil
    }
    
    fileprivate func calcWidth() -> CGFloat {
        return self.bounds.width - (self.contentInset.left + self.contentInset.right) - pointDiameter - lineWidth - ISTimeline.gap * 1.5
    }
    
    fileprivate func drawLine(_ start:CGPoint, end:CGPoint, color:CGColor, cap:Int, offset:CGFloat = 0.0, layer:MovableLineLayer) -> CAShapeLayer {
        var startPoint = start
        startPoint.y -= offset
        
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: end)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = lineWidth
        
        if cap > 0 {
            let topRoundedCap = UIBezierPath(ovalIn: CGRect(x: start.x - lineWidth/2.0, y: start.y - lineWidth/2.0, width: lineWidth, height: lineWidth))
            let topRoundedCapLayer = CAShapeLayer()
            topRoundedCapLayer.path = topRoundedCap.cgPath
            topRoundedCapLayer.fillColor = color
            topRoundedCapLayer.lineWidth = 0
            shapeLayer.addSublayer(topRoundedCapLayer)
            layer.topCap = topRoundedCapLayer
            
            if cap == 2 {
                let lineOffset = 1.0 - ((end.y - start.y) / (end.y - startPoint.y))
                shapeLayer.strokeStart = lineOffset
                let bottomRoundedCap = UIBezierPath(ovalIn: CGRect(x: end.x - lineWidth/2.0, y: end.y - lineWidth/2.0, width: lineWidth, height: lineWidth))
                let bottomRoundedCapLayer = CAShapeLayer()
                bottomRoundedCapLayer.path = bottomRoundedCap.cgPath
                bottomRoundedCapLayer.fillColor = Constants.black.cgColor
                bottomRoundedCapLayer.lineWidth = 0
                shapeLayer.addSublayer(bottomRoundedCapLayer)
                layer.bottomCap = bottomRoundedCapLayer
                layer.lineOffset = lineOffset
            }
        }
        
        layer.line = shapeLayer
        return shapeLayer
    }
    
    fileprivate func drawPoint(_ point:CGPoint, color:CGColor, fill:Bool) -> CALayer {
        let path = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: pointDiameter, height: pointDiameter))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color
        shapeLayer.fillColor = fill ? color : UIColor.clear.cgColor
        shapeLayer.lineWidth = 0
        
        return shapeLayer
    }
    
    fileprivate func drawIcon(_ point: CGPoint, fill: CGColor, image: UIImage) -> CALayer {
        let path = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: iconDiameter, height: iconDiameter))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = fill
        shapeLayer.lineWidth = 0
        
        let imageLayer = CALayer()
        imageLayer.backgroundColor = UIColor.clear.cgColor
        imageLayer.bounds = CGRect(x: point.x, y: point.y , width: 0.8*iconDiameter, height: 0.8*iconDiameter)
        imageLayer.position = CGPoint(x: point.x + iconDiameter/2 ,y: point.y + iconDiameter/2)
        imageLayer.contents = image.cgImage
        
        shapeLayer.addSublayer(imageLayer)
        return shapeLayer
    }
    
    fileprivate func drawBubble(_ rect:CGRect, backgroundColor:UIColor, textColor:UIColor, titleLabel:UILabel) -> UILabel {
        
        let titleRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width - 15, height: rect.size.height - 1)
        titleLabel.textColor = Constants.black
        titleLabel.frame = titleRect
        
        return titleLabel
    }
    
    fileprivate func drawDescription(_ rect:CGRect, textColor:UIColor, descriptionLabel:UILabel) -> UILabel {
        descriptionLabel.textColor = textColor
        descriptionLabel.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width - 10, height: rect.height)
        
        return descriptionLabel
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        for (index, section) in sections.enumerated() {
            if (section.bubbleRect.contains(point)) {
                points[index].touchUpInside?(points[index])
                break
            }
        }
    }
}
