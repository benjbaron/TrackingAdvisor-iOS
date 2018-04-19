//
//  OverlayView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/27/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit


protocol OverlayViewDelegate {
    func overlayViewDismissed()
}

public class OverlayView {
    var delegate:OverlayViewDelegate?
    
    var overlayView: UIView? {
        didSet {
            if overlayView != nil {
                bgView?.addSubview(overlayView!)
            }
        }
    }
    
    private var effectView: UIView?
    private var bgView: UIView?
    private var window: UIWindow?
    private var timer: Timer?
    
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
            
            self.window = window
            
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
                self?.hideOverlayView()
            }
            
            self.window?.addSubview(bgView)
            overlayView = view
        }
    }
    
    public func autoRemove(with delay: TimeInterval, callback: (()->())? = nil) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hideOverlayView()
            callback?()
        }
    }
    
    public func hideOverlayView() {
        DispatchQueue.main.async() { [weak self] in
            self?.overlayView?.removeFromSuperview()
            self?.effectView?.removeFromSuperview()
            self?.bgView?.removeFromSuperview()
            self?.delegate?.overlayViewDismissed()
        }
    }
}
