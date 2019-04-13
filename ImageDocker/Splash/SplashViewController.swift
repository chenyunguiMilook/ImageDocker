//
//  SplashViewController.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/4/13.
//  Copyright © 2019 nonamecat. All rights reserved.
//

import Cocoa

class SplashViewController: NSViewController {
    
    // MARK: PROPERTIES
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var btnRetry: NSButton!
    @IBOutlet weak var btnQuit: NSButton!
    @IBOutlet weak var btnAbort: NSButton!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    
    required init?(coder: NSCoder) {
        self.onStartup = {}
        self.onCompleted = {}
        super.init(coder: coder)
    }
    
    fileprivate var onStartup: (() -> Void)
    fileprivate var onCompleted: (() -> Void)
    
    init(onStartup: @escaping (() -> Void), onCompleted: @escaping (() -> Void)) {
        self.onStartup = onStartup
        self.onCompleted = onCompleted
        super.init(nibName: NSNib.Name(rawValue: "SplashViewController"), bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        self.btnAbort.isHidden = true
        self.btnRetry.isHidden = true
        self.btnQuit.isHidden = true
        
        self.lblProgress.stringValue = "0 %"
        self.progressIndicator.minValue = 0
        self.progressIndicator.maxValue = 100
        self.progressIndicator.doubleValue = 0
        
        self.onStartup()
    }
    
    func progressWillEnd(at:Int) {
        self.progressEnd = at
        DispatchQueue.main.async {
            self.progressIndicator.maxValue = Double(at)
            self.progressIndicator.isHidden = false
        }
    }
    
    fileprivate var progressEnd = 0
    var progressStage = 0
    var progressStep = 0
    
    func message(_ value:String, progress:Int){
        DispatchQueue.main.async {
            self.lblMessage.stringValue = value
            
            if self.progressStage != progress {
                // progress indicator + 1
                self.progressStep += 1
                
                let ratio = self.progressStep * 100 / self.progressEnd
                self.lblProgress.stringValue = "\(ratio) %"
                self.progressIndicator.increment(by: 1)
                
                self.progressStage = progress
                
                if self.progressStep >= self.progressEnd {
                    self.onCompleted()
                }
            }
        }
    }
    
    var cancelWaiting = false
    var decideQuit = false
    
    func showRetry(_ countdown:Int){
        DispatchQueue.main.async {
            self.btnRetry.title = "Retry (\(countdown))"
            self.btnRetry.isHidden = false
            self.btnQuit.isHidden = true
            self.btnAbort.isHidden = false
        }
    }
    
    func hideRetry() {
        DispatchQueue.main.async {
            self.btnRetry.isHidden = true
            self.btnQuit.isHidden = true
            self.btnAbort.isHidden = true
        }
    }
    
    func showQuit() {
        DispatchQueue.main.async {
            self.btnQuit.isHidden = false
            self.btnRetry.isHidden = true
            self.btnAbort.isHidden = true
        }
    }
    
    @IBAction func onQuitClicked(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func onRetryClicked(_ sender: NSButton) {
        self.cancelWaiting = true
    }
    
    @IBAction func onAbortClicked(_ sender: NSButton) {
        self.cancelWaiting = true
        self.decideQuit = true
        DispatchQueue.main.async {
            self.lblMessage.stringValue = "Quiting ..."
            self.btnRetry.isHidden = true
            self.btnQuit.isHidden = true
            self.btnAbort.isHidden = true
            self.lblProgress.isHidden = true
            self.progressIndicator.isHidden = true
        }
    }
    
}
