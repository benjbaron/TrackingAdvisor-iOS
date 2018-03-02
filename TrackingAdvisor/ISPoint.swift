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
    open var descriptionSupp: UIView?
    open var pointColor:UIColor
    open var lineColor:UIColor
    open var touchUpInside:Optional<(_ point:ISPoint) -> Void>
    open var feedbackTouchUpInside:Optional<(_ point:ISPoint) -> Void>
    open var addPlaceTouchUpInside:Optional<(_ pt1:ISPoint?, _ pt2:ISPoint?) -> Void>
    open var fill:Bool = true
    open var icon:UIImage
    open var iconBg: UIColor
    open var showFeedback: Bool = true
    var visit: Visit?
    
    public init(title:String, description:String?, descriptionSupp:UIView?, pointColor:UIColor, lineColor:UIColor, touchUpInside:Optional<(_ point:ISPoint) -> Void>, feedbackTouchUpInside:Optional<(_ point:ISPoint) -> Void>, addPlaceTouchUpInside:Optional<(_ pt1:ISPoint?, _ pt2:ISPoint?) -> Void>,  icon:UIImage, iconBg:UIColor, fill:Bool = true, showFeedback:Bool = true) {
        self.title = title
        self.description = description
        self.descriptionSupp = descriptionSupp
        self.pointColor = pointColor
        self.lineColor = lineColor
        self.touchUpInside = touchUpInside
        self.feedbackTouchUpInside = feedbackTouchUpInside
        self.addPlaceTouchUpInside = addPlaceTouchUpInside
        self.fill = fill
        self.icon = icon
        self.iconBg = iconBg
        self.showFeedback = showFeedback
    }
    
    public convenience init(title:String, description:String?, descriptionSupp:UIView?, touchUpInside:Optional<(_ point:ISPoint) -> Void>, feedbackTouchUpInside:Optional<(_ point:ISPoint) -> Void>, addPlaceTouchUpInside:Optional<(_ pt1:ISPoint?, _ pt2:ISPoint?) -> Void>) {
        
        self.init(title: title, description: description, descriptionSupp: descriptionSupp, pointColor: Constants.colors.primaryLight, lineColor: Constants.colors.primaryDark, touchUpInside: touchUpInside, feedbackTouchUpInside:feedbackTouchUpInside, addPlaceTouchUpInside:addPlaceTouchUpInside, icon: UIImage(named: "location")!, iconBg: Constants.colors.primaryLight, fill: true)
    }
    
    public convenience init(title:String, touchUpInside:Optional<(_ point:ISPoint) -> Void>, feedbackTouchUpInside:Optional<(_ point:ISPoint) -> Void>, addPlaceTouchUpInside:Optional<(_ pt1:ISPoint?, _ pt2:ISPoint?) -> Void>) {
        self.init(title: title, description: nil, descriptionSupp: nil, touchUpInside: touchUpInside, feedbackTouchUpInside: feedbackTouchUpInside, addPlaceTouchUpInside:addPlaceTouchUpInside)
    }
    
    public convenience init(title:String) {
        self.init(title: title, touchUpInside: nil, feedbackTouchUpInside: nil, addPlaceTouchUpInside: nil)
    }
}
