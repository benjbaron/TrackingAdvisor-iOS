//
//  OverlayView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/27/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

public class OverlayView {
    
    var overlayView: UIView? {
        didSet {
            if overlayView != nil {
                bgView?.addSubview(overlayView!)
            }
        }
    }
    
    private var effectView: UIView?
    private var bgView: UIView?
    
    class var shared: OverlayView {
        struct Static {
            static let instance: OverlayView = OverlayView()
        }
        return Static.instance
    }
    
    class func frame() -> CGRect {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window {
            return window.frame
        }
        return CGRect.zero
    }
    
    public func showOverlay(with view: UIView? = nil) {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window {
            
            bgView = UIView()
            guard let bgView = bgView else { return }
            
            bgView.frame = window.frame

            if !UIAccessibilityIsReduceTransparencyEnabled() {
                let blurEffect = UIBlurEffect(style: .regular)
                effectView = UIVisualEffectView(effect: blurEffect)
                effectView?.frame = bgView.frame
                effectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
            } else {
                effectView = UIView()
                effectView?.frame = bgView.frame
                effectView?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                effectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            
            bgView.addSubview(effectView!)
            effectView!.addTapGestureRecognizer { [weak self] in
                self?.effectView?.removeFromSuperview()
                self?.bgView?.removeFromSuperview()
            }
            
            window.addSubview(bgView)
            overlayView = view
        }
    }
    
    public func hideOverlayView() {
        effectView?.removeFromSuperview()
        bgView?.removeFromSuperview()
        overlayView?.removeFromSuperview()
    }
}
