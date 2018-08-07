//
//  TreeListController.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2018/4/28.
//  Copyright © 2018年 nonamecat. All rights reserved.
//

import Cocoa
import PXSourceList
import GRDB

let photosIcon:NSImage = NSImage(imageLiteralResourceName: "photos")
let eventsIcon:NSImage = NSImage(imageLiteralResourceName: "events")
let peopleIcon:NSImage = NSImage(imageLiteralResourceName: "people")
let placesIcon:NSImage = NSImage(imageLiteralResourceName: "places")
let albumIcon:NSImage = NSImage(imageLiteralResourceName: "album")
let folderIcon:NSImage = NSImage(imageLiteralResourceName: "folderOpen")
let folderAltIcon:NSImage = NSImage(imageLiteralResourceName: "folderOpenAlt")
let calendarIcon:NSImage = NSImage(imageLiteralResourceName: "calendar")
let clockIcon:NSImage = NSImage(imageLiteralResourceName: "clock")
let flagIcon:NSImage = NSImage(imageLiteralResourceName: "flag")
let anchorIcon:NSImage = NSImage(imageLiteralResourceName: "anchor")
let phoneIcon:NSImage = NSImage(imageLiteralResourceName: "phone")
let printIcon:NSImage = NSImage(imageLiteralResourceName: "print")
let shareIcon:NSImage = NSImage(imageLiteralResourceName: "share")

extension ViewController {
    
    // MARK: INIT
    
    func initTreeDataModel() {
        placesIcon.isTemplate = true
        peopleIcon.isTemplate = true
        eventsIcon.isTemplate = true
        photosIcon.isTemplate = true
        albumIcon.isTemplate = true
        phoneIcon.isTemplate = true
        
        self.sourceListItems = NSMutableArray(array:[])
        //self.modelObjects = NSMutableArray(array:[])
        
        if self.deviceSectionOfTree == nil {
            self.deviceSectionOfTree = self.addTreeSection(title: "DEVICES")
        }
        
        if self.librarySectionOfTree == nil {
            self.librarySectionOfTree = self.addTreeSection(title: "LIBRARY")
        }
        
        if self.momentSectionOfTree == nil {
            self.momentSectionOfTree = self.addTreeSection(title: "MOMENTS")
        }
        
        if self.eventSectionOfTree == nil {
            self.eventSectionOfTree = self.addTreeSection(title: "EVENTS")
        }
        
        if self.placeSectionOfTree == nil {
            self.placeSectionOfTree = self.addTreeSection(title: "PLACES")
        }
        
        self.addDeviceTypeTreeEntry(type: "Android")
        self.addDeviceTypeTreeEntry(type: "iPhone")
 
    }
    
    // MARK: SECTIONS
    
    func deviceItem() -> PXSourceListItem {
        return self.sourceListItems![0] as! PXSourceListItem
    }
    
    func libraryItem() -> PXSourceListItem {
        return self.sourceListItems![1] as! PXSourceListItem
    }
    
    func momentItem() -> PXSourceListItem {
        return self.sourceListItems![2] as! PXSourceListItem
    }
    
    func eventItem() -> PXSourceListItem {
        return self.sourceListItems![3] as! PXSourceListItem
    }
    
    func placeItem() -> PXSourceListItem {
        return self.sourceListItems![4] as! PXSourceListItem
    }
    
    func addTreeSection(title:String) -> PXSourceListItem {
        let item:PXSourceListItem = PXSourceListItem(title: title, identifier: "")
        self.sourceListItems?.add(item)
        self.identifiersOfLibraryTree[title] = item
        return item
    }
    
    // MARK: BEFORE and AFTER REFRESH
    
    func saveTreeItemsExpandState() {
        
        // save expandable state of all items, mark by moment.id
        for idItem in self.treeIdItems {
            let expanded = self.sourceList.isItemExpanded(idItem.value)
            self.treeIdItemsExpandState[idItem.key] = expanded
            //if expanded {
            //    print("EXPANDED \(idItem.key)")
            //}
        }
    }
    
    func restoreTreeItemsExpandState() {
        // restore expanded state of expanded items, search by moment.id
        for parent in self.treeIdItemsExpandState.sorted(by: { $0.key.localizedCaseInsensitiveCompare($1.key) == ComparisonResult.orderedAscending }) {
            if parent.value {
                //print("EXPANDING \(parent.key)")
                let item = self.treeIdItems[parent.key]
                self.sourceList.expandItem(item)
            }
        }
    }
    
    func restoreTreeSelection(){
        guard self.treeLastSelectedIdentifier != "" && !treeRefreshing else {return}
        treeRefreshing = true
        // restore selection
        for idItem in self.treeIdItems {
            if idItem.key == self.treeLastSelectedIdentifier {
                //print("SELECT \(idItem.key)")
                let row = self.sourceList.row(forItem: idItem.value)
                self.sourceList.scrollRowToVisible(row)
                self.sourceList.selectRowIndexes(NSIndexSet(index: row) as IndexSet, byExtendingSelection: false)
                //self.sourceList.highlightSelection(inClipRect: self.sourceList.rect(ofRow: row))
                break
            }
        }
        treeRefreshing = false
    }
    
}

// MARK: VIEW and CLICK ACTION

extension ViewController : PXSourceListDelegate {
    
    func sourceList(_ sourceList: PXSourceList!, isGroupAlwaysExpanded group: Any!) -> Bool {
        return true
    }
    
    func sourceList(_ aSourceList:PXSourceList!, viewForItem item: Any!) -> NSView {
        var cellView: LCSourceListTableCellView? = nil
        if let sourceListItem: PXSourceListItem = item as? PXSourceListItem {
            
            if aSourceList.level(forItem: item) == 0 {
                let sectionCellView:PXSourceListTableCellView = (aSourceList.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: nil) as! PXSourceListTableCellView)
                sectionCellView.textField?.textColor = NSColor.white
                sectionCellView.textField?.stringValue = sourceListItem.title
                return sectionCellView
            } else {
                cellView = (aSourceList.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: nil) as! LCSourceListTableCellView)
            }
            if let t:String = sourceListItem.title {
                cellView?.textField?.stringValue = t
                //print(t)
            }
            
            cellView?.imageView?.image = sourceListItem.icon
            
            //print(sourceListItem.representedObject)
            
            if sourceListItem.representedObject == nil {
                // section, do nothing
                //print("COLLECTION IS NULL \(sourceListItem.title ?? "")")
                
                //if self.momentToCollection[sourceListItem.title] != nil {
                //    let _ = self.momentToCollection[sourceListItem.title]!
                    //print("found collection: \(collection.title) \(collection.photoCount)")
                //}
            }else{
                let collection: PhotoCollection = sourceListItem.representedObject as! PhotoCollection
                
                //print("COLLECTION: \(collection.title) , count: \(collection.photoCount)")
                
                let sourceTitle:String? = sourceListItem.title
                let collectionTitle:String? = collection.title
                if sourceTitle != nil && sourceTitle != "" {
                    cellView?.textField?.stringValue = sourceListItem.title
                } else {
                    if collectionTitle != nil && collectionTitle != "" {
                        cellView?.textField?.stringValue = collection.title
                    }
                }
                if sourceTitle == nil && collectionTitle != nil {
                    cellView?.textField?.stringValue = collectionTitle!
                }
                cellView?.badge?.stringValue = " \(collection.photoCount) "
                cellView?.badge?.isHidden = (collection.photoCount == 0)
                
            
            }
            return cellView!
        }else {
            return cellView!
        }
    }
    
    func sourceListSelectionDidChange(_ notification: Notification!) {
        guard !self.treeRefreshing else {
            //self.indicatorMessage.stringValue = "Updating tree, please wait for a while"
            return
        }
        //var removeButtonEnabled:Bool = false
        if let selectedItem:PXSourceListItem = self.sourceList.item(atRow: self.sourceList.selectedRow) as? PXSourceListItem {
            
            if let collection:PhotoCollection = selectedItem.representedObject as? PhotoCollection {
                
                if collection.source! == .library {
                    self.selectImageFolder(collection.imageFolder!)
                }else if collection.source! == .moment {
                    //print("selected moment \(collection.title)")
                    self.selectMoment(collection, groupByPlace: false)
                }else if collection.source! == .place {
                    //print("selected place moment \(collection.title)")
                    self.selectMoment(collection, groupByPlace: true)
                }else if collection.source! == .event {
                    //print("selected place moment \(collection.title)")
                    self.selectEvent(collection)
                }else if collection.source! == .device {
                    self.selectDeviceNode(collection)
                }
                
                self.treeLastSelectedIdentifier = collection.identifier
            }
        }
    }
    
}

// MARK: DATA SOURCE

extension ViewController : PXSourceListDataSource {
    func sourceList(_ sourceList: PXSourceList!, numberOfChildrenOfItem item: Any!) -> UInt {
        if item != nil {
            if let node = item as? PXSourceListItem {
                return UInt(node.children.count)
            }else {
                return UInt(self.sourceListItems!.count)
            }
        } else{
            // when just init sections
            return UInt(5)
        }
    }
    
    func sourceList(_ aSourceList: PXSourceList!, child index: UInt, ofItem item: Any!) -> Any! {
        if let node = item as? PXSourceListItem {
            //print("getting child of item \(node.title) \(index)/\(node.children.count)")
            return node.children[Int(index)]
        }else{
            return self.sourceListItems?[Int(index)] ?? PXSourceListItem()
        }
    }
    
    func sourceList(_ aSourceList: PXSourceList!, isItemExpandable item: Any!) -> Bool {
        if let node = item as? PXSourceListItem {
            return node.hasChildren()
        }else{
            return false
        }
    }
    
    
}
