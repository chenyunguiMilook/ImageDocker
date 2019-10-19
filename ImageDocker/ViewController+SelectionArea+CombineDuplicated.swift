//
//  ViewController+SelectionArea+Combine.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/9/29.
//  Copyright © 2019 nonamecat. All rights reserved.
//

import Cocoa

extension ViewController {
    
    internal func selectCombineMenuInSelectionArea(_ i:Int) {
        
        self.btnDuplicates.isEnabled = false
        if i == 1 {
            self.markCheckedImageAsDuplicatedChief()
        }else if i == 2 {
            self.decoupleCheckedImages()
        }else if i == 3 {
            self.combineCheckedImages()
        }else if i == 4 {
            self.combineSelectedImages(checkedAsChief: false)
        }else if i == 5 {
            self.combineSelectedImages(checkedAsChief: true)
        }
        self.btnDuplicates.isEnabled = true
    }
    
    internal func combineSelectedImages(checkedAsChief:Bool) {
        let items = self.selectionViewController.imagesLoader.getItems()
        if items.count == 0 {
            Alert.noImageSelected()
            return
        }
        var major = items[0]
        if checkedAsChief {
            let checked = self.selectionViewController.imagesLoader.getCheckedItems()
            if checked.count == 0 {
                Alert.checkOneImage()
                return
            }
            major = checked[0]
        }
        if let image = major.imageData, let date = image.photoTakenDate {
            let place = Naming.Place.place(from: image)
            let year = Calendar.current.component(.year, from: date)
            let month = Calendar.current.component(.month, from: date)
            let day = Calendar.current.component(.day, from: date)
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            let second = Calendar.current.component(.second, from: date)
            
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyyMMddHHmmss"
            let now = dateFormat.string(from: Date())
            
            let key = "\(place)_\(year)_\(month)_\(day)_\(hour)_\(minute)_\(second)_\(now)"
            for imageFile in items {
                if imageFile.url.path == major.url.path {
                    ModelStore.default.markImageDuplicated(path: imageFile.url.path, duplicatesKey: key, hide: false)
                }else{
                    ModelStore.default.markImageDuplicated(path: imageFile.url.path, duplicatesKey: key, hide: true)
                }
                ModelStore.default.getDuplicatePhotos().updateMapping(key: key, path: imageFile.url.path)
            }
            self.selectionViewController.imagesLoader.reload()
            self.selectionViewController.imagesLoader.reorganizeItems()
            self.selectionCollectionView.reloadData()
            
            self.imagesLoader.reload()
            self.imagesLoader.reorganizeItems()
            self.collectionView.reloadData()
        }
    }
    
    // MARK: Selection View - Batch Editor - Duplicates
    
    internal func markCheckedImageAsDuplicatedChief() {
        let items = self.selectionViewController.imagesLoader.getItems()
        if items.count == 0 {
            Alert.noImageSelected()
            return
        }
        let checked = self.selectionViewController.imagesLoader.getCheckedItems()
        if checked.count != 1 {
            Alert.checkOneImage()
            return
        }
        let imageFile = checked[0]
        if let image = ModelStore.default.getImage(path: imageFile.url.path), let duplicatesKey = image.duplicatesKey {
            if let paths = ModelStore.default.getDuplicatePhotos().keyToPath[duplicatesKey] {
                for path in paths {
                    if path == imageFile.url.path {
                        print("to be changed: show - \(path)")
                        ModelStore.default.markImageDuplicated(path: path, duplicatesKey: duplicatesKey, hide: false)
                    }else{
                        print("to be changed: hide - \(path)")
                        ModelStore.default.markImageDuplicated(path: path, duplicatesKey: duplicatesKey, hide: true)
                    }
                }
                self.selectionViewController.imagesLoader.reload()
                self.selectionViewController.imagesLoader.reorganizeItems()
                self.selectionCollectionView.reloadData()
                
                self.imagesLoader.reload()
                self.imagesLoader.reorganizeItems()
                self.collectionView.reloadData()
            }
        }
    }
    
    internal func decoupleCheckedImages() {
        let items = self.selectionViewController.imagesLoader.getItems()
        if items.count == 0 {
            Alert.noImageSelected()
            return
        }
        let checked = self.selectionViewController.imagesLoader.getCheckedItems()
        if checked.count == 0 {
            Alert.checkImages()
            return
        }
        for imageFile in checked {
            ModelStore.default.markImageDuplicated(path: imageFile.url.path, duplicatesKey: nil, hide: false)
        }
        self.selectionViewController.imagesLoader.reload()
        self.selectionViewController.imagesLoader.reorganizeItems()
        self.selectionCollectionView.reloadData()
        
        self.imagesLoader.reload()
        self.imagesLoader.reorganizeItems()
        self.collectionView.reloadData()
    }
    
    internal func combineCheckedImages() {
        let items = self.selectionViewController.imagesLoader.getItems()
        if items.count == 0 {
            Alert.noImageSelected()
            return
        }
        let checked = self.selectionViewController.imagesLoader.getCheckedItems()
        if checked.count == 0 {
            Alert.checkImages()
            return
        }
        let first = checked[0]
        
        if let image = ModelStore.default.getImage(path: first.url.path), let date = image.photoTakenDate {
            let oldKey = image.duplicatesKey ?? ""
            
            // generate new key
            let place = Naming.Place.place(from: image)
            let year = Calendar.current.component(.year, from: date)
            let month = Calendar.current.component(.month, from: date)
            let day = Calendar.current.component(.day, from: date)
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            let second = Calendar.current.component(.second, from: date)
            
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyyMMddHHmmss"
            let now = dateFormat.string(from: Date())
            
            let key = "\(place)_\(year)_\(month)_\(day)_\(hour)_\(minute)_\(second)_\(now)"
            
            // update images
            for imageFile in checked {
                if imageFile.url.path == first.url.path {
                    ModelStore.default.markImageDuplicated(path: imageFile.url.path, duplicatesKey: key, hide: false)
                }else{
                    ModelStore.default.markImageDuplicated(path: imageFile.url.path, duplicatesKey: key, hide: true)
                }
                ModelStore.default.getDuplicatePhotos().updateMapping(key: key, path: imageFile.url.path)
            }
            
            // health check for the original duplicated set (if exists)
            if oldKey != "" {
                let chiefOfOldKey = ModelStore.default.getChiefImageOfDuplicatedSet(duplicatesKey: oldKey)
                if chiefOfOldKey == nil {
                    if let firstOfOldKey = ModelStore.default.getFirstImageOfDuplicatedSet(duplicatesKey: oldKey) {
                        ModelStore.default.markImageDuplicated(path: firstOfOldKey.path, duplicatesKey: oldKey, hide: false)
                    }
                }
            }
            
            // refresh UI
            self.selectionViewController.imagesLoader.reload()
            self.selectionViewController.imagesLoader.reorganizeItems()
            self.selectionCollectionView.reloadData()
            
            self.imagesLoader.reload()
            self.imagesLoader.reorganizeItems()
            self.collectionView.reloadData()
        }
    }
}
