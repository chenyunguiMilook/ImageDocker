//
//  ViewController+TreeArea+Filter.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/9/29.
//  Copyright © 2019 nonamecat. All rights reserved.
//

import Cocoa

extension ViewController {
    
    internal func createFilterPopover(){
        var myPopover = self.filterPopover
        if(myPopover == nil){
            myPopover = NSPopover()
            
            let frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 300))
            self.filterViewController = FilterViewController(onApply: { (imageSources, cameraModels) in
                self.filterImageSource = imageSources
                self.filterCameraModel = cameraModels
                self.refreshTree()
            })
            self.filterViewController.view.frame = frame
            //self.filterViewController.refreshDelegate = self
            
            myPopover!.contentViewController = self.filterViewController
            myPopover!.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)!
            //myPopover!.animates = true
            myPopover!.delegate = self
            myPopover!.behavior = NSPopover.Behavior.transient
        }
        self.filterPopover = myPopover
    }
}
