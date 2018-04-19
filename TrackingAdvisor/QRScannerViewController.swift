//
//  QRScannerViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/12/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

@available(iOS 10.2, *)
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var timer: Timer?
    var qrCodeDetected: Bool = false { didSet {
        if qrCodeDetected {
            qrCodeFrameView?.alpha = 1
        } else {
            qrCodeFrameView?.alpha = 0
        }
    }}
    var qrCodeFrameView: UIView?
    
    var requestSent = false { didSet {
        if requestSent {
            if timer != nil && timer!.isValid { return }
            
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.requestSent = false
                self?.messageLabel.text = "Looking for QR code..."
            }
        }
    }}
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        messageLabel.text = "Looking for QR code..."
        requestSent = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppDelegate.isIPhone5() {
            self.instructionsLabel.font = UIFont.systemFont(ofSize: 14.0)
        } else {
            self.instructionsLabel.font = UIFont.systemFont(ofSize: 14.0)
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .notDetermined:
            // request user authorisation
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("granted: \(granted)")
                if !granted {
                    self?.setupAlternativeScreen()
                }
            }
        case .denied, .restricted:
            print("not possible to access the camera")
            // show a user id alias instead
            setupAlternativeScreen()
            return
            
        default:
            print("access granted")
        }
        
        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back).devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = containerView.layer.bounds
        
        containerView.layer.addSublayer(videoPreviewLayer!)
        
        
        var blur: UIView!
        blur = UIVisualEffectView (effect: UIBlurEffect(style: .light))
        
        blur.frame = containerView.layer.bounds
        blur.isUserInteractionEnabled = false
        
        let qrCodeRect = CGRect(origin: CGPoint(x: UIScreen.main.bounds.midX - 125,
                                                y: UIScreen.main.bounds.midY - 250),
                                size: CGSize(width: 250, height: 250))
        
        let path = UIBezierPath (
            roundedRect: blur.frame,
            cornerRadius: 0)

        let circle = UIBezierPath (
            roundedRect: qrCodeRect,
            cornerRadius: 10)

        path.append(circle)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = kCAFillRuleEvenOdd

        let borderLayer = CAShapeLayer()
        borderLayer.path = circle.cgPath
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 5
        
        blur.layer.addSublayer(borderLayer)
        blur.layer.mask = maskLayer
        
        containerView.addSubview(blur)
        containerView.bringSubview(toFront: blur)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView(frame: blur.frame)
        
        if let qrCodeFrameView = qrCodeFrameView {
            let qrCodeBorderLayer = CAShapeLayer()
            qrCodeBorderLayer.path = circle.cgPath
            qrCodeBorderLayer.strokeColor = UIColor.green.cgColor
            qrCodeBorderLayer.fillColor = UIColor.clear.cgColor
            qrCodeBorderLayer.lineWidth = 8
            qrCodeFrameView.layer.addSublayer(qrCodeBorderLayer)
            qrCodeFrameView.alpha = 0
            
            containerView.addSubview(qrCodeFrameView)
            containerView.bringSubview(toFront: qrCodeFrameView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupAlternativeScreen() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false

        title = "Enter code"
        instructionsLabel.text = "Go to http://trackingadvisor.geog.ucl.ac.uk and enter the following code."
        messageLabel.alpha = 0
        
        containerView.addSubview(label)
        containerView.addVisualConstraint("H:|-[v0]-|", views: ["v0": label])
        containerView.addVisualConstraint("V:|-[v0]-|", views: ["v0": label])
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
        spinner.center = CGPoint(x: containerView.bounds.size.width / 2, y: containerView.bounds.size.height / 2)
        
        containerView.addSubview(spinner)
        spinner.startAnimating()
        
        sendAuthenticationRequestToServer(with: "TrackingAdvisorLogin", with: "TEXT") { res in
            print("recieved from server: \(res)")
            label.text = res["code"]
            spinner.stopAnimating()
        }
    }
    

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeDetected = false
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            
            if metadataObj.stringValue != nil {
                qrCodeDetected = true
                if let qrCodeText = metadataObj.stringValue {
                    messageLabel.text = "Authenticating..."
                    sendAuthenticationRequestToServer(with: qrCodeText, with: "QR") { [weak self] res in
                        
                        guard let strongSelf = self else { return }
                        
                        if !strongSelf.requestSent {
                            strongSelf.captureSession.stopRunning()
                            strongSelf.messageLabel.text = "Authenticated, thank you"
                            strongSelf.requestSent = true
                            
                            let overlayFrame = OverlayView.frame()
                            if let overlayView = self?.createFullScreenView(frame: overlayFrame) {
                                overlayView.addTapGestureRecognizer { [weak self] in
                                    OverlayView.shared.hideOverlayView()
                                    self?.goBack()
                                }
                                OverlayView.shared.showOverlay(with: overlayView)
                                OverlayView.shared.autoRemove(with: 3) { [weak self] in
                                    self?.goBack()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createFullScreenView(frame: CGRect) -> UIView {
        let view = UIView(frame: frame)
        
        let label = UILabel()
        label.text = "You are authenticated"
        label.font = UIFont.systemFont(ofSize: 30.0, weight: .bold)
        label.textColor = Constants.colors.primaryDark
        label.textAlignment = .center
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(named: "check")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Constants.colors.primaryLight
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(imageView)
        
        view.addVisualConstraint("H:|-20-[label]-20-|", views: ["label": label])
        view.addVisualConstraint("V:[image]-20-[label]", views: ["image": imageView, "label": label])
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        return view
    }
    
    func goBack() {
        guard let controllers = navigationController?.viewControllers else { return }
        let count = controllers.count
        if count >= 2 {
            // get the previous place detail controller
            let vc = controllers[controllers.count - 2]
            navigationController?.popToViewController(vc, animated: true)
        }
    }
    
    func sendAuthenticationRequestToServer(with text: String, with type: String, callback: (([String:String])->Void)? = nil) {
        if text.hasPrefix("TrackingAdvisorLogin") {
            // send the request to the server
            
            if requestSent { return }
            
            DispatchQueue.global(qos: .background).async {
                let userid = Settings.getUserId() ?? ""
                let parameters: Parameters = [
                    "userid": userid,
                    "text": text,
                    "type": type,
                    "date": Date()
                ]
                
                Alamofire.request(Constants.urls.authClientURL, method: .get, parameters: parameters).responseJSON { response in
                    
                    LogService.shared.log(LogService.types.serverResponse,
                                          args: [LogService.args.responseMethod: "get",
                                                 LogService.args.responseUrl: Constants.urls.authClientURL,
                                                 LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                    
                    if response.result.isSuccess {
                        guard let data = response.data else { return }
                        do {
                            let decoder = JSONDecoder()
                            let res = try decoder.decode([String:String].self, from: data)
                            callback?(res)
                        } catch {
                            print("Error serializing the json", error)
                        }
                    } else {
                        print("Error in response \(response.result)")
                    }
                }
            }
        }
    }

}
