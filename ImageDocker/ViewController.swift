//
//  ViewController.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2018/4/22.
//  Copyright © 2018年 nonamecat. All rights reserved.
//

import Cocoa
import CryptoSwift
import CoreLocation
import SwiftyJSON
import WebKit
import AVFoundation
import AVKit
import PXSourceList

class ViewController: NSViewController {
    
    
    // MARK: Image preview
    var img:ImageData!
    @IBOutlet weak var playerContainer: NSView!
    var stackedImageViewController : StackedImageViewController!
    var stackedVideoViewController : StackedVideoViewController!
    
    // MARK: MetaInfo table view
    var metaInfo:[MetaInfo] = [MetaInfo]()
    var lastSelectedMetaInfoRow: Int?
    @IBOutlet weak var metaInfoTableView: NSTableView!
    
    // MARK: Image Map
    var zoomSize:Int = 16
    var previousTick:Int = 3
    @IBOutlet weak var webLocation: WKWebView!
    @IBOutlet weak var mapZoomSlider: NSSlider!
    
    // MARK: Editor - Map
    var zoomSizeForPossibleAddress:Int = 16
    var previousTickForPossibleAddress:Int = 3
    @IBOutlet weak var addressSearcher: NSSearchField!

    @IBOutlet weak var webPossibleLocation: WKWebView!
    var possibleLocation:Location?
    
    @IBOutlet weak var possibleLocationText: NSTextField!
    var locationTextDelegate:LocationTextDelegate?
    
    // MARK: PXSourceList
    var modelObjects:NSMutableArray?
    var sourceListItems:NSMutableArray?
    var sourceListIdentifiers:[String : PXSourceListItem] = [String : PXSourceListItem] ()
    
    var librarySectionOfTree : PXSourceListItem?

    var selectedImageFolder:ImageFolder?
    var selectedImageFile:String = ""
    
    @IBOutlet weak var sourceList: PXSourceList!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: Collection View for browsing
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var collectionProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var considerPlacesCheckBox: NSButton!
    @IBOutlet weak var indicatorMessage: NSTextField!
    
    let imagesLoader = CollectionViewItemsLoader()
    var collectionLoadingIndicator:Accumulator?
    
    // MARK: Collection View for selection
    var selectionViewController : SelectionCollectionViewController!
    
    @IBOutlet weak var selectionCollectionView: NSCollectionView!
    
    @IBOutlet weak var selectionCheckAllBox: NSButton!
    
    // MARK: Editor - DateTime
    
    @IBOutlet weak var editorDatePicker: NSDatePicker!
    @IBOutlet weak var batchEditIndicator: NSProgressIndicator!
    
    
    
    // MARK: init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionProgressIndicator.isDisplayedWhenStopped = false
        
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        self.configurePreview()
        self.configureSelectionView()
        
        PreferencesController.healthCheck()
        
        self.initSourceListDataModel()
        self.loadPathToTreeFromDatabase()
        self.sourceList.backgroundColor = NSColor.darkGray
        self.sourceList.reloadData()
        
        configureCollectionView()
        configureEditors()
    }
    
    func configurePreview(){
        
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
    
    private func configureCollectionView() {
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
        imagesLoader.setupItems(urls: nil)
        collectionView.reloadData()
    }
    
    func configureSelectionView(){
        
        // init controller
        selectionViewController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "selectionView")) as! SelectionCollectionViewController
        self.addChildViewController(selectionViewController)
        
        // outlet
        self.selectionCollectionView.dataSource = selectionViewController
        self.selectionCollectionView.delegate = selectionViewController
        
        // flow layout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 180.0, height: 150.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        selectionCollectionView.collectionViewLayout = flowLayout

        // view layout
        selectionCollectionView.wantsLayer = true
        selectionCollectionView.backgroundColors = [NSColor.darkGray]
        selectionCollectionView.layer?.backgroundColor = NSColor.darkGray.cgColor
        selectionCollectionView.layer?.borderColor = NSColor.darkGray.cgColor
        
        // data model
        selectionViewController.collectionView = self.selectionCollectionView
        selectionViewController.imagesLoader.singleSectionMode = true
        selectionViewController.imagesLoader.setupItems(urls: nil)
        
        selectionCollectionView.reloadData()
        
    }
    
    func configureEditors(){
        editorDatePicker.dateValue = Date()
    }
    
    // MARK: Actions
    
    @IBAction func onMapSliderClick(_ sender: NSSliderCell) {
        let tick:Int = sender.integerValue
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
    
    // shared among different open-channels
    func processImageUrls(urls:[URL]){
        
        if urls.count == 0 {return}
        loadImage(urls[0])
    }
    
    private func previewImage(image:ImageData) {
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
            
        } else {
            
            // switch to video view
            stackedVideoViewController.view.frame = self.playerContainer.bounds
            self.playerContainer.addSubview(stackedVideoViewController.view)
            
            // show video
            stackedVideoViewController.videoDisplayer.player = AVPlayer(url: image.url)
            stackedVideoViewController.videoDisplayer.player?.play()
            
        }
    }
    
    private func loadImage(_ url:URL){
        
        // init meta data
        self.metaInfo = [MetaInfo]()
        self.img = ImageData(url: url, metaInfoStore: self)
        
        guard img.isPhoto || img.isVideo else {return}
        self.previewImage(image: img)
        
        //img.loadMetaInfoFromExif()
        img.loadMetaInfoFromDatabase()
        img.loadMetaInfoFromExif()
        self.sortMetaInfoArray()
        self.metaInfoTableView.reloadData()
        img.getBaiduLocation()
        self.loadBaiduMap()
    }
    
    private func loadBaiduMap() {
        webLocation.load(URLRequest(url: URL(string: "about:blank")!))
        if img.hasCoordinate {
            BaiduLocation.queryForMap(lat: img.latitudeBaidu, lon: img.longitudeBaidu, view: webLocation, zoom: zoomSize)
        }
    }
    
    @IBAction func onAddressSearcherAction(_ sender: Any) {
        let address:String = addressSearcher.stringValue
        if address == "" {return}
        BaiduLocation.queryForCoordinate(address: address, locationDelegate: self)
    }
    
    func loadDataForNewFolderWithUrl(folderURL: NSURL) {
        imagesLoader.load(from: folderURL)
        collectionView.reloadData()
    }
    
    @IBAction func showHideSections(sender: AnyObject) {
        let show = (sender as! NSButton).state
        imagesLoader.singleSectionMode = (show == NSControl.StateValue.off)
        imagesLoader.setupItems(urls: nil)
        collectionView.reloadData()
    }
    
    func selectImageFile(_ filename:String){
        self.selectedImageFile = filename
        //print("selected image file: \(filename)")
        let url:URL = (self.selectedImageFolder?.url.appendingPathComponent(filename, isDirectory: false))!
        DispatchQueue.main.async {
            self.loadImage(url)
        }
    }
    
    func selectImageFolder(_ imageFolder:ImageFolder){
        self.selectedImageFolder = imageFolder
        //print("selected image folder: \(imageFolder.url.path)")
        
        self.imagesLoader.setupItems(urls: nil)
        collectionView.reloadData()
        
        DispatchQueue.global().async {
            self.collectionLoadingIndicator = Accumulator(target: 1000, indicator: self.collectionProgressIndicator, suspended: true, lblMessage:self.indicatorMessage)
            self.imagesLoader.load(from: imageFolder.url as NSURL, indicator:self.collectionLoadingIndicator)
            self.refreshCollectionView()
        }
    }
    
    @IBAction func onAddButtonClicked(_ sender: Any) {
        let window = NSApplication.shared.windows.first
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories  = true
        openPanel.canChooseFiles        = false
        openPanel.showsHiddenFiles      = false
        
        openPanel.beginSheetModal(for: window!) { (response) -> Void in
            guard response == NSApplication.ModalResponse.OK else {return}
            if let path = openPanel.url?.path {
                DispatchQueue.main.async {
                    self.loadPathToTree(path)
                    self.sourceList.reloadData()
                }
            }
        }
    }
    
    @IBAction func onDelButtonClicked(_ sender: Any) {
        print("clicked delete button")
    }
    
    @IBAction func onRefreshButtonClicked(_ sender: Any) {
        print("clicked refresh button")
    }
    
    @IBAction func onRefreshCollectionButtonClicked(_ sender: Any) {
        self.refreshImagesLocation()
    }
    
    @IBAction func onPlacesCheckBoxClicked(_ sender: NSButton) {
        refreshCollectionView()
    }
    
    
    @IBAction func onSelectionRemoveButtonClicked(_ sender: Any) {
        // collect which to be removed from selection
        var images:[ImageFile] = [ImageFile]()
        for item in self.selectionCollectionView.visibleItems() {
            let item = item as! CollectionViewItem
            if item.isChecked() {
                images.append(item.imageFile!)
            }
        }
        // remove from selection
        for image in images {
            self.selectionViewController.imagesLoader.removeItem(image)
        }
        self.selectionViewController.imagesLoader.reorganizeItems()
        self.selectionCollectionView.reloadData()
        
        // uncheck in browser if exists there (if user changed to another folder, it won't be there)
        for item in self.collectionView.visibleItems() {
            let item = item as! CollectionViewItem
            let i = images.index(where: { $0.url == item.imageFile?.url })
            if i != nil {
                item.uncheck()
            }
        }
        self.selectionCheckAllBox.state = NSButton.StateValue.off
    }
    

    @IBAction func onSelectionCheckAllClicked(_ sender: NSButton) {
        if self.selectionCheckAllBox.state == NSButton.StateValue.on {
            for item in self.selectionCollectionView.visibleItems() {
                let item = item as! CollectionViewItem
                item.check()
            }
        }else {
            for item in self.selectionCollectionView.visibleItems() {
                let item = item as! CollectionViewItem
                item.uncheck()
            }
        }
    }
    
    // from favourites
    @IBAction func onCopyLocationFromListClicked(_ sender: Any) {
    }
    
    // from selected image
    @IBAction func onCopyLocationFromMapClicked(_ sender: Any) {
        guard self.img != nil && self.img.longitude != 0 && self.img.latitude != 0 else {return}
        if self.possibleLocation == nil {
            self.possibleLocation = Location()
        }
        self.possibleLocation?.latitude = img.latitude
        self.possibleLocation?.longitude = img.longitude
        self.possibleLocation?.latitudeBD = img.latitudeBaidu
        self.possibleLocation?.longitudeBD = img.longitudeBaidu
        
        self.possibleLocation?.country = self.getMeta(category: "Location", subCategory: "Baidu", title: "Country") ?? ""
        self.possibleLocation?.province = self.getMeta(category: "Location", subCategory: "Baidu", title: "Province") ?? ""
        self.possibleLocation?.city = self.getMeta(category: "Location", subCategory: "Baidu", title: "City") ?? ""
        self.possibleLocation?.district = self.getMeta(category: "Location", subCategory: "Baidu", title: "District") ?? ""
        self.possibleLocation?.businessCircle = self.getMeta(category: "Location", subCategory: "Baidu", title: "BusinessCircle") ?? ""
        self.possibleLocation?.street = self.getMeta(category: "Location", subCategory: "Baidu", title: "Street") ?? ""
        self.possibleLocation?.address = self.getMeta(category: "Location", subCategory: "Baidu", title: "Address") ?? ""
        self.possibleLocation?.addressDescription = self.getMeta(category: "Location", subCategory: "Baidu", title: "Description") ?? ""
        
        print("possible location address: \(possibleLocation?.address ?? "")")
        print("possible location place: \(possibleLocation?.place ?? "")")
        
        
        self.addressSearcher.stringValue = ""
        
        BaiduLocation.queryForAddress(lat: img.latitudeBaidu, lon: img.longitudeBaidu, metaInfoStore: self.locationTextDelegate!)
        BaiduLocation.queryForMap(lat: img.latitudeBaidu, lon: img.longitudeBaidu, view: webPossibleLocation, zoom: zoomSizeForPossibleAddress)
        
    }
    
    @IBAction func onReplaceLocationClicked(_ sender: Any) {
        guard self.possibleLocation != nil && self.selectionViewController.imagesLoader.getItems().count > 0 else {return}
        let accumulator:Accumulator = Accumulator(target: self.selectionViewController.imagesLoader.getItems().count, indicator: self.batchEditIndicator, suspended: false, lblMessage: nil)
        let location:Location = self.possibleLocation!
        for item in self.selectionViewController.imagesLoader.getItems() {
            let url:URL = item.url as URL
            if url.isPhoto() || url.isVideo() {
                ExifTool.helper.patchGPSCoordinateForImage(latitude: location.latitude!, longitude: location.longitude!, url: url)
                item.assignLocation(location: location)
                
                
                let imageInSelection:ImageFile? = self.imagesLoader.getItem(path: url.path)
                if imageInSelection != nil {
                    imageInSelection!.assignLocation(location: location)
                }
                
                print("place after assign location: \(item.place)")
                item.saveToModelStore(notifyIndicator: false)
            }
            let _ = accumulator.add()
        }
        self.selectionViewController.imagesLoader.reorganizeItems()
        self.selectionCollectionView.reloadData()
        self.imagesLoader.reorganizeItems(considerPlaces: (self.considerPlacesCheckBox.state == NSButton.StateValue.on))
        self.collectionView.reloadData()
        
    }
    
    @IBAction func onReplaceDateClicked(_ sender: Any) {
        guard self.selectionViewController.imagesLoader.getItems().count > 0 else {return}
        let accumulator:Accumulator = Accumulator(target: self.selectionViewController.imagesLoader.getItems().count, indicator: self.batchEditIndicator, suspended: false, lblMessage: nil)
        for item:ImageFile in self.selectionViewController.imagesLoader.getItems() {
            let url:URL = item.url as URL
            if url.isPhoto() {
                ExifTool.helper.patchDateForPhoto(date: self.editorDatePicker.dateValue, url: url)
            }else if url.isVideo() {
                ExifTool.helper.patchDateForVideo(date: self.editorDatePicker.dateValue, url: url)
            }
            item.assignDate(date: self.editorDatePicker.dateValue)
            item.saveToModelStore(notifyIndicator: false)
            
            let _ = accumulator.add()
        }
        self.selectionViewController.imagesLoader.reorganizeItems()
        self.selectionCollectionView.reloadData()
    }
    
    // add to favourites
    @IBAction func onAddEventButtonClicked(_ sender: Any) {
    }
    
    @IBAction func onAssignEventButtonClicked(_ sender: Any) {
        guard self.selectionViewController.imagesLoader.getItems().count > 0 else {return}
        let accumulator:Accumulator = Accumulator(target: self.selectionViewController.imagesLoader.getItems().count, indicator: self.batchEditIndicator, suspended: false, lblMessage: nil)
        for item:ImageFile in self.selectionViewController.imagesLoader.getItems() {
            let url:URL = item.url as URL
            if url.isPhoto() || url.isVideo(){
                ExifTool.helper.assignKeyValueForImage(key: "Event", value: "some event", url: url)
            }
            let _ = accumulator.add()
        }
    }
    
    // add to favourites
    @IBAction func onMarkLocationButtonClicked(_ sender: Any) {
    }
    
    
    
}





