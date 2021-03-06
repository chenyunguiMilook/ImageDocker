//
//  Naming.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/10/19.
//  Copyright © 2019 nonamecat. All rights reserved.
//

import Foundation

enum ImageType : Int {
    case photo
    case video
    case other
}

struct Naming {
    static let Camera = CameraModelRecognizer()
    static let Image = ImagePropertyRules()
    static let Source = ImageSourceRecognizer()
    static let DateTime = DateTimeRecognizer()
    static let Place = PlaceRecognizer()
    static let FileType = FileTypeRecognizer()
    static let Event = EventRecognizer()
    static let Export = NamingForExporting()
}

struct ImagePropertyRules {
    
    /// Get event from folder name in the path
    /// - parameter image: Image record
    /// - parameter folderLevel: start from 1
    func getEventFromFolderName(image:Image, folderLevel:Int) -> String {
        return self.getEventFromFolderName(subPath: image.subPath, folderLevel: folderLevel)
    }
    
    /// Get event from folder name in the path
    /// - parameter subPath: /path/to/filename/without/repository/path, such as DCIM/IMG_12345.jpg
    /// - parameter folderLevel: start from 1
    func getEventFromFolderName(subPath:String, folderLevel lv:Int) -> String {
        let level = lv - 1
        let parts = subPath.components(separatedBy: "/")
        let n = parts[level]
        return n
    }
    
    /// Get brief from folder name in the path
    /// - parameter image: Image record
    /// - parameter folderLevel: start from 1 or -1, -1 means the last one
    func getBriefFromFolderName(image:Image, folderLevel:Int) -> String {
        return self.getBriefFromFolderName(subPath: image.subPath, folderLevel: folderLevel)
    }
    
    /// Get brief from folder name in the path
    /// - parameter subPath: /path/to/filename/without/repository/path, such as DCIM/IMG_12345.jpg
    /// - parameter folderLevel: start from 1 or -1, -1 means the last one
    func getBriefFromFolderName(subPath:String, folderLevel lv:Int) -> String {
        var level = lv - 1
        
        let parts = subPath.components(separatedBy: "/")
        var x = 0
        
        // filter
        let lastPart = parts[parts.count - 2] // presume the very last part is filename
        if lastPart == "DCIM" { x = 1 }
        if let _ = Int(lastPart) { x = 1 } // numeric
        
        if lv < 0 {
            level = parts.count - 1 + lv - x
        }
        if level < 0 {level = 0}
        let n = parts[level]
        return n
    }
    
}

// MARK: - FILE TYPE

struct FileTypeRecognizer {
    
    let photoExts:[String] = ["jpg", "jpeg", "png"]
    let videoExts:[String] = ["mov", "mp4", "mpeg", "mts", "m2ts"]
    
    let allowed:Set<String> = ["jpg", "jpeg", "mp4", "mov", "mpg", "mpeg", "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "vcf", "amr"]
    
    func recognize(from url:URL) -> ImageType {
        var type = self.recognize(from: url.lastPathComponent)
        
        if type == .other {
            do {
                let properties = try url.resourceValues(forKeys: [.typeIdentifierKey])
                guard let fileType = properties.typeIdentifier else { return type }
                if UTTypeConformsTo(fileType as CFString, kUTTypeImage) {
                    type = .photo
                }else if UTTypeConformsTo(fileType as CFString, kUTTypeMovie) {
                    type = .video
                }
            }
            catch {
                print("Unexpected error occured when recognizing image type: \(error).")
            }
        }
        
        return type
    }
    
    func recognize(from filename: String) -> ImageType {
        let fileExt:String = (filename.split(separator: Character(".")).last?.lowercased()) ?? filename
        if self.photoExts.contains(fileExt) {
            return.photo
        }else if self.videoExts.contains(fileExt) {
            return.video
        }
        return .other
    }
}

// MARK: - EVENT

struct EventRecognizer {
    
    func recognize(from url:URL, level:Int) -> String {
        if (level - 1) < 0 || level >= url.pathComponents.count { // last part is filename
            return ""
        }
        return url.pathComponents[level - 1]
    }
}

// MARK: - SOURCE

struct ImageSourceRecognizer {
    
    func recognize(url:URL) -> String {
        
        let filename = url.lastPathComponent
        return self.recognize(filename: filename)
    }
    
    func recognize(filename:String) -> String {
        var imageSource:String = ""
        if filename.starts(with: "mmexport") {
            imageSource = "WeChat"
        }else if filename.starts(with: "QQ空间视频") {
            imageSource = "QQ"
        }else if filename.starts(with: "IMG_") {
            imageSource = "Camera"
        }else if filename.starts(with: "VID_") {
            imageSource = "Camera"
        }else if filename.starts(with: "DSC") {
            imageSource = "Camera"
        }else if filename.starts(with: "Screenshot_") {
            imageSource = "ScreenShot"
        }
        if imageSource == "" {
            let parts:[String] = filename.matches(for: "[0-9a-zA-Z]{25}_[0-9]+\\.([A-Za-z0-9]{3}+)")
            if parts.count > 0 {
                imageSource = "PhoneApp"
            }
        }
        if imageSource == "" {
            let parts:[String] = filename.matches(for: "[0-9a-zA-Z]{32}\\.([A-Za-z0-9]{3}+)")
            if parts.count > 0 {
                imageSource = "PhoneApp"
            }
        }
        if imageSource == "" {
            let parts:[String] = filename.matches(for: "[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}-[0-9A-Z]{3}-[0-9A-Z]{16}_tmp\\.([A-Za-z0-9]{3}+)")
            if parts.count > 0 {
                imageSource = "PhoneApp"
            }
        }
        return imageSource
    }
}

// MARK: - CAMERA MODEL

class CameraModelRecognizer {
    
    let models:[String : [String : String]] = [
        "HUAWEI" : [
            "H60" : "Honor 6",
            "FRD" : "Honor 8",
            "KNT" : "Honor V8",
            "STF" : "Honor 9",
            "DUK" : "Honor V9",
            "COL" : "Honor 10",
            "BKL" : "Honor V10",
            "EVA" : "Perfect 9",
            "VIE" : "Perfect 9 Plus",
            "VTR" : "Perfect 10",
            "VKY" : "Perfect 10 Plus",
            "EML" : "Perfect 20",
            "CLT" : "Perfect 20 Plus",
            "MHA" : "Mate 9",
            "LON" : "Mate 9 Pro",
            "ALP" : "Mate 10",
            "BLA" : "Mate 10 Pro",
            "WAS" : "Nova Young"
        ]
    ]
    
    func recognize(maker:String, model:String) -> String{
        guard maker != "" && model != "" else {return model}
        for m in models.keys {
            if maker == m {
                print("Recognized maker \(m), trying to get name of model \(model)")
                for mm in models[m]! {
                    if model.starts(with: mm.key) {
                        return mm.value + " (" + model + ")"
                    }
                }
                break
            }
        }
        return model
    }
    
    func getMarketName(maker:String, model:String) -> String{
        guard maker != "" && model != "" else {return model}
        for m in models.keys {
            if maker == m {
                print("Recognized maker \(m), trying to get market name of model \(model)")
                for mm in models[m]! {
                    if model.starts(with: mm.key) {
                        print("Got market name [\(mm.value)] of [\(m) \(model)]")
                        return mm.value
                    }
                }
                break
            }
        }
        return ""
    }
}

// MARK: - DATE TIME

struct DateTimeRecognizer {
    
    let exifDateFormat = DateFormatter()
    let exifDateFormatWithTimezone = DateFormatter()
    
    init() {
        exifDateFormat.dateFormat = "yyyy:MM:dd HH:mm:ss"
        exifDateFormatWithTimezone.dateFormat = "yyyy:MM:dd HH:mm:ssxxx"
    }
    
    func get(from data:Image) -> Date? {
        let now:Date = Date()
        var date:Date? = data.photoTakenDate
        if date != nil && date! < now { return date }
        date = data.assignDateTime
        if date != nil && date! < now { return date }
        date = data.exifDateTimeOriginal
        if date != nil && date! < now { return date }
        if let dt = data.dateTimeFromFilename {
            date = exifDateFormat.date(from: dt)
        }
        if date != nil && date! < now { return date }
        date = data.exifCreateDate
        if date != nil && date! < now { return date }
        date = data.exifModifyDate
        if date != nil && date! < now { return date }
        date = data.videoCreateDate
        if date != nil && date! < now { return date }
        date = data.trackCreateDate
        if date != nil && date! < now { return date }
        date = data.filesysCreateDate
        if date != nil && date! < now { return date }
        date = data.softwareModifiedTime
        return date
    }
    
    func recognize(url:URL) -> String {
        
        // netease photo gallery, disordered
        if url.lastPathComponent.starts(with: "photo.163.com") {
            return self.recognizeDateTimeFromPath(path: url.path)
        }
        
        // other cases
        var date = self.recognizeDateTimeFromFilename(filename: url.lastPathComponent)
        if date == "" {
            date = self.recognizeDateTimeFromPath(path: url.path)
        }
        
        return date
    }
    
    func recognizeDateTimeFromFilename(filename: String) -> String {
        
        var date = ""
        // huawei pictures
        if date == "" {
            date = self.recognizeDateTimeFromFilename(filename: filename, patterns: [
                // huawei pictures
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{3})\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})-([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                
                // file copied
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_[0-9]\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})-[0-9]\\.([A-Za-z0-9]{3}+)",
                
                // file compressed by wechat
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_comps\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_[A-Za-z0-9]{32}_comps\\.([A-Za-z0-9]{3}+)",
                
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_BURST[0-9]{3}\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_BURST[0-9]{3}_COVER\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_[0-9]{3}_COVER\\.([A-Za-z0-9]{3}+)",
                "IMG_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_[0-9]{3}-[0-9]+\\.([A-Za-z0-9]{3}+)",
                
                // screenshots
                "Screenshot_([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                "Screenshot_([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})-([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                "Screenshot_([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                "pt([0-9]{4})_([0-9]{2})_([0-9]{2})_([0-9]{2})_([0-9]{2})_([0-9]{2})_([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                
                // from another camera models
                "YP([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                "YP([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})_[0-9]+\\.([A-Za-z0-9]{3}+)",
                "YP([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})_[0-9]+_[0-9]+\\.([A-Za-z0-9]{3}+)",
                "IMG([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                
                // qqzone video
                "QQ空间视频_([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                
                // huawei video
                "VID_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)",
                
                // face_u app
                "faceu_([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)"
                ])
        }
        
        if date == "" {
            date = self.recognizeDateTimeFromFilename(filename: filename, patterns: [
                
                // face_u app
                "faceu_([0-9]+)_([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\\.([A-Za-z0-9]{3}+)"
                
                ], startIndex: 1)
        }
        
        if date == "" {
            date = self.recognizeUnixTimeFromFilename(filename: filename, patterns: [
                
                // huawei honor6 video
                "([0-9]{13})\\.([A-Za-z0-9]{3}+)",
                
                // file exported by wechat
                "mmexport([0-9]{13})\\.([A-Za-z0-9]{3}+)",
                "mmexport([0-9]{13})-[0-9]+\\.([A-Za-z0-9]{3}+)",
                
                // file compressed by wechat
                "mmexport([0-9]{13})_comps\\.([A-Za-z0-9]{3}+)",
                
                // file copied by wechat
                "mmexport([0-9]{13})\\([0-9]+\\)\\.([A-Za-z0-9]{3}+)"
                
                ])
        }
        
        if date == "" {
            date = self.recognizeUnixTime2FromFilename(filename: filename, patterns: [
                
                // file exported by wechat
                "mmexport([0-9]{13})_([0-9]+)_[0-9]+\\.([A-Za-z0-9]{3}+)"
                
                ])
        }
        
        return date
    }
    
    func recognizeDateTimeFromPath(path: String) -> String {
        var date = ""
        
        if date == "" {
            date = self.recognizeYearMonthDayFromPath(path: path, patterns: [
                
                "([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})",
                "([0-9]{4})年([0-9]{2})月([0-9]{2})"
                
                ])
        }
        
        if date == "" {
            date = self.recognizeYearMonthFromPath(path: path, patterns: [
                
                "([0-9]{4})\\-([0-9]{2})",
                "([0-9]{4})年([0-9]{2})"
                
                ])
        }
        return date
    }
    
    
    
    internal func recognizeDateTimeFromFilename(filename: String, patterns:[String], startIndex:Int = 0) -> String {
        for pattern in patterns {
            let dateString = self.recognizeDateTimeFromFilename(filename: filename, pattern, startIndex)
            if dateString != "" {
                return dateString
            }
        }
        return ""
    }
    
    internal func recognizeDateTimeFromFilename(filename: String, _ pattern:String, _ startIndex:Int = 0) -> String{
        
        let parts:[String] = filename.matches(for: pattern)
        if parts.count > 0 {
            return "\(parts[startIndex+1]):\(parts[startIndex+2]):\(parts[startIndex+3]) \(parts[startIndex+4]):\(parts[startIndex+5]):\(parts[startIndex+6])"
        }
        return ""
    }
    
    
    
    internal func recognizeUnixTimeFromFilename(filename: String, patterns:[String]) -> String {
        for pattern in patterns {
            let dateString = self.recognizeUnixTimeFromFilename(filename: filename, pattern)
            if dateString != "" {
                return dateString
            }
        }
        return ""
    }
    
    internal func recognizeUnixTimeFromFilename(filename: String, _ pattern:String) -> String{
        let parts:[String] = filename.matches(for: pattern)
        if parts.count > 0 {
            let timestamp:String = "\(parts[1])"
            return self.convertUnixTimestampToDateString(timestamp)
        }
        return ""
    }
    
    internal func recognizeUnixTime2FromFilename(filename: String, patterns:[String]) -> String {
        for pattern in patterns {
            let dateString = self.recognizeUnixTime2FromFilename(filename: filename, pattern)
            if dateString != "" {
                return dateString
            }
        }
        return ""
    }
    
    internal func recognizeUnixTime2FromFilename(filename: String, _ pattern:String) -> String{
        let parts:[String] = filename.matches(for: pattern)
        if parts.count > 0 {
            let timestamp:String = "\(parts[1]).\(parts[2])"
            return self.convertUnixTimestampToDateString(timestamp)
        }
        return ""
    }
    
    internal func recognizeYearMonthFromPath(path: String, patterns:[String]) -> String {
        for pattern in patterns {
            let dateString = self.recognizeYearMonthFromPath(path: path, pattern)
            if dateString != "" {
                return dateString
            }
        }
        return ""
    }
    
    internal func recognizeYearMonthFromPath(path: String, _ pattern:String) -> String{
        let parts:[String] = path.matches(for: pattern)
        if parts.count > 0 {
            return "\(parts[1]):\(parts[2]):01 00:00:00"
        }
        return ""
    }
    
    internal func recognizeYearMonthDayFromPath(path: String, patterns:[String]) -> String {
        for pattern in patterns {
            let dateString = self.recognizeYearMonthDayFromPath(path: path, pattern)
            if dateString != "" {
                return dateString
            }
        }
        return ""
    }
    
    internal func recognizeYearMonthDayFromPath(path: String, _ pattern:String) -> String{
        let parts:[String] = path.matches(for: pattern)
        if parts.count > 0 {
            return "\(parts[1]):\(parts[2]):\(parts[3]) 00:00:00"
        }
        return ""
    }
    
    internal func convertUnixTimestampToDateString(_ timestamp:String, dateFormat:String = "yyyy:MM:dd HH:mm:ss") -> String {
        let date = NSDate(timeIntervalSince1970: Double(timestamp)!/1000 + 8*60*60) // GMT+8
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateTime = dateFormatter.string(from: date as Date)
        return dateTime
    }
}

// MARK: - PLACE

struct PlaceRecognizer {
    
    func country(from photoFile:Image) -> String {
        return photoFile.assignCountry ?? photoFile.country ?? ""
    }
    
    func province(from photoFile:Image) -> String {
        return photoFile.assignProvince ?? photoFile.province ?? ""
    }

    func city(from photoFile:Image) -> String {
        return photoFile.assignCity ?? photoFile.city ?? ""
    }
    
    func district(from photoFile:Image) -> String {
        return photoFile.assignDistrict ?? photoFile.district ?? ""
    }
    
    func street(from photoFile:Image) -> String {
        return photoFile.assignStreet ?? photoFile.street ?? ""
    }
    
    func businessCircle(from photoFile:Image) -> String {
        return photoFile.assignBusinessCircle ?? photoFile.businessCircle ?? ""
    }
    
    func address(from photoFile:Image) -> String {
        return photoFile.assignAddress ?? photoFile.address ?? ""
    }
    
    func addressDescription(from photoFile:Image) -> String {
        return photoFile.assignAddressDescription ?? photoFile.addressDescription ?? ""
    }
    
    func place(from photoFile:Image) -> String {
        return photoFile.assignPlace ?? photoFile.suggestPlace ?? photoFile.businessCircle ?? ""
    }
    
    func recognize(from data:Image) -> String {
        var prefix:String = ""
        
        var country = ""
        var city = ""
        var district = ""
        var place = ""
        
        country = data.assignCountry ?? data.country ?? ""
        city = data.assignCity ?? data.city ?? ""
        city = city.replacingOccurrences(of: "特别行政区", with: "")
        district = data.assignDistrict ?? data.district ?? ""
        place = data.assignPlace ?? data.suggestPlace ?? data.businessCircle ?? ""
        place = place.replacingOccurrences(of: "特别行政区", with: "")
    
        if country == "中国" {
            if city != "" && city.reversed().starts(with: "市") {
                city = city.replacingOccurrences(of: "市", with: "")
            }
            prefix = "\(city)"
            
            if city == "佛山" && district == "顺德区" {
                prefix = "顺德"
            }
        }
        if place != "" {
            if place.starts(with: prefix) {
                return place
            }else {
                return "\(prefix)\(place)"
            }
        }else{
            return ""
        }
    }
}

// MARK: - EXPORT

struct NamingForExporting {
    
    let dateFormatter = DateFormatter()
    
    let sourceFileSystemHandler = ComputerFileManager()
    let targetFileSystemHandler = ComputerFileManager()
    
    init() {
        self.dateFormatter.dateFormat = "MM月dd日HH点mm分ss"
    }
    
    func getOriginalDescription(image photo:Image) -> String{
        return photo.exportedLongDescription ?? ExifTool.helper.getImageDescription(url: URL(fileURLWithPath: photo.path))
    }
    
    func getNewDescription(image photo:Image) -> String{
        return photo.longDescription ?? Naming.Export.getImageBrief(image: photo)
    }
    
    func getImageBrief(image photo:Image) -> String {
        var eventAndPlace = ""
        if photo.shortDescription != nil && photo.shortDescription != "" {
            eventAndPlace = "\(photo.shortDescription!)"
        }
        if photo.event != nil && photo.event != "" {
            if eventAndPlace == "" {
                eventAndPlace = "\(photo.event!)"
            }else{
                eventAndPlace = "\(eventAndPlace) - \(photo.event!)"
            }
        }
        if photo.place != nil && photo.place != "" {
            eventAndPlace = "\(eventAndPlace) 在 \(photo.place!)"
        }
        return eventAndPlace
    }
    
    func buildFilename(photo:Image, toPath path:String, 
                             ignoreDiffPathChecking:Bool = false,
                             forceGenerateMD5:Bool = false) -> (isSamePath: Bool, existAtPath: FileExistState, filename:String, md5:String) {
        
        var filenameComponents:[String] = []
        
        // Date
        var photoDateFormatted = ""
        if photo.photoTakenDate != nil {
            photoDateFormatted = dateFormatter.string(from: photo.photoTakenDate!)
            filenameComponents.append(photoDateFormatted)
        }
        
        // Event & Place
        let eventAndPlace = Naming.Export.getImageBrief(image: photo)
        if eventAndPlace != "" {
            filenameComponents.append(eventAndPlace)
        }
        
        // Image Source
        if (photo.filename.starts(with: "mmexport")) {
            filenameComponents.append(" (来自微信)")
        }
        
        if (photo.filename.starts(with: "QQ空间视频_")) {
            filenameComponents.append(" (来自QQ)")
        }
        
        if (photo.filename.starts(with: "Screenshot_")) {
            filenameComponents.append(" (手机截屏)")
        }
        
        // Combine
        let fileExt:String = (photo.filename.split(separator: Character(".")).last?.lowercased())!
        filenameComponents.append(".")
        filenameComponents.append(fileExt)
        
        // export as this name
        var filename:String = filenameComponents.joined()
        
        // START: check duplicates, adjust filename if duplicates at target path
        
        // export to this path
        var targetPath:String = "\(path)/\(filename)"
        
        var previousTargetPath = "\(photo.exportToPath ?? "")/\(photo.exportAsFilename ?? "")"
        if previousTargetPath == "/" {
            previousTargetPath = ""
        }
        
        let isSamePath:Bool = ignoreDiffPathChecking ? true : ( previousTargetPath == targetPath )
        
        // detect duplicates
        let md5OfSourceFile = forceGenerateMD5 ? self.sourceFileSystemHandler.md5(pathOfFile: photo.path) : ( photo.exportedMD5 ?? self.sourceFileSystemHandler.md5(pathOfFile: photo.path) )
        
        var state = self.targetFileSystemHandler.fileExists(atPath: targetPath, md5: md5OfSourceFile)
        
        if state == .notExistAtPath {
            return (isSamePath: isSamePath, existAtPath: .notExistAtPath, filename: filename, md5: md5OfSourceFile)
        }
        
        if state == .existAtPathWithSameMD5 {
            return (isSamePath: isSamePath, existAtPath: .existAtPathWithSameMD5, filename: filename, md5: md5OfSourceFile)
        }
        
        // if another photo occupied the filename at targetPath, with different md5, change filename
        if state == .existAtPathWithDifferentMD5 {
            
            // add camera model to suffix
            //            filenameComponents.removeLast()
            //            filenameComponents.removeLast()
            //            if photo.cameraMaker != nil && photo.cameraMaker != "" {
            //                filenameComponents.append(" (\(photo.cameraMaker!)")
            //
            //                if photo.cameraModel != nil && photo.cameraModel != "" {
            //                    filenameComponents.append(" \(photo.cameraModel!)")
            //                }
            //                filenameComponents.append(")")
            //            }
            //            filenameComponents.append(".")
            //            filenameComponents.append(fileExt)
            //            filename = filenameComponents.joined()
            //            targetPath = "\(path)/\(filename)"
            
            // add number to suffix
            for i in 1...9999 {
                let suffix = i < 10 ? "0\(i)" : "\(i)"
                
                state = self.targetFileSystemHandler.fileExists(atPath: targetPath, md5: md5OfSourceFile)
                if state == .existAtPathWithDifferentMD5 {
                    filenameComponents.removeLast() // fileExt
                    filenameComponents.removeLast() // .
                    if i > 1 {
                        filenameComponents.removeLast() // suffix
                    }
                    filenameComponents.append(" \(suffix)")
                    filenameComponents.append(".")
                    filenameComponents.append(fileExt)
                    filename = filenameComponents.joined()
                    targetPath = "\(path)/\(filename)"
                }else{
                    print("break for-loop")
                    break
                }
            } // state will become .notExistAtPath or .existAtPathWithSameMD5
        }
        // only returns: .notExistAtPath or .existAtPathWithSameMD5
        return (isSamePath: isSamePath, existAtPath: state, filename: filename, md5:md5OfSourceFile)
    }
    
    
    
    func buildFolder(photo:Image) -> String{
        var pathComponents:[String] = []
        pathComponents.append(PreferencesController.exportDirectory())
        pathComponents.append("\(photo.photoTakenYear ?? 0)年")
        //let year:String = "\(photo.photoTakenYear)"
        let month:String = photo.photoTakenMonth! < 10 ? "0\(photo.photoTakenMonth ?? 0)" : "\(photo.photoTakenMonth ?? 0)"
        //let day:String = photo.photoTakenDay < 10 ? "0\(photo.photoTakenDay)" : "\(photo.photoTakenDay)"
        let event:String = photo.event == nil || photo.event == "" ? "" : " \(photo.event ?? "")"
        pathComponents.append("\(month)月\(event)")
        let path:String = pathComponents.joined(separator: "/")
        
        if self.targetFileSystemHandler.createDirectory(atPath: path) {
            return path
        }else{
            return ""
        }
    }
    
}
