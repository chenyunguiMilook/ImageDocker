//
//  ViewController+Main+PreviewArea.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/9/29.
//  Copyright © 2019 nonamecat. All rights reserved.
//


import Cocoa
import AVFoundation
import AVKit

extension ViewController {

    internal func configurePreview(){
        
        webLocation.setValue(false, forKey: "drawsBackground")
        webPossibleLocation.setValue(false, forKey: "drawsBackground")
        
        webLocation.load(URLRequest(url: URL(string: "about:blank")!))
        webPossibleLocation.load(URLRequest(url: URL(string: "about:blank")!))
        
        self.playerContainer.layer?.borderColor = NSColor.darkGray.cgColor
        
        // Do any additional setup after loading the view.
        stackedImageViewController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "imageView")) as! StackedImageViewController
        stackedVideoViewController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "videoView")) as! StackedVideoViewController
        
        stackedImageViewController.parentController = self
        stackedVideoViewController.parentController = self
        
        self.addChildViewController(stackedImageViewController)
        self.addChildViewController(stackedVideoViewController)
        
        stackedImageViewController.view.frame = self.playerContainer.bounds
        self.playerContainer.addSubview(stackedImageViewController.view)
        
        possibleLocationText.textColor = NSColor.white
        locationTextDelegate = LocationTextDelegate()
        locationTextDelegate?.textField = self.possibleLocationText
        
    }
    
    // shared among different open-channels
    internal func processImageUrls(urls:[URL]){
        
        if urls.count == 0 {return}
        loadImage(urls[0])
    }
    
    internal func previewImage(url:URL, isPhoto:Bool) {
        for sView in self.playerContainer.subviews {
            sView.removeFromSuperview()
        }
        
        if stackedVideoViewController != nil && stackedVideoViewController.videoDisplayer != nil && stackedVideoViewController.videoDisplayer.player != nil {
            stackedVideoViewController.videoDisplayer.player?.pause()
        }
        
        if isPhoto {
            
            // switch to image view
            stackedImageViewController.view.frame = self.playerContainer.bounds
            self.playerContainer.addSubview(stackedImageViewController.view)
            
            // show image
            stackedImageViewController.imageDisplayer.image = url.loadImage(maxDimension: 512)
            
            self.btnImageOptions.isEnabled = true
        } else {
            
            // switch to video view
            stackedVideoViewController.view.frame = self.playerContainer.bounds
            self.playerContainer.addSubview(stackedVideoViewController.view)
            
            // show video
            stackedVideoViewController.videoDisplayer.player = AVPlayer(url: url)
            stackedVideoViewController.videoDisplayer.player?.play()
            
            self.btnImageOptions.isEnabled = false
        }
    }
    
    internal func previewImage(image:ImageFile) {
        for sView in self.playerContainer.subviews {
            sView.removeFromSuperview()
        }
        
        if stackedVideoViewController != nil && stackedVideoViewController.videoDisplayer != nil && stackedVideoViewController.videoDisplayer.player != nil {
            stackedVideoViewController.videoDisplayer.player?.pause()
        }
        
        if img.isPhoto {
            
            // switch to image view
            stackedImageViewController.view.frame = self.playerContainer.bounds
            self.playerContainer.addSubview(stackedImageViewController.view)
            
            // show image
            stackedImageViewController.imageDisplayer.image = image.image
            
            self.btnImageOptions.isEnabled = true
        } else {
            
            // switch to video view
            stackedVideoViewController.view.frame = self.playerContainer.bounds
            self.playerContainer.addSubview(stackedVideoViewController.view)
            
            // show video
            stackedVideoViewController.videoDisplayer.player = AVPlayer(url: image.url)
            stackedVideoViewController.videoDisplayer.player?.play()
            
            self.btnImageOptions.isEnabled = false
        }
    }
    
    internal func loadImage(_ url:URL){
        
        // init meta data
        //self.metaInfo = [MetaInfo]()
        self.img = ImageFile(url: url, sharedDB:ModelStoreGRDB.sharedDBPool() )
        
        guard img.isPhoto || img.isVideo else {return}
        self.previewImage(image: img)
        
        //img.loadMetaInfoFromExif()
        self.loadImageExif()
        img.loadLocation()
        self.loadBaiduMap()
        self.loadImageDescription(img)
    }
    
    internal func loadImageExif(_ force:Bool = false) {
        img.loadMetaInfoFromDatabase()
        img.loadMetaInfoFromExif(force)
        img.metaInfoHolder.sort(by: MetaCategorySequence)
        self.metaInfoTableView.reloadData()
    }
    
    internal func loadImageDescription(_ img:ImageFile){
        if let image = self.img.imageData {
            var people = ""
            if let id = image.id {
                let faces = ModelStore.default.getFaceCrops(imageId: id)
                for face in faces {
                    if let peopleId = face.peopleId, peopleId != "" {
                        var name = FaceTask.default.people(id: peopleId)
                        if name == "" {
                            name = "(unknown)"
                        }
                        people += "\(name) "
                    }
                }
            }
            self.lblImageDescription.stringValue = """
            \(people) \(image.shortDescription ?? "")
            \(image.longDescription ?? "")
            """
        }
    }
    
    internal func loadImage(imageFile:ImageFile){
        self.img = imageFile
        self.previewImage(image: img)
        //self.img.transformDomainToMetaInfo()
        img.metaInfoHolder.sort(by: MetaCategorySequence)
        self.metaInfoTableView.reloadData()
        self.loadBaiduMap()
        self.loadImageDescription(img)
    }
    
    internal func loadBaiduMap() {
        webLocation.load(URLRequest(url: URL(string: "about:blank")!))
        if img.location.coordinateBD != nil && img.location.coordinateBD!.isNotZero {
            BaiduLocation.queryForMap(coordinateBD: img.location.coordinateBD!, view: webLocation, zoom: zoomSize)
        }else{
            print("img has no coord")
        }
    }
    
    internal func resizeMap(tick:Int) {
        if tick == previousTick {
            return
        }
        switch tick {
        case 1:
            zoomSize = 14
        case 2:
            zoomSize = 15
        case 3:
            zoomSize = 16
        case 4:
            zoomSize = 17
        default:
            zoomSize = 17
        }
        
        self.loadBaiduMap()
        previousTick = tick
    }
    
    internal func readImageLocationMeta(title:String) -> String{
        return self.img.metaInfoHolder.getMeta(category: "Location", subCategory: "Assign", title: title) ?? self.img.metaInfoHolder.getMeta(category: "Location", subCategory: "Baidu", title: title) ?? self.img.metaInfoHolder.getMeta(category: "Location", subCategory: "Google", title: title) ?? ""
    }
    
    internal func chooseMapProvider(_ i:Int){
        if i == 0 {
            self.coordinateAPI = .google
            locationTextDelegate?.coordinateAPI = .google
            self.btnChoiceMapService.setImage(tick, forSegment: 0)
            self.btnChoiceMapService.setImage(nil, forSegment: 1)
        }else{
            self.coordinateAPI = .baidu
            locationTextDelegate?.coordinateAPI = .baidu
            self.btnChoiceMapService.setImage(nil, forSegment: 0)
            self.btnChoiceMapService.setImage(tick, forSegment: 1)
        }
    }
    
    internal func searchAddress(_ address:String){
        if address == "" {return}
        if self.coordinateAPI == .baidu {
            BaiduLocation.queryForCoordinate(address: address, coordinateConsumer: self)
        }else if self.coordinateAPI == .google {
            GoogleLocation.queryForCoordinate(address: address, coordinateConsumer: self)
        }
    }
    
    internal func openLocationSelector(_ sender: NSButton){
        self.createPlacePopover()
        if self.possibleLocation != nil {
            self.placeViewController.setPossibleLocation(place: self.possibleLocation!)
        }
        
        let cellRect = sender.bounds
        self.placePopover?.show(relativeTo: cellRect, of: sender, preferredEdge: .maxY)
    }
    
    internal func copyLocationFromMap() {
        guard self.img != nil && self.img.location.coordinateBD != nil && self.img.location.coordinateBD!.isNotZero else {return}
        if self.possibleLocation == nil {
            self.possibleLocation = Location()
        }
        if img.location.coordinate != nil && img.location.coordinateBD != nil {
            self.possibleLocation?.setCoordinateWithoutConvert(coord: img.location.coordinate!, coordBD: img.location.coordinateBD!)
        }
        
        self.possibleLocation?.country = self.readImageLocationMeta(title: "Country")
        self.possibleLocation?.province = self.readImageLocationMeta(title: "Province")
        self.possibleLocation?.city = self.readImageLocationMeta(title: "City")
        self.possibleLocation?.district = self.readImageLocationMeta(title: "District")
        self.possibleLocation?.businessCircle = self.readImageLocationMeta(title: "BusinessCircle")
        self.possibleLocation?.street = self.readImageLocationMeta(title: "Street")
        self.possibleLocation?.address = self.readImageLocationMeta(title: "Address")
        self.possibleLocation?.addressDescription = self.readImageLocationMeta(title: "Description")
        
        //print("possible location address: \(possibleLocation?.address ?? "")")
        //print("possible location place: \(possibleLocation?.place ?? "")")
        
        
        self.addressSearcher.stringValue = ""
        self.comboPlaceList.stringValue = ""
        self.comboPlaceList.deselectItem(at: self.comboPlaceList.indexOfSelectedItem)
        
        BaiduLocation.queryForAddress(coordinateBD: img.location.coordinateBD!, locationConsumer: self, textConsumer: self.locationTextDelegate!)
        BaiduLocation.queryForMap(coordinateBD: img.location.coordinateBD!, view: webPossibleLocation, zoom: zoomSizeForPossibleAddress)
    }
    
    internal func replaceLocation() {
        guard self.possibleLocation != nil && self.selectionViewController.imagesLoader.getItems().count > 0 else {return}
        let accumulator:Accumulator = Accumulator(target: self.selectionViewController.imagesLoader.getItems().count, indicator: self.batchEditIndicator, suspended: false, lblMessage: nil)
        let location:Location = self.possibleLocation!
        for item in self.selectionViewController.imagesLoader.getItems() {
            let url:URL = item.url as URL
            let imageType = url.imageType()
            if imageType == .photo || imageType == .video {
                ExifTool.helper.patchGPSCoordinateForImage(latitude: location.latitude!, longitude: location.longitude!, url: url)
                item.assignLocation(location: location)
                
                
                let imageInSelection:ImageFile? = self.imagesLoader.getItem(path: url.path)
                if imageInSelection != nil {
                    imageInSelection!.assignLocation(location: location)
                }
                
                //print("place after assign location: \(item.place)")
                item.save()
            }
            let _ = accumulator.add()
        }
        self.selectionViewController.imagesLoader.reorganizeItems()
        self.selectionCollectionView.reloadData()
        self.imagesLoader.reorganizeItems(considerPlaces: true)
        self.collectionView.reloadData()
    }
}
