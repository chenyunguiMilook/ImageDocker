//
//  ViewController+Main+CollectionArea.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/9/29.
//  Copyright © 2019 nonamecat. All rights reserved.
//

import Cocoa

extension ViewController {
    
    internal func configureCollectionView() {
        collectionProgressIndicator.isHidden = true
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 180.0, height: 150.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
        view.wantsLayer = true
        collectionView.backgroundColors = [NSColor.darkGray]
        collectionView.layer?.backgroundColor = NSColor.darkGray.cgColor
        collectionView.layer?.borderColor = NSColor.darkGray.cgColor
        
        imagesLoader.singleSectionMode = false
        imagesLoader.showHidden = false
        imagesLoader.clean()
        collectionView.reloadData()
    }
    
    internal func hideToolbarOfCollectionView() {
        self.btnRefreshCollectionView.isHidden = true
        self.btnCombineDuplicates.isHidden = true
        self.chbSelectAll.isHidden = true
        self.chbShowHidden.isHidden = true
    }
    
    internal func showToolbarOfCollectionView() {
        self.btnRefreshCollectionView.isHidden = false
        self.btnCombineDuplicates.isHidden = false
        self.chbSelectAll.isHidden = false
        self.chbShowHidden.isHidden = false
    }
    
    
    
    internal func disableCollectionViewControls() {
        self.btnRefreshCollectionView.isEnabled = false
        self.chbSelectAll.isEnabled = false
        self.chbShowHidden.isEnabled = false
        self.btnCombineDuplicates.isEnabled = false
    }
    
    
    internal func enableCollectionViewControls() {
        self.btnRefreshCollectionView.isEnabled = true
        self.chbSelectAll.isEnabled = true
        self.chbShowHidden.isEnabled = true
        self.btnCombineDuplicates.isEnabled = true
    }
    
    internal func switchShowHideState() {
        self.imagesLoader.showHidden = self.chbShowHidden.state == .on
        
        TaskManager.loadingImagesCollection = true
        
        self.imagesLoader.clean()
        collectionView.reloadData()
        
        DispatchQueue.global().async {
            if self.imagesLoader.isLoading(){
                self.imagesLoader.cancel(onCancelled: {
                    self.imagesLoader.reload()
                    self.refreshCollectionView()
                    TaskManager.loadingImagesCollection = false
                })
            }else{
                self.imagesLoader.reload()
                self.refreshCollectionView()
                TaskManager.loadingImagesCollection = false
            }
            
        }
    }
    
    internal func refreshCollection(_ sender: NSButton) {
        if self.imagesLoader.lastRequest.loadSource == .repository && self.imagesLoader.lastRequest.pageNumber > 0 && self.imagesLoader.lastRequest.pageSize > 0 {
            self.reloadImageFolder(sender: sender)
        }else if self.imagesLoader.lastRequest.loadSource == .moment && self.imagesLoader.lastRequest.pageNumber > 0 && self.imagesLoader.lastRequest.pageSize > 0 {
            if self.imagesLoader.lastRequest.place == nil {
                self.reloadMomentCollection(sender: sender)
            }else{
                self.reloadPlaceCollection(sender: sender)
            }
        }else if self.imagesLoader.lastRequest.loadSource == .event && self.imagesLoader.lastRequest.pageNumber > 0 && self.imagesLoader.lastRequest.pageSize > 0 {
            self.reloadEventCollection(sender: sender)
        }else{
            self.refreshCollection()
        }
    }
    
    internal func selectImageFile(_ imageFile:ImageFile){
        self.selectedImageFile = imageFile.fileName
        //print("selected image file: \(filename)")
        //let url:URL = (self.selectedImageFolder?.url.appendingPathComponent(imageFile.fileName, isDirectory: false))!
        DispatchQueue.main.async {
            self.loadImage(imageFile: imageFile)
        }
    }
    
    internal func refreshCollection(){
        DispatchQueue.global().async {
            if self.imagesLoader.isLoading() {
                self.imagesLoader.cancel(onCancelled: {
                    self.imagesLoader.reload()
                    self.refreshCollectionView()
                })
            }else {
                self.imagesLoader.reload()
                self.refreshCollectionView()
            }
            
        }
    }
}
