//
//  ISPoint.swift
//  ISTimeline
//
//  Created by Max Holzleitner on 13.05.16.
//  Copyright © 2016 instant:solutions. All rights reserved.
//

import UIKit

open class ISPoint {
    
    open var title:String
    open var description:String?
    open var pointColor:UIColor
    open var lineColor:UIColor
    open var touchUpInside:Optional<(_ point:ISPoint) -> Void>
    open var fill:Bool = true
    open var icon:UIImage
    open var iconBg: UIColor
    
    public init(title:String, description:String, pointColor:UIColor, lineColor:UIColor, touchUpInside:Optional<(_ point:ISPoint) -> Void>, icon:UIImage, iconBg:UIColor, fill:Bool = true) {
        self.title = title
        self.description = description
        self.pointColor = pointColor
        self.lineColor = lineColor
        self.touchUpInside = touchUpInside
        self.fill = fill
        self.icon = icon
        self.iconBg = iconBg
    }
    
    public convenience init(title:String, description:String, touchUpInside:Optional<(_ point:ISPoint) -> Void>) {
        
        self.init(title: title, description: description, pointColor: Constants.primaryLight, lineColor: Constants.primaryDark, touchUpInside: touchUpInside, icon: UIImage(named: "location")!, iconBg: Constants.primaryLight, fill: true)
    }
    
    public convenience init(title:String, touchUpInside:Optional<(_ point:ISPoint) -> Void>) {
        self.init(title: title, description: "", touchUpInside: touchUpInside)
    }
    
    public convenience init(title:String) {
        self.init(title: title, touchUpInside: nil)
    }
}
