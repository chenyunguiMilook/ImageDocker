//
//  ExportManager.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2018/6/18.
//  Copyright © 2018年 nonamecat. All rights reserved.
//

import Cocoa

class ExportManager {
    
    static var working:Bool = false
    static var suppressed:Bool = false
    static var messageBox:NSTextField? = nil
    
    @objc static func enable() {
        suppressed = false
        
        if messageBox != nil {
            DispatchQueue.main.async {
                messageBox?.stringValue = ""
            }
        }
    }
    
    @objc static func disable() {
        suppressed = true
        if messageBox != nil {
            DispatchQueue.main.async {
                messageBox?.stringValue = ""
            }
        }
    }
    
    static func md5(pathOfFile:String) -> String {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
        let cmd = Process()
            cmd.standardOutput = pipe
            cmd.standardError = pipe
            cmd.launchPath = "/sbin/md5"
            cmd.arguments = []
            cmd.arguments?.append(pathOfFile)
            cmd.launch()
            cmd.waitUntilExit()
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        print(string)
        if string != "" && string.starts(with: "MD5 (") {
            let comp:[String] = string.components(separatedBy: " = ")
            if comp.count == 2 {
                return comp[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    static func export(after date:Date) {
        if suppressed {
            print("ExportManager is suppressed.")
            return
        }
        if working {
            print("ExportManager: Another instance is working, I'll take a rest.")
            return
        }
        //print("exporting")
        working = true
        print("  ")
        print("!! ExportManager start working at \(Date())")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日HH点mm分ss"
        
        //var filepaths:[String] = []
        
        if PreferencesController.exportDirectory() != "" {
            let fm:FileManager = FileManager.default
            if !fm.fileExists(atPath: PreferencesController.exportDirectory()) {
                do {
                    try fm.createDirectory(atPath: PreferencesController.exportDirectory(), withIntermediateDirectories: true, attributes: nil)
                }catch{
                    print("Cannot location or create destination directory for exporting photos: \(PreferencesController.exportDirectory())")
                    print(error)
                    return
                }
            }
            
            // check exported
            
            if messageBox != nil {
                DispatchQueue.main.async {
                    messageBox?.stringValue = "EXPORT Validating ..."
                }
            }
            
            let allMarkedExported = ModelStore.default.getAllPhotoFilesMarkedExported()
            let totalMarked = allMarkedExported.count
            var k:Int = 0
            
            
            print("\(Date()) EXPORT: CHECKING IF MARKED EXPORTED ARE REALLY EXPORTED")
            for photo in allMarkedExported {
                
                // if suppressed from outside, stop immediately
                if suppressed {
                    ExportManager.working = false
                    DispatchQueue.main.async {
                        messageBox?.stringValue = ""
                    }
                    return
                }
                
                k += 1
                if messageBox != nil {
                    DispatchQueue.main.async {
                        messageBox?.stringValue = "EXPORT Validating ... ( \(k) / \(totalMarked) )"
                    }
                }
                
                if photo.exportToPath != nil && photo.exportAsFilename != nil {
                    let fullpath:String = "\(photo.exportToPath ?? "")/\(photo.exportAsFilename ?? "")"
                    if !fm.fileExists(atPath: fullpath){
                        ModelStore.default.cleanImageExportTime(path: photo.path)
                        //photo.exportTime = nil
                        //recovered = true
                    }
                }
            }
            
            print("\(Date()) EXPORT: CHECKING IF MARKED EXPORTED ARE REALLY EXPORTED: DONE")
            
            // check updates and which not exported
            if messageBox != nil {
                DispatchQueue.main.async {
                    messageBox?.stringValue = "EXPORT Searching for updates ..."
                }
            }
            
            print("\(Date()) EXPORT: CHECKING UPDATES AND WHICH NOT EXPORTED")
            
            let allowedExt:Set<String> = ["jpg", "jpeg", "mp4", "mov", "mpg", "mpeg"]
            
            let total = ModelStore.default.countAllPhotoFilesForExporting(after: date)
            
            var batchTotal = 1
            let batchLimit = 500
            
            var i:Int = 0
            while(batchTotal > 0) {
                
                // check updates and which not exported
                if messageBox != nil {
                    DispatchQueue.main.async {
                        messageBox?.stringValue = "EXPORT Searching for updates ..."
                    }
                }
                
                print("\(Date()) EXPORT: CHECKING UPDATES AND WHICH NOT EXPORTED")
            
                let photos:[Image] = ModelStore.default.getAllPhotoFilesForExporting(after: date, limit: batchLimit)
                
                batchTotal = photos.count
                
                if batchTotal == 0 {
                    break
                }
                
                for photo in photos {
                    
                    // if suppressed from outside, stop immediately
                    if suppressed {
                        
                        ExportManager.working = false
                        DispatchQueue.main.async {
                            messageBox?.stringValue = ""
                        }
                        return
                    }
                    
                    
                    
                    i += 1
                    if messageBox != nil {
                        DispatchQueue.main.async {
                            messageBox?.stringValue = "EXPORT Processing ... ( \(i) / \(total) )"
                        }
                    }
                    
                    print("EXPORT Processing \(i) : \(photo.path)")
                    
                    if photo.photoTakenYear == 0 {
                        continue
                    }
                    
                    let pathUrl = URL(fileURLWithPath: photo.path)
                    let pathExt = pathUrl.pathExtension.lowercased()
                    
                    if !allowedExt.contains(pathExt){
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                        continue
                    }
                    
                    if !FileManager.default.fileExists(atPath: photo.path) {
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                        continue
                    }
                    
                    var pathComponents:[String] = []
                    pathComponents.append(PreferencesController.exportDirectory())
                    pathComponents.append("\(photo.photoTakenYear ?? 0)年")
                    //let year:String = "\(photo.photoTakenYear)"
                    let month:String = photo.photoTakenMonth! < 10 ? "0\(photo.photoTakenMonth ?? 0)" : "\(photo.photoTakenMonth ?? 0)"
                    //let day:String = photo.photoTakenDay < 10 ? "0\(photo.photoTakenDay)" : "\(photo.photoTakenDay)"
                    let event:String = photo.event == nil || photo.event == "" ? "" : " \(photo.event ?? "")"
                    pathComponents.append("\(month)月\(event)")
                    let path:String = pathComponents.joined(separator: "/")
                    
                    do {
                        try fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                    }catch{
                        print("Cannot create directory: \(path)")
                        print(error)
                        continue
                    }
                    
                    var eventAndPlace = ""
                    var photoDateFormatted = ""
                    var filenameComponents:[String] = []
                    if photo.photoTakenDate != nil {
                        photoDateFormatted = dateFormatter.string(from: photo.photoTakenDate!)
                        filenameComponents.append(photoDateFormatted)
                        if photo.event != nil && photo.event != "" {
                            eventAndPlace = "\(photo.event!)"
                            filenameComponents.append(" ")
                            filenameComponents.append(photo.event!)
                        }
                        if photo.place != nil && photo.place != "" {
                            eventAndPlace = "\(eventAndPlace) 在 \(photo.place!)"
                            filenameComponents.append(" 在")
                            filenameComponents.append(photo.place!)
                        }
                    }
                    var imageDescription = ""
                    if eventAndPlace != "" {
                        imageDescription = "\(eventAndPlace), \(photoDateFormatted)"
                    }else{
                        imageDescription = photoDateFormatted
                    }
                    
                    if (photo.filename.starts(with: "mmexport")) {
                        filenameComponents.append(" (来自微信)")
                    }
                    
                    if (photo.filename.starts(with: "QQ空间视频_")) {
                        filenameComponents.append(" (来自QQ)")
                    }
                    
                    if (photo.filename.starts(with: "Screenshot_")) {
                        filenameComponents.append(" (手机截屏)")
                    }
                    
                    let fileExt:String = (photo.filename.split(separator: Character(".")).last?.lowercased())!
                    filenameComponents.append(".")
                    filenameComponents.append(fileExt)
                    
                    // export as this name
                    var filename:String = filenameComponents.joined()
                    
                    // export to this path
                    var fullpath:String = "\(path)/\(filename)"
                    
                    var originalExportPath = "\(photo.exportToPath ?? "")/\(photo.exportAsFilename ?? "")"
                    if originalExportPath == "/" {
                        originalExportPath = ""
                    }
                    if originalExportPath != fullpath {
                        print("\(Date()) Change ImageDescription for \(photo.path)")
                        ExifTool.helper.patchImageDescription(description: imageDescription, url: URL(fileURLWithPath: photo.path))
                        print("\(Date()) Change ImageDescription for \(photo.path) : DONE")
                    }
                    // detect duplicates
                    if originalExportPath == fullpath { // export to the same path as previous
                        if fm.fileExists(atPath: fullpath) {
                            print("\(Date()) Getting MD5 for \(photo.path)")
                            let md5Exists = md5(pathOfFile: fullpath)
                            let md5PhotoFile = md5(pathOfFile: photo.path)
                            print("\(Date()) Getting MD5 for \(photo.path) : DONE")
                            if md5Exists == md5PhotoFile {
                                // same file, abort
                                //filepaths.append(originalExportPath)
                                
                                if photo.exportTime == nil {
                                    ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                                    //photo.exportTime = Date()
                                    //dataChanged = true
                                }
                                continue
                            }else{
                                // different file, delete the one in export path
                                print("!! exists destination \(fullpath) , different md5, delete")
                                do {
                                    try fm.removeItem(atPath: originalExportPath)
                                }catch {
                                    print("Cannot delete original copy: \(originalExportPath)")
                                    print(error)
                                }
                            }
                        }
                    }else if originalExportPath != "" && originalExportPath != fullpath { // export to a different path from previous
                        if fm.fileExists(atPath: originalExportPath) { // delete the one in previous path
                            do {
                                try fm.removeItem(atPath: originalExportPath)
                            }catch {
                                print("Cannot delete original copy: \(originalExportPath)")
                                print(error)
                            }
                        }
                    }
                    
                    // other photo occupied the filename, same md5, abort
                    if fm.fileExists(atPath: fullpath) {
                        let md5Exists = md5(pathOfFile: fullpath)
                        let md5PhotoFile = md5(pathOfFile: photo.path)
                        if md5Exists == md5PhotoFile {
                            
                            if photo.exportTime == nil {
                                ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                                //photo.exportTime = Date()
                                //dataChanged = true
                            }
                            continue
                        }
                    }
                    // other photo occupied the filename, different md5, change filename
                    if fm.fileExists(atPath: fullpath) {
                        //print("!! exists destination \(fullpath) , add camera as suffix")
                        filenameComponents.removeLast()
                        filenameComponents.removeLast()
                        if photo.cameraMaker != nil && photo.cameraMaker != "" {
                            filenameComponents.append(" (\(photo.cameraMaker!)")
                            
                            if photo.cameraModel != nil && photo.cameraModel != "" {
                                filenameComponents.append(" \(photo.cameraModel!)")
                            }
                            filenameComponents.append(")")
                        }
                        filenameComponents.append(".")
                        filenameComponents.append(fileExt)
                        filename = filenameComponents.joined()
                        fullpath = "\(path)/\(filename)"
                    }
                    // other photo occupied the filename, different md5, change filename
                    for i in 1...9999 {
                        let suffix = i < 10 ? "0\(i)" : "\(i)"
                        
                        if fm.fileExists(atPath: fullpath) {
                            //print("!! exists destination \(fullpath) , add \(suffix) as suffix")
                            filenameComponents.removeLast() // fileExt
                            filenameComponents.removeLast() // .
                            if i > 1 {
                                filenameComponents.removeLast() // suffix
                            }
                            filenameComponents.append(" \(suffix)")
                            filenameComponents.append(".")
                            filenameComponents.append(fileExt)
                            filename = filenameComponents.joined()
                            fullpath = "\(path)/\(filename)"
                        }else{
                            break
                        }
                    }
                    
                    
                    if messageBox != nil {
                        DispatchQueue.main.async {
                            messageBox?.stringValue = "EXPORT Copying ... ( \(i) / \(total) )"
                        }
                    }
                    print("\(Date()) Copy file \(photo.path)")
                    do {
                        try fm.copyItem(atPath: photo.path, toPath: "\(path)/\(filename)")
                    }catch {
                        print("Cannot copy from: \(photo.path) to: \(path)/\(filename) ")
                        print(error)
                        
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                        continue
                    }
                    print("\(Date()) Copy file \(photo.path) : DONE")
                    
                    
                    if photo.exportToPath == nil || path != photo.exportToPath {
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date(), exportToPath: path)
                        //photo.exportToPath = path
                        //photo.exportTime = Date()
                        //dataChanged = true
                    }
                    if photo.exportAsFilename == nil || filename != photo.exportAsFilename {
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date(), exportedFilename: filename)
                        //photo.exportAsFilename = filename
                        //photo.exportTime = Date()
                        //dataChanged = true
                    }
                    
                    if photo.exportTime == nil {
                        ModelStore.default.storeImageExportedTime(path: photo.path, date: Date())
                        //photo.exportTime = Date()
                        //dataChanged = true
                    }
                    
                    //filepaths.append(fullpath)
                }
            } // end of while loop
            
            if messageBox != nil {
                DispatchQueue.main.async {
                    messageBox?.stringValue = ""
                }
            }
            
            print("\(Date()) EXPORT: CHECKING UPDATES AND WHICH NOT EXPORTED: DONE")
            
            
            // if suppressed from outside, stop immediately
            if suppressed {
                ExportManager.working = false
                DispatchQueue.main.async {
                    messageBox?.stringValue = ""
                }
                return
            }
            
            // house keep
            
            print("\(Date()) EXPORT: HOUSE KEEP")
            let allExportedFilenames:Set<String> = ModelStore.default.getAllExportedPhotoFilenames()
            
            let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: PreferencesController.exportDirectory()),
                                                            includingPropertiesForKeys: [.isDirectoryKey, .isReadableKey, .isWritableKey ],
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            var allExportedDirectories:Set<String> = []
            var uselessFiles:Set<String> = []
            for case let file as URL in enumerator {
                do {
                    
                    // if suppressed from outside, stop immediately
                    if suppressed {
                        ExportManager.working = false
                        DispatchQueue.main.async {
                            messageBox?.stringValue = ""
                        }
                        return
                    }
                    
                    let url = try file.resourceValues(forKeys: [.isDirectoryKey, .isReadableKey, .isWritableKey])
                    if url.isWritable! {
                        if !url.isDirectory! {
                            if !allExportedFilenames.contains(file.path) {
                                print("found useless file \(file.path), mark to delete")
                                uselessFiles.insert(file.path)
                            }
                        }else {
                            allExportedDirectories.insert("\(file.path)/")
                        }
                    }
                }catch{
                    print("Error reading url properties for \(file.path)")
                    print(error)
                }
            }
            
            // delete useless files
            if uselessFiles.count > 0 {
                let total = uselessFiles.count
                var i = 0
                for uselessFile in uselessFiles {
                    
                    // if suppressed from outside, stop immediately
                    if suppressed {
                        ExportManager.working = false
                        DispatchQueue.main.async {
                            messageBox?.stringValue = ""
                        }
                        return
                    }
                    i += 1
                    
                    if messageBox != nil {
                        DispatchQueue.main.async {
                            messageBox?.stringValue = "Useless file ... ( \(i) / \(total) )"
                        }
                    }
                    
                    print("deleting useless file \(uselessFile)")
                    
                    do {
                        try fm.removeItem(atPath: uselessFile)
                    }catch {
                        print("Cannot delete useless file \(uselessFile)")
                        print(error)
                    }
                }
            }
            // recognize empty folders
            for exportedFilePath in allExportedFilenames {
                for folder in allExportedDirectories {
                    
                    // if suppressed from outside, stop immediately
                    if suppressed {
                        ExportManager.working = false
                        DispatchQueue.main.async {
                            messageBox?.stringValue = ""
                        }
                        return
                    }
                    
                    if exportedFilePath.starts(with: folder) {
                        allExportedDirectories.remove(folder)
                        continue
                    }
                }
            }
            // delete empty folders
            if allExportedDirectories.count > 0 {
                print("  ")
                let total = allExportedDirectories.count
                var i = 0
                for emptyFolder in allExportedDirectories {
                    
                    // if suppressed from outside, stop immediately
                    if suppressed {
                        ExportManager.working = false
                        DispatchQueue.main.async {
                            messageBox?.stringValue = ""
                        }
                        return
                    }
                    
                    i += 1
                    
                    if messageBox != nil {
                        DispatchQueue.main.async {
                            messageBox?.stringValue = "Empty folder ... ( \(i) / \(total) )"
                        }
                    }
                    
                    print("deleting empty folder \(emptyFolder)")
                    do {
                        try fm.removeItem(atPath: emptyFolder)
                    }catch{
                        print("  Cannot delete empty folder \(emptyFolder)")
                        print(error)
                    }
                }
                print("  ")
            }
            
            if messageBox != nil {
                DispatchQueue.main.async {
                    messageBox?.stringValue = ""
                }
            }
            
            print("\(Date()) EXPORT: HOUSE KEEP: DONE")
            
            ExportManager.working = false
        }
    }
}
